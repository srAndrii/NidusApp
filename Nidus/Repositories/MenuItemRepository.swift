// MenuItemRepository.swift
import Foundation

protocol MenuItemRepositoryProtocol {
    // MARK: - Користувацький інтерфейс
    /// Отримання всіх пунктів меню для групи
    func getMenuItems(groupId: String) async throws -> [MenuItem]
    
    /// Отримання деталей пункту меню
    func getMenuItem(groupId: String, itemId: String) async throws -> MenuItem
    
    /// Отримання відфільтрованих пунктів меню (за ціною)
    func getFilteredMenuItems(groupId: String, minPrice: Double?, maxPrice: Double?) async throws -> [MenuItem]
    
    // MARK: - Адміністративний інтерфейс
    /// Створення нового пункту меню
    func createMenuItem(groupId: String, item: CreateMenuItemRequest) async throws -> MenuItem
    
    /// Оновлення існуючого пункту меню
    func updateMenuItem(groupId: String, itemId: String, updates: [String: Any]) async throws -> MenuItem
    
    /// Видалення пункту меню
    func deleteMenuItem(groupId: String, itemId: String) async throws
    
    /// Оновлення доступності пункту меню
    func updateAvailability(groupId: String, itemId: String, available: Bool) async throws -> MenuItem
}

struct CreateMenuItemRequest: Codable {
    let name: String
    let price: Decimal
    let description: String?
    let isAvailable: Bool
    let ingredients: [Ingredient]?
    let customizationOptions: [String: [String]]?
    var menuGroupId: String
    
    // Додаємо кастомний кодер для уникнення проблем з форматом price
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        
        // Відправляємо price як число, не як рядок
        try container.encode(NSDecimalNumber(decimal: price).doubleValue, forKey: .price)
        
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(isAvailable, forKey: .isAvailable)
        try container.encodeIfPresent(ingredients, forKey: .ingredients)
        try container.encodeIfPresent(customizationOptions, forKey: .customizationOptions)
        try container.encode(menuGroupId, forKey: .menuGroupId)
    }
    
    enum CodingKeys: String, CodingKey {
        case name, price, description, isAvailable, ingredients, customizationOptions, menuGroupId
    }
}

class MenuItemRepository: MenuItemRepositoryProtocol {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService.shared) {
        self.networkService = networkService
    }
    
    // MARK: - Користувацький інтерфейс
    
    func getMenuItems(groupId: String) async throws -> [MenuItem] {
        return try await networkService.fetch(endpoint: "/menu-groups/\(groupId)/items")
    }
    
    func getMenuItem(groupId: String, itemId: String) async throws -> MenuItem {
        return try await networkService.fetch(endpoint: "/menu-groups/\(groupId)/items/\(itemId)")
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
    
    // MARK: - Адміністративний інтерфейс
    
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
        
        print("JSON для оновлення: \(String(data: jsonData, encoding: .utf8) ?? "невідомо")")
        
        // Створюємо запит напряму
        var urlRequest = try createRequest(for: "/menu-groups/\(groupId)/items/\(itemId)", method: "PATCH")
        urlRequest.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        // Виводимо відповідь для діагностики
        if let responseString = String(data: data, encoding: .utf8) {
            print("Відповідь сервера: \(responseString)")
        }
        
        // Використовуємо спеціальний декодер з надійною обробкою дат
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            // Спробуємо різні формати дат
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
            
            // Якщо не вдалося розпарсити, просто повертаємо поточну дату замість помилки
            print("❌ Не вдалося розпарсити дату: \(dateStr)")
            return Date()
        }
        
        do {
            return try decoder.decode(MenuItem.self, from: data)
        } catch {
            print("❌ Помилка декодування: \(error)")
            
            // Якщо декодування не вдалося, завантажуємо пункт меню окремим запитом
            return try await getMenuItem(groupId: groupId, itemId: itemId)
        }
    }
    
    func deleteMenuItem(groupId: String, itemId: String) async throws {
        try await networkService.deleteWithoutResponse(endpoint: "/menu-groups/\(groupId)/items/\(itemId)")
    }
    
    func updateAvailability(groupId: String, itemId: String, available: Bool) async throws -> MenuItem {
        // Правильний ендпоінт з query-параметром
        let endpoint = "/menu-groups/\(groupId)/items/\(itemId)/availability?available=\(available)"
        
        // Виконуємо запит без декодування відповіді
        let (_, response) = try await networkService.createPatchRequest(endpoint: endpoint, body: EmptyBody())
        
        // Перевіряємо статус-код
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        // Завантажуємо оновлений пункт меню
        return try await getMenuItem(groupId: groupId, itemId: itemId)
    }
    
    // MARK: - Допоміжні методи
    
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
    
    struct EmptyBody: Codable {}
}
