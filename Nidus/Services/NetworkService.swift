import UIKit
import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
    case unauthorized
    case serverError(statusCode: Int, message: String?)
    case simpleServerError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Недійсна URL-адреса"
        case .requestFailed(let error):
            return "Запит не вдалося виконати: \(error.localizedDescription)"
        case .invalidResponse:
            return "Отримана недійсна відповідь від сервера"
        case .decodingFailed(let error):
            return "Не вдалося декодувати відповідь: \(error.localizedDescription)"
        case .unauthorized:
            return "Необхідна авторизація для доступу до цього ресурсу"
        case .serverError(statusCode: let statusCode, message: let message):
            return "Помилка сервера (\(statusCode)): \(message ?? "Невідома помилка")"
        case .simpleServerError(message: let message):
            return "Помилка сервера: \(message)"
        }
    }
}

struct ErrorResponse: Decodable {
    let message: String
    let error: String
    let statusCode: Int
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        error = try container.decode(String.self, forKey: .error)
        statusCode = try container.decode(Int.self, forKey: .statusCode)
        
        // Декодуємо "message" залежно від типу даних
        if let messageArray = try? container.decode([String].self, forKey: .message) {
            // Якщо це масив, об'єднуємо елементи в один рядок
            message = messageArray.joined(separator: ", ")
        } else if let messageString = try? container.decode(String.self, forKey: .message) {
            // Якщо це рядок, використовуємо його
            message = messageString
        } else {
            // Якщо поле відсутнє або має невідомий формат
            message = "Невідома помилка"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case message, error, statusCode
    }
}

class NetworkService {
    static let shared = NetworkService()
    
    private let baseURL = "https://nidus-production.up.railway.app/api"
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Auth Token Management
    
    private var accessToken: String? {
        get {
            return userDefaults.string(forKey: "accessToken")
        }
        set {
            if let newValue = newValue {
                userDefaults.set(newValue, forKey: "accessToken")
            } else {
                userDefaults.removeObject(forKey: "accessToken")
            }
        }
    }
    
    private var refreshToken: String? {
        get {
            return userDefaults.string(forKey: "refreshToken")
        }
        set {
            if let newValue = newValue {
                userDefaults.set(newValue, forKey: "refreshToken")
            } else {
                userDefaults.removeObject(forKey: "refreshToken")
            }
        }
    }
    
    func saveTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
    
    func clearTokens() {
        accessToken = nil
        refreshToken = nil
    }
    
    // MARK: - API Methods
    
    func getBaseURL() -> String {
        return baseURL
    }
    
    func fetch<T: Decodable>(endpoint: String, requiresAuth: Bool = true) async throws -> T {
        print("🌐 [NetworkService] Starting fetch request")
        print("📍 [NetworkService] Endpoint: \(endpoint)")
        print("🔑 [NetworkService] Requires auth: \(requiresAuth)")
        print("🌍 [NetworkService] Full URL: \(baseURL)\(endpoint)")
        
        var urlRequest = try createRequest(for: endpoint, method: "GET", requiresAuth: requiresAuth)
        
        print("📡 [NetworkService] Request headers: \(urlRequest.allHTTPHeaderFields ?? [:])")
        
        let result: T = try await performRequest(urlRequest)
        print("✅ [NetworkService] Successfully fetched data for endpoint: \(endpoint)")
        return result
    }
    
    func post<T: Encodable, U: Decodable>(endpoint: String, body: T, requiresAuth: Bool = true) async throws -> U {
        var urlRequest = try createRequest(for: endpoint, method: "POST", requiresAuth: requiresAuth)
        return try await performRequestWithBody(urlRequest, body: body)
    }
    
