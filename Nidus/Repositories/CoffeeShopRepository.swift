import Foundation
import UIKit

protocol CoffeeShopRepositoryProtocol {
    // MARK: - Користувацький інтерфейс
    func getAllCoffeeShops() async throws -> [CoffeeShop]
    func getCoffeeShopById(id: String) async throws -> CoffeeShop
    func getCoffeeShopMenu(id: String) async throws -> [MenuGroup]
    func searchCoffeeShops(address: String) async throws -> [CoffeeShop]
}

class CoffeeShopRepository: CoffeeShopRepositoryProtocol {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService.shared) {
        self.networkService = networkService
    }
    
    // MARK: - Користувацький інтерфейс
    
    func getAllCoffeeShops() async throws -> [CoffeeShop] {
        return try await networkService.fetch(endpoint: "/coffee-shops/find-all")
    }
    
    func getCoffeeShopById(id: String) async throws -> CoffeeShop {
        return try await networkService.fetch(endpoint: "/coffee-shops/\(id)")
    }
    
    func getCoffeeShopMenu(id: String) async throws -> [MenuGroup] {
        return try await networkService.fetch(endpoint: "/coffee-shops/\(id)/menu")
    }
    
    func searchCoffeeShops(address: String) async throws -> [CoffeeShop] {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return try await networkService.fetch(endpoint: "/coffee-shops/search?address=\(encodedAddress)")
    }
}

// Розширення WorkingHoursPeriod для конвертації в словник
extension WorkingHoursPeriod {
    func toDictionary() -> [String: Any] {
        return [
            "open": open,
            "close": close,
            "isClosed": isClosed
        ]
    }
}
