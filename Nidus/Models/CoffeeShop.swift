// CoffeeShopRepository.swift
import Foundation
import UIKit

protocol CoffeeShopRepositoryProtocol {
    func getAllCoffeeShops() async throws -> [CoffeeShop]
    func getCoffeeShopById(id: String) async throws -> CoffeeShop
    func getMyCoffeeShops() async throws -> [CoffeeShop]
    func getCoffeeShopMenu(id: String) async throws -> [MenuGroup]
    func createCoffeeShop(name: String, address: String?) async throws -> CoffeeShop
    func updateCoffeeShop(id: String, params: [String: Any]) async throws -> CoffeeShop
    func searchCoffeeShops(address: String) async throws -> [CoffeeShop]
    func deleteCoffeeShop(id: String) async throws
    func assignOwner(coffeeShopId: String, userId: String) async throws -> CoffeeShop
    // Новий метод для завантаження логотипу
    func uploadLogo(coffeeShopId: String, imageData: Data) async throws -> String
    // Новий метод для видалення логотипу
    func resetLogo(coffeeShopId: String) async throws -> String
}

class CoffeeShopRepository: CoffeeShopRepositoryProtocol {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService.shared) {
        self.networkService = networkService
    }
    
    func getAllCoffeeShops() async throws -> [CoffeeShop] {
        return try await networkService.fetch(endpoint: "/coffee-shops/find-all")
    }
    
    func getCoffeeShopById(id: String) async throws -> CoffeeShop {
        return try await networkService.fetch(endpoint: "/coffee-shops/\(id)")
    }
    
    func getMyCoffeeShops() async throws -> [CoffeeShop] {
        return try await networkService.fetch(endpoint: "/coffee-shops/my-shops")
    }
    
    func getCoffeeShopMenu(id: String) async throws -> [MenuGroup] {
        return try await networkService.fetch(endpoint: "/coffee-shops/\(id)/menu")
    }
    
    struct CreateCoffeeShopRequest: Codable {
        let name: String
        let address: String?
    }
    
    func createCoffeeShop(name: String, address: String?) async throws -> CoffeeShop {
        let createRequest = CreateCoffeeShopRequest(name: name, address: address)
        return try await networkService.post(endpoint: "/coffee-shops/create", body: createRequest)
    }
    
    // Використовуємо Dictionary для гнучкого оновлення полів
    func updateCoffeeShop(id: String, params: [String: Any]) async throws -> CoffeeShop {
        // Перетворення Dictionary на JSON data
        let jsonData = try JSONSerialization.data(withJSONObject: params)
        
        // Використовуємо raw Data для уникнення проблем з типами
        struct UpdateResponse: Decodable {
            let coffeeShop: CoffeeShop
        }
        
        // Створюємо запит напряму
        var urlRequest = try createRequest(for: "/coffee-shops/\(id)", method: "PATCH")
        urlRequest.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(CoffeeShop.self, from: data)
    }
    
    private func createRequest(for endpoint: String, method: String) throws -> URLRequest {
        let baseURL = networkService.getBaseURL()
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let token = UserDefaults.standard.string(forKey: "accessToken") else {
            throw APIError.unauthorized
        }
        
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    func searchCoffeeShops(address: String) async throws -> [CoffeeShop] {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return try await networkService.fetch(endpoint: "/coffee-shops/search?address=\(encodedAddress)")
    }
    
    func deleteCoffeeShop(id: String) async throws {
        try await networkService.deleteWithoutResponse(endpoint: "/coffee-shops/\(id)")
    }
    
    func assignOwner(coffeeShopId: String, userId: String) async throws -> CoffeeShop {
        return try await networkService.patch(endpoint: "/coffee-shops/\(coffeeShopId)/assign-owner/\(userId)", body: EmptyBody())
    }
    
    // MARK: - Завантаження файлів
    
    // Метод для завантаження логотипу кав'ярні
    func uploadLogo(coffeeShopId: String, imageData: Data) async throws -> String {
        // Використовуємо multipart/form-data для завантаження файлу
        let endpoint = "/upload/coffee-shop/\(coffeeShopId)/logo"
        
        struct UploadResponse: Decodable {
            let success: Bool
            let url: String
        }
        
        // Створюємо multipart запит
        let boundary = UUID().uuidString
        let baseURL = networkService.getBaseURL()
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        guard let token = UserDefaults.standard.string(forKey: "accessToken") else {
            throw APIError.unauthorized
        }
        
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Будуємо multipart/form-data тіло запиту
        var body = Data()
        
        // Додаємо заголовок для файлу
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"logo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        
        // Додаємо дані зображення
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Додаємо закриваючу частину
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Встановлюємо тіло запиту
        request.httpBody = body
        
        // Виконуємо запит
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            // Спробуємо отримати повідомлення про помилку
            if let errorMessage = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 500,
                                           message: errorMessage.message)
            }
            throw APIError.invalidResponse
        }
        
        let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
        
        if uploadResponse.success {
            return uploadResponse.url
        } else {
            throw APIError.serverError(statusCode: 500, message: "Не вдалося завантажити логотип")
        }
    }
    
    // Метод для скидання логотипу до дефолтного
    func resetLogo(coffeeShopId: String) async throws -> String {
        struct ResetLogoResponse: Decodable {
            let success: Bool
            let url: String
        }
        
        let response: ResetLogoResponse = try await networkService.delete(endpoint: "/upload/coffee-shop/\(coffeeShopId)/logo")
        
        if response.success {
            return response.url
        } else {
            throw APIError.serverError(statusCode: 500, message: "Не вдалося скинути логотип")
        }
    }
    
    struct EmptyBody: Codable {}
    
    struct ErrorResponse: Decodable {
        let message: String
        let error: String?
        let statusCode: Int?
    }
}
