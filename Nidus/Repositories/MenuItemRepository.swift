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
}

class MenuItemRepository: MenuItemRepositoryProtocol {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService.shared) {
        self.networkService = networkService
    }
    
    // MARK: - Користувацький інтерфейс
    
    func getMenuItems(groupId: String) async throws -> [MenuItem] {
        return try await networkService.fetch(endpoint: "/menu-groups/\(groupId)/items", requiresAuth: false)
    }
    
    func getMenuItem(groupId: String, itemId: String) async throws -> MenuItem {
        return try await networkService.fetch(endpoint: "/menu-groups/\(groupId)/items/\(itemId)", requiresAuth: false)
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
        
        return try await networkService.fetch(endpoint: endpoint, requiresAuth: false)
    }
}
