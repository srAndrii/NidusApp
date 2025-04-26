// OrderRepository.swift
import Foundation

protocol OrderRepositoryProtocol {
    // MARK: - Користувацький інтерфейс
    /// Отримання активних замовлень поточного користувача
    func getMyActiveOrders() async throws -> [Order]
    
    /// Отримання історії замовлень поточного користувача
    func getMyOrderHistory() async throws -> [Order]
    
    /// Отримання деталей замовлення за ID
    func getOrderById(id: String) async throws -> Order
    
    /// Створення нового замовлення
    func createOrder(orderRequest: CreateOrderRequest) async throws -> Order
    
    /// Скасування замовлення
    func cancelOrder(id: String) async throws -> Order
}

struct CreateOrderRequest: Codable {
    let coffeeShopId: String
    let items: [CreateOrderItemRequest]
    let comment: String?
    let scheduledFor: Date?
}

struct CreateOrderItemRequest: Codable {
    let menuItemId: String
    let quantity: Int
    let customization: [String: String]?
}

class OrderRepository: OrderRepositoryProtocol {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService.shared) {
        self.networkService = networkService
    }
    
    // MARK: - Користувацький інтерфейс
    
    func getMyActiveOrders() async throws -> [Order] {
        return try await networkService.fetch(endpoint: "/orders/my")
    }
    
    func getMyOrderHistory() async throws -> [Order] {
        return try await networkService.fetch(endpoint: "/orders/my/history")
    }
    
    func getOrderById(id: String) async throws -> Order {
        return try await networkService.fetch(endpoint: "/orders/\(id)")
    }
    
    func createOrder(orderRequest: CreateOrderRequest) async throws -> Order {
        return try await networkService.post(endpoint: "/orders", body: orderRequest)
    }
    
    func cancelOrder(id: String) async throws -> Order {
        return try await networkService.patch(endpoint: "/orders/\(id)/cancel", body: EmptyBody())
    }
    
    // MARK: - Допоміжні структури
    
    struct EmptyBody: Codable {}
}
