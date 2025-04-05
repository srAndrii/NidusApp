// MenuGroupRepository.swift
import Foundation

// MARK: - Протокол репозиторію
protocol MenuGroupRepositoryProtocol {
    // MARK: - Методи користувацького інтерфейсу
    /// Отримання груп меню для певної кав'ярні (для відображення в UI користувача)
    func getMenuGroups(coffeeShopId: String) async throws -> [MenuGroup]
    
    /// Отримання групи меню з її пунктами (для відображення деталей групи в UI користувача)
    func getMenuGroupWithItems(coffeeShopId: String, groupId: String) async throws -> MenuGroup
    
    // MARK: - Методи адміністративного інтерфейсу
    /// Створення нової групи меню (тільки для адміністративного інтерфейсу)
    func createMenuGroup(coffeeShopId: String, name: String, description: String?, displayOrder: Int) async throws -> MenuGroup
    
    /// Оновлення існуючої групи меню (тільки для адміністративного інтерфейсу)
    func updateMenuGroup(coffeeShopId: String, groupId: String, name: String?, description: String?, displayOrder: Int?) async throws -> MenuGroup
    
    /// Видалення групи меню (тільки для адміністративного інтерфейсу)
    func deleteMenuGroup(coffeeShopId: String, groupId: String) async throws
    
    /// Оновлення порядку відображення групи меню (тільки для адміністративного інтерфейсу)
    func updateDisplayOrder(coffeeShopId: String, groupId: String, order: Int) async throws -> MenuGroup
}

// MARK: - Імплементація репозиторію
class MenuGroupRepository: MenuGroupRepositoryProtocol {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService.shared) {
        self.networkService = networkService
    }
    
    // MARK: - Імплементація методів користувацького інтерфейсу
    
    /// Отримання груп меню для певної кав'ярні
    func getMenuGroups(coffeeShopId: String) async throws -> [MenuGroup] {
        return try await networkService.fetch(endpoint: "/coffee-shops/\(coffeeShopId)/menu-groups")
    }
    
    /// Отримання групи меню з її пунктами
    func getMenuGroupWithItems(coffeeShopId: String, groupId: String) async throws -> MenuGroup {
        return try await networkService.fetch(endpoint: "/coffee-shops/\(coffeeShopId)/menu-groups/\(groupId)")
    }
    
    // MARK: - Імплементація методів адміністративного інтерфейсу
    
    /// Структура для створення групи меню
    struct CreateMenuGroupRequest: Codable {
        let name: String
        let description: String?
        let displayOrder: Int
        let coffeeShopId: String
    }
    
    /// Створення нової групи меню
    func createMenuGroup(coffeeShopId: String, name: String, description: String?, displayOrder: Int) async throws -> MenuGroup {
        let createRequest = CreateMenuGroupRequest(
            name: name,
            description: description,
            displayOrder: displayOrder,
            coffeeShopId: coffeeShopId
        )
        
        // Створюємо групу через API
        let menuGroup: MenuGroup = try await networkService.post(
            endpoint: "/coffee-shops/\(coffeeShopId)/menu-groups",
            body: createRequest
        )
        
        // Якщо coffeeShopId відсутній у відповіді, додаємо його вручну
        var updatedMenuGroup = menuGroup
        if updatedMenuGroup.coffeeShopId == nil {
            updatedMenuGroup.coffeeShopId = coffeeShopId
        }
        
        return updatedMenuGroup
    }
    
    /// Структура для оновлення групи меню
    struct UpdateMenuGroupRequest: Codable {
        let name: String?
        let description: String?
        let displayOrder: Int?
    }
    
    /// Оновлення існуючої групи меню
    func updateMenuGroup(coffeeShopId: String, groupId: String, name: String?, description: String?, displayOrder: Int?) async throws -> MenuGroup {
        let updateRequest = UpdateMenuGroupRequest(
            name: name,
            description: description,
            displayOrder: displayOrder
        )
        
        return try await networkService.patch(
            endpoint: "/coffee-shops/\(coffeeShopId)/menu-groups/\(groupId)",
            body: updateRequest
        )
    }
    
    /// Видалення групи меню
    func deleteMenuGroup(coffeeShopId: String, groupId: String) async throws {
        try await networkService.deleteWithoutResponse(
            endpoint: "/coffee-shops/\(coffeeShopId)/menu-groups/\(groupId)"
        )
    }
    
    /// Оновлення порядку відображення групи меню
    func updateDisplayOrder(coffeeShopId: String, groupId: String, order: Int) async throws -> MenuGroup {
        return try await networkService.put(
            endpoint: "/coffee-shops/\(coffeeShopId)/menu-groups/\(groupId)/display-order?order=\(order)",
            body: EmptyBody()
        )
    }
    
    // MARK: - Допоміжні структури
    
    /// Порожнє тіло для запитів без параметрів
    struct EmptyBody: Codable {}
}
