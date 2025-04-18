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
    
    // MARK: - Адміністративний інтерфейс
    /// Отримання замовлень для конкретної кав'ярні з можливістю фільтрації
    func getCoffeeShopOrders(coffeeShopId: String, status: [String]?, startDate: Date?, endDate: Date?) async throws -> [Order]
    
    /// Оновлення статусу замовлення (для адміністраторів та персоналу кав'ярні)
    func updateOrderStatus(id: String, status: OrderStatus, comment: String?) async throws -> Order
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
    
    // MARK: - Адміністративний інтерфейс
    
    func getCoffeeShopOrders(coffeeShopId: String, status: [String]?, startDate: Date?, endDate: Date?) async throws -> [Order] {
        var endpoint = "/orders/coffee-shop/\(coffeeShopId)?"
        
        if let status = status, !status.isEmpty {
            let statusString = status.joined(separator: ",")
            endpoint += "status=\(statusString)&"
        }
        
        let dateFormatter = ISO8601DateFormatter()
        
        if let startDate = startDate {
            let startDateString = dateFormatter.string(from: startDate)
            endpoint += "startDate=\(startDateString)&"
        }
        
        if let endDate = endDate {
            let endDateString = dateFormatter.string(from: endDate)
            endpoint += "endDate=\(endDateString)&"
        }
        
        // Видаляємо останній символ, якщо це '&' або '?'
        if endpoint.last == "&" || endpoint.last == "?" {
            endpoint.removeLast()
        }
        
        return try await networkService.fetch(endpoint: endpoint)
    }
    
    struct UpdateStatusRequest: Codable {
        let status: String
        let comment: String?
    }
    
    func updateOrderStatus(id: String, status: OrderStatus, comment: String?) async throws -> Order {
        let updateRequest = UpdateStatusRequest(status: status.rawValue, comment: comment)
        return try await networkService.patch(endpoint: "/orders/\(id)/status", body: updateRequest)
    }
    
    // MARK: - Допоміжні структури
    
    struct EmptyBody: Codable {}
}
