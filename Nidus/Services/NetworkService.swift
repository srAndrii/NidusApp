// NetworkService.swift
import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
    case unauthorized
    case serverError(statusCode: Int, message: String?)
    
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
        case .serverError(let statusCode, let message):
            return "Помилка сервера (\(statusCode)): \(message ?? "Невідома помилка")"
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
    
    private let baseURL = "https://nidus-845c224671ea.herokuapp.com/api"
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
        var urlRequest = try createRequest(for: endpoint, method: "GET", requiresAuth: requiresAuth)
        return try await performRequest(urlRequest)
    }
    
    func post<T: Encodable, U: Decodable>(endpoint: String, body: T, requiresAuth: Bool = true) async throws -> U {
        var urlRequest = try createRequest(for: endpoint, method: "POST", requiresAuth: requiresAuth)
        return try await performRequestWithBody(urlRequest, body: body)
    }
    
    func patch<T: Encodable, U: Decodable>(endpoint: String, body: T, requiresAuth: Bool = true) async throws -> U {
        var urlRequest = try createRequest(for: endpoint, method: "PATCH", requiresAuth: requiresAuth)
        return try await performRequestWithBody(urlRequest, body: body)
    }
    
    func put<T: Encodable, U: Decodable>(endpoint: String, body: T, requiresAuth: Bool = true) async throws -> U {
        var urlRequest = try createRequest(for: endpoint, method: "PUT", requiresAuth: requiresAuth)
        return try await performRequestWithBody(urlRequest, body: body)
    }
    
    func delete<U: Decodable>(endpoint: String, requiresAuth: Bool = true) async throws -> U {
        var urlRequest = try createRequest(for: endpoint, method: "DELETE", requiresAuth: requiresAuth)
        return try await performRequest(urlRequest)
    }
    
    func deleteWithoutResponse(endpoint: String, requiresAuth: Bool = true) async throws {
        var urlRequest = try createRequest(for: endpoint, method: "DELETE", requiresAuth: requiresAuth)
        _ = try await performRequestWithoutResponse(urlRequest)
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
    
    private func performRequestWithoutResponse(_ request: URLRequest) async throws {
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        default:
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: nil)
        }
    }
    
    
    
    // Додайте цей код до вашого NetworkService.swift
    // Змініть метод для обробки відповіді

    private func handleResponse<T: Decodable>(data: Data, response: URLResponse) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                // Для відладки: виведемо текст JSON-відповіді
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("JSON відповідь: \(jsonString)")
                }
                
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
                    
                    // Спробуємо кілька форматів дати
                    let formatters = [
                        "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                        "yyyy-MM-dd'T'HH:mm:ssZ",
                        "yyyy-MM-dd'T'HH:mm:ss"
                    ].map { format -> DateFormatter in
                        let formatter = DateFormatter()
                        formatter.dateFormat = format
                        formatter.locale = Locale(identifier: "en_US_POSIX")
                        return formatter
                    }
                    
                    for formatter in formatters {
                        if let date = formatter.date(from: dateStr) {
                            return date
                        }
                    }
                    
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Не вдається розпізнати дату: \(dateStr)"
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
                print("Error parsing JSON: \(error)")
                
                // Запасний варіант - використовуємо JSONSerialization
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let messageArray = json["message"] as? [String], !messageArray.isEmpty {
                        let message = messageArray.joined(separator: ", ")
                        throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
                    } else if let message = json["message"] as? String {
                        throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
                    }
                }
                
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: "Помилка обробки відповіді")
            }
        }
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
