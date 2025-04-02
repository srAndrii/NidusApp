// MenuGroupRepository.swift
import Foundation

protocol MenuGroupRepositoryProtocol {
    func getMenuGroups(coffeeShopId: String) async throws -> [MenuGroup]
    func getMenuGroupWithItems(coffeeShopId: String, groupId: String) async throws -> MenuGroup
    func createMenuGroup(coffeeShopId: String, name: String, description: String?, displayOrder: Int) async throws -> MenuGroup
    func updateMenuGroup(coffeeShopId: String, groupId: String, name: String?, description: String?, displayOrder: Int?) async throws -> MenuGroup
    func deleteMenuGroup(coffeeShopId: String, groupId: String) async throws
    func updateDisplayOrder(coffeeShopId: String, groupId: String, order: Int) async throws -> MenuGroup
}

class MenuGroupRepository: MenuGroupRepositoryProtocol {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService.shared) {
        self.networkService = networkService
    }
    
    func getMenuGroups(coffeeShopId: String) async throws -> [MenuGroup] {
        return try await networkService.fetch(endpoint: "/coffee-shops/\(coffeeShopId)/menu-groups")
    }
    
    func getMenuGroupWithItems(coffeeShopId: String, groupId: String) async throws -> MenuGroup {
        return try await networkService.fetch(endpoint: "/coffee-shops/\(coffeeShopId)/menu-groups/\(groupId)")
    }
    
    struct CreateMenuGroupRequest: Codable {
            let name: String
            let description: String?
            let displayOrder: Int
            let coffeeShopId: String
        }
        
        func createMenuGroup(coffeeShopId: String, name: String, description: String?, displayOrder: Int) async throws -> MenuGroup {
            let createRequest = CreateMenuGroupRequest(
                name: name,
                description: description,
                displayOrder: displayOrder,
                coffeeShopId: coffeeShopId
            )
            
            // Створюємо групу через API
            let menuGroup: MenuGroup = try await networkService.post(endpoint: "/coffee-shops/\(coffeeShopId)/menu-groups", body: createRequest)
            
            // Якщо coffeeShopId відсутній у відповіді, додаємо його вручну
            var updatedMenuGroup = menuGroup
            if updatedMenuGroup.coffeeShopId == nil {
                updatedMenuGroup.coffeeShopId = coffeeShopId
            }
            
            return updatedMenuGroup
        }
    
    struct UpdateMenuGroupRequest: Codable {
        let name: String?
        let description: String?
        let displayOrder: Int?
    }
    
    func updateMenuGroup(coffeeShopId: String, groupId: String, name: String?, description: String?, displayOrder: Int?) async throws -> MenuGroup {
        let updateRequest = UpdateMenuGroupRequest(
            name: name,
            description: description,
            displayOrder: displayOrder
        )
        
        return try await networkService.patch(endpoint: "/coffee-shops/\(coffeeShopId)/menu-groups/\(groupId)", body: updateRequest)
    }
    
    func deleteMenuGroup(coffeeShopId: String, groupId: String) async throws {
        try await networkService.deleteWithoutResponse(endpoint: "/coffee-shops/\(coffeeShopId)/menu-groups/\(groupId)")
    }
    
    func updateDisplayOrder(coffeeShopId: String, groupId: String, order: Int) async throws -> MenuGroup {
        return try await networkService.put(
            endpoint: "/coffee-shops/\(coffeeShopId)/menu-groups/\(groupId)/display-order?order=\(order)",
            body: EmptyBody()
        )
    }
    
    struct EmptyBody: Codable {}
}
