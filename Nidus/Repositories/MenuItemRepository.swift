// MenuItemRepository.swift
import Foundation

protocol MenuItemRepositoryProtocol {
    func getMenuItems(groupId: String) async throws -> [MenuItem]
    func getMenuItem(groupId: String, itemId: String) async throws -> MenuItem
    func createMenuItem(groupId: String, item: CreateMenuItemRequest) async throws -> MenuItem
    func updateMenuItem(groupId: String, itemId: String, updates: [String: Any]) async throws -> MenuItem
    func deleteMenuItem(groupId: String, itemId: String) async throws
    func updateAvailability(groupId: String, itemId: String, available: Bool) async throws -> MenuItem
    func getFilteredMenuItems(groupId: String, minPrice: Double?, maxPrice: Double?) async throws -> [MenuItem]
}

struct CreateMenuItemRequest: Codable {
    let name: String
    let price: Decimal
    let description: String?
    let isAvailable: Bool
    let ingredients: [Ingredient]?
    let customizationOptions: [String: [String]]?
    var menuGroupId: String  
}

class MenuItemRepository: MenuItemRepositoryProtocol {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService.shared) {
        self.networkService = networkService
    }
    
    func getMenuItems(groupId: String) async throws -> [MenuItem] {
        return try await networkService.fetch(endpoint: "/menu-groups/\(groupId)/items")
    }
    
    func getMenuItem(groupId: String, itemId: String) async throws -> MenuItem {
        return try await networkService.fetch(endpoint: "/menu-groups/\(groupId)/items/\(itemId)")
    }
    
    func createMenuItem(groupId: String, item: CreateMenuItemRequest) async throws -> MenuItem {
            // Оновлюємо структуру запиту, щоб мати правильний menuGroupId
            var createRequest = item
            createRequest.menuGroupId = groupId
            
            // Виконуємо запит
            let menuItem: MenuItem = try await networkService.post(endpoint: "/menu-groups/\(groupId)/items", body: createRequest)
            
            // Якщо menuGroupId відсутній у відповіді, додаємо його вручну
            var updatedMenuItem = menuItem
            if updatedMenuItem.menuGroupId == nil {
                updatedMenuItem.menuGroupId = groupId
            }
            
            return updatedMenuItem
        }
    
    // Використовуємо Dictionary для гнучкого оновлення полів
    func updateMenuItem(groupId: String, itemId: String, updates: [String: Any]) async throws -> MenuItem {
        // Перетворення Dictionary на JSON data
        let jsonData = try JSONSerialization.data(withJSONObject: updates)
        
        // Використовуємо raw Data для уникнення проблем з типами
        struct UpdateResponse: Decodable {
            let menuItem: MenuItem
        }
        
        // Створюємо запит напряму
        var urlRequest = try createRequest(for: "/menu-groups/\(groupId)/items/\(itemId)", method: "PATCH")
        urlRequest.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MenuItem.self, from: data)
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
    
    func deleteMenuItem(groupId: String, itemId: String) async throws {
        try await networkService.deleteWithoutResponse(endpoint: "/menu-groups/\(groupId)/items/\(itemId)")
    }
    
    func updateAvailability(groupId: String, itemId: String, available: Bool) async throws -> MenuItem {
        return try await networkService.patch(
            endpoint: "/menu-groups/\(groupId)/items/\(itemId)/availability?available=\(available)",
            body: EmptyBody()
        )
    }
    
    func getFilteredMenuItems(groupId: String, minPrice: Double?, maxPrice: Double?) async throws -> [MenuItem] {
        var endpoint = "/menu-groups/\(groupId)/items/filter?"
        
        if let minPrice = minPrice {
            endpoint += "minPrice=\(minPrice)&"
        }
        
        if let maxPrice = maxPrice {
            endpoint += "maxPrice=\(maxPrice)&"
        }
        
        // Видаляємо останній символ, якщо це '&' або '?'
        if endpoint.last == "&" || endpoint.last == "?" {
            endpoint.removeLast()
        }
        
        return try await networkService.fetch(endpoint: endpoint)
    }
    
    struct EmptyBody: Codable {}
}
