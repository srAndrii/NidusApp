// MenuGroupRepository.swift
import Foundation

// MARK: - Протокол репозиторію
protocol MenuGroupRepositoryProtocol {
    // MARK: - Методи користувацького інтерфейсу
    /// Отримання груп меню для певної кав'ярні (для відображення в UI користувача)
    func getMenuGroups(coffeeShopId: String) async throws -> [MenuGroup]
    
    /// Отримання групи меню з її пунктами (для відображення деталей групи в UI користувача)
    func getMenuGroupWithItems(coffeeShopId: String, groupId: String) async throws -> MenuGroup
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
        return try await networkService.fetch(endpoint: "/coffee-shops/\(coffeeShopId)/menu-groups", requiresAuth: false)
    }
    
    /// Отримання групи меню з її пунктами
    func getMenuGroupWithItems(coffeeShopId: String, groupId: String) async throws -> MenuGroup {
        return try await networkService.fetch(endpoint: "/coffee-shops/\(coffeeShopId)/menu-groups/\(groupId)", requiresAuth: false)
    }
}