    // Залишаємо метод patch для клієнтських запитів (оновлення профілю, скасування замовлення)
    func patch<T: Encodable, U: Decodable>(endpoint: String, body: T, requiresAuth: Bool = true) async throws -> U {
        var urlRequest = try createRequest(for: endpoint, method: "PATCH", requiresAuth: requiresAuth)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let requestData = try encoder.encode(body)
            urlRequest.httpBody = requestData
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Перевіряємо код відповіді
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .custom { decoder in
                        let container = try decoder.singleValueContainer()
                        let dateStr = try container.decode(String.self)
                        
                        print("🕐 [PATCH] Намагаємося декодувати дату: '\(dateStr)'")
                        
                        // Спочатку пробуємо ISO8601DateFormatter з підтримкою мілісекунд
                        let iso8601Formatter = ISO8601DateFormatter()
                        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        
                        if let date = iso8601Formatter.date(from: dateStr) {
                            print("✅ [PATCH] Успішно декодовано з ISO8601 (з мілісекундами): \(date)")
                            return date
                        }
                        
                        // Якщо не спрацювало, пробуємо без мілісекунд
                        iso8601Formatter.formatOptions = [.withInternetDateTime]
                        
                        if let date = iso8601Formatter.date(from: dateStr) {
                            print("✅ [PATCH] Успішно декодовано з ISO8601 (без мілісекунд): \(date)")
                            return date
                        }
                        
                        // Спробуємо кілька форматів дати вручну
                        let formatters = [
                            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                            "yyyy-MM-dd'T'HH:mm:ss'Z'",
                            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                            "yyyy-MM-dd'T'HH:mm:ssZ",
                            "yyyy-MM-dd'T'HH:mm:ss"
                        ].map { format -> DateFormatter in
                            let formatter = DateFormatter()
                            formatter.dateFormat = format
                            formatter.locale = Locale(identifier: "en_US_POSIX")
                            formatter.timeZone = TimeZone(secondsFromGMT: 0)
                            return formatter
                        }
                        
                        for formatter in formatters {
                            if let date = formatter.date(from: dateStr) {
                                return date
                            }
                        }
                        throw DecodingError.dataCorruptedError(
                            in: container,
                            debugDescription: "Expected date string to be ISO8601-formatted."
                        )
                    }
                    
                    return try decoder.decode(U.self, from: data)
                } catch {
                    throw APIError.decodingFailed(error)
                }
            } else {
                // Спробуємо декодувати помилку
                do {
                    let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                    throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorResponse.message)
                } catch {
                    throw APIError.serverError(statusCode: httpResponse.statusCode, message: "Помилка оновлення профілю")
                }
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.requestFailed(error)
        }
    }
    
    // DELETE method for deleting resources
    func delete<T: Decodable>(endpoint: String, requiresAuth: Bool = true) async throws -> T {
        var urlRequest = try createRequest(for: endpoint, method: "DELETE", requiresAuth: requiresAuth)
        return try await performRequest(urlRequest)
    }
    
    // MARK: - Helper Methods
    
    private func createRequest(for endpoint: String, method: String, requiresAuth: Bool) throws -> URLRequest {
        // Make sure URL starts with "/" if not provided
        let formattedEndpoint = endpoint.hasPrefix("/") ? endpoint : "/\(endpoint)"
        
        guard let url = URL(string: baseURL + formattedEndpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if requiresAuth {
            guard let token = accessToken else {
                throw APIError.unauthorized
            }
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            return try handleResponse(data: data, response: response)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.requestFailed(error)
        }
    }
    
    private func performRequestWithBody<T: Encodable, U: Decodable>(_ request: URLRequest, body: T) async throws -> U {
        var request = request
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            request.httpBody = try encoder.encode(body)
            let (data, response) = try await URLSession.shared.data(for: request)
            return try handleResponse(data: data, response: response)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.requestFailed(error)
        }
    }
    
    private func handleResponse<T: Decodable>(data: Data, response: URLResponse) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                // JSON логування видалено для production
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                decoder.keyDecodingStrategy = .useDefaultKeys
                
                // Додамо обробку дат у різних форматах
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateStr = try container.decode(String.self)
                    
                    print("🕐 Намагаємося декодувати дату: '\(dateStr)'")
                    
                    // Спочатку пробуємо ISO8601DateFormatter з підтримкою мілісекунд
                    let iso8601Formatter = ISO8601DateFormatter()
                    iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    
                    if let date = iso8601Formatter.date(from: dateStr) {
                        print("✅ Успішно декодовано з ISO8601 (з мілісекундами): \(date)")
                        return date
                    }
                    
                    // Якщо не спрацювало, пробуємо без мілісекунд
                    iso8601Formatter.formatOptions = [.withInternetDateTime]
                    
                    if let date = iso8601Formatter.date(from: dateStr) {
                        print("✅ Успішно декодовано з ISO8601 (без мілісекунд): \(date)")
                        return date
                    }
                    
                    // Спробуємо кілька форматів дати вручну
                    let formatters = [
                        "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                        "yyyy-MM-dd'T'HH:mm:ss'Z'",
                        "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                        "yyyy-MM-dd'T'HH:mm:ssZ",
                        "yyyy-MM-dd'T'HH:mm:ss"
                    ].map { format -> DateFormatter in
                        let formatter = DateFormatter()
                        formatter.dateFormat = format
                        formatter.locale = Locale(identifier: "en_US_POSIX")
                        formatter.timeZone = TimeZone(secondsFromGMT: 0)
                        return formatter
                    }
                    
                    for (index, formatter) in formatters.enumerated() {
                        if let date = formatter.date(from: dateStr) {
                            print("✅ Успішно декодовано з формату #\(index): \(date)")
                            return date
                        }
                    }
                    
                    print("❌ Не вдалося декодувати дату: '\(dateStr)'")
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Expected date string to be ISO8601-formatted."
                    )
                }
                
                return try decoder.decode(T.self, from: data)
            } catch {
                // Більш детальна інформація про помилку декодування
                print("Помилка декодування: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("Ключ не знайдено: \(key), шлях: \(context.codingPath), \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("Значення не знайдено: \(type), шлях: \(context.codingPath), \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("Невідповідність типу: \(type), шлях: \(context.codingPath), \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("Дані пошкоджені: \(context.debugDescription), шлях: \(context.codingPath)")
                    @unknown default:
                        print("Невідома помилка декодування")
                    }
                }
                throw APIError.decodingFailed(error)
            }
        case 401:
            throw APIError.unauthorized
        default:
            // Виводимо JSON для діагностики
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Error JSON response: \(jsonString)")
            }
            
            do {
                let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                print("Parsed error message: \(errorResponse.message)")
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorResponse.message)
            } catch let apiError as APIError {
                throw apiError
            } catch {
                print("Error parsing error response: \(error)")
                
                // Безпечна обробка помилок для ErrorResponse
                do {
                    // Спробуємо проаналізувати JSON вручну
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let messageArray = json["message"] as? [String], !messageArray.isEmpty {
                            let message = messageArray.joined(separator: ", ")
                            throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
                        } else if let message = json["message"] as? String {
                            throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
                        } else {
                            throw APIError.serverError(statusCode: httpResponse.statusCode, message: "Невідома помилка сервера")
                        }
                    } else {
                        throw APIError.serverError(statusCode: httpResponse.statusCode, message: "Помилка обробки відповіді")
                    }
                } catch let jsonError as APIError {
                    throw jsonError
                } catch {
                    throw APIError.simpleServerError(message: "Помилка обробки відповіді сервера")
                }
            }
        }
    }
    
    // MARK: - File Upload Helper Methods

    func mimeType(for extension: String) -> String {
        switch `extension`.lowercased() {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "pdf":
            return "application/pdf"
        default:
            return "application/octet-stream"
        }
    }

    /// Конвертує UIImage в Data з визначеним форматом і якістю
    func compressImage(_ image: UIImage, format: ImageFormat = .jpeg, compressionQuality: CGFloat = 0.8) -> Data? {
        switch format {
        case .jpeg:
            return image.jpegData(compressionQuality: compressionQuality)
        case .png:
            return image.pngData()
        }
    }

    enum ImageFormat {
        case jpeg
        case png
    }
    
    // MARK: - Token Refresh
    
    func refreshAuthToken() async throws -> Bool {
        guard let refreshToken = refreshToken else {
            return false
        }
        
        struct RefreshTokenRequest: Codable {
            let refreshToken: String
        }
        
        struct TokenResponse: Codable {
            let access_token: String
            let refresh_token: String
        }
        
        do {
            let request = RefreshTokenRequest(refreshToken: refreshToken)
            let response: TokenResponse = try await post(endpoint: "/auth/refresh", body: request, requiresAuth: false)
            saveTokens(accessToken: response.access_token, refreshToken: response.refresh_token)
            return true
        } catch {
            clearTokens()
            return false
        }
    }
}
