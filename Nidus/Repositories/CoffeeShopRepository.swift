// CoffeeShopRepository.swift
import Foundation

protocol CoffeeShopRepositoryProtocol {
    func getAllCoffeeShops() async throws -> [CoffeeShop]
    func getCoffeeShopById(id: String) async throws -> CoffeeShop
    func getMyCoffeeShops() async throws -> [CoffeeShop]
    func getCoffeeShopMenu(id: String) async throws -> [MenuGroup]
    func createCoffeeShop(name: String, address: String?) async throws -> CoffeeShop
    func updateCoffeeShop(id: String, params: [String: Any]) async throws -> CoffeeShop
    func searchCoffeeShops(address: String) async throws -> [CoffeeShop]
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
        guard let url = URL(string: networkService.baseURL + endpoint) else {
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
}
