import Foundation
import Combine

// MARK: - NetworkError enum
enum NetworkError: Error {
    case invalidURL
    case serverError
    case unauthorized
    case noInternetConnection
    case decodingError
    case unknown
}

protocol OrderHistoryServiceProtocol {
    func fetchOrderHistory(
        statuses: [OrderStatus]?,
        limit: Int?,
        page: Int?
    ) -> AnyPublisher<[OrderHistory], NetworkError>
    
    func fetchActiveOrders(
        limit: Int?,
        page: Int?
    ) -> AnyPublisher<[OrderHistory], NetworkError>
    
    func fetchOrderDetails(orderId: String) -> AnyPublisher<OrderHistory, NetworkError>
    func fetchOrderPaymentStatus(orderId: String) -> AnyPublisher<OrderPaymentInfo, NetworkError>
}

class OrderHistoryService: OrderHistoryServiceProtocol {
    private let networkService = NetworkService.shared
    
    func fetchOrderHistory(
        statuses: [OrderStatus]? = nil,
        limit: Int? = 20,
        page: Int? = 1
    ) -> AnyPublisher<[OrderHistory], NetworkError> {
        
        return Future { promise in
            Task {
                do {
                    var endpoint = "/orders/my/history"
                    var queryItems: [String] = []
        
        if let statuses = statuses {
            for status in statuses {
                            queryItems.append("status[]=\(status.rawValue)")
            }
        }
        
        if let limit = limit {
                        queryItems.append("limit=\(limit)")
        }
        
        if let page = page {
                        queryItems.append("page=\(page)")
                    }
                    
                    if !queryItems.isEmpty {
                        endpoint += "?" + queryItems.joined(separator: "&")
                    }
                    
                    // Детальне логування
                    print("🔍 OrderHistoryService: Запит до \(endpoint)")
                    print("📊 OrderHistoryService: Деталі запиту:")
                    print("   - Повний URL: \(self.networkService.getBaseURL())\(endpoint)")
                    print("   - Статуси фільтру: \(statuses?.map { $0.rawValue } ?? ["всі"])")
                    print("   - Сторінка: \(page ?? 1), Ліміт: \(limit ?? 20)")
                    
                    // Перевіряємо наявність токена
                    if let token = UserDefaults.standard.string(forKey: "accessToken") {
                        print("🔑 OrderHistoryService: Токен доступу є (довжина: \(token.count))")
                        print("🔑 OrderHistoryService: Токен початок: \(String(token.prefix(20)))...")
                    } else {
                        print("❌ OrderHistoryService: ТОКЕН ДОСТУПУ ВІДСУТНІЙ!")
                    }
                    
                    let result: [OrderHistory] = try await self.networkService.fetch(endpoint: endpoint)
                    
                    print("✅ OrderHistoryService: Отримано \(result.count) замовлень")
                    
                    // Витягуємо назви з отриманих замовлень та завантажуємо інформацію про кав'ярні
                    for order in result {
                        CustomizationNameService.shared.extractNamesFromOrder(order)
                        
                        // Якщо назва кав'ярні відсутня, спробуємо завантажити її
                        if order.coffeeShopName == nil && order.coffeeShop == nil {
                            Task {
                                await self.loadCoffeeShopInfo(for: order.coffeeShopId)
                            }
                        }
                    }
                    
                    // Детальне логування замовлень видалено для production
                    
                    promise(.success(result))
                } catch {
                    print("❌ OrderHistoryService: Помилка - \(error)")
                    print("🔍 OrderHistoryService: Тип помилки: \(type(of: error))")
                    if let apiError = error as? APIError {
                        print("🔍 OrderHistoryService: API помилка: \(apiError)")
                    }
                    promise(.failure(NetworkError.serverError))
                }
            }
        }
                .eraseToAnyPublisher()
        }
        
    func fetchActiveOrders(
        limit: Int? = 20,
        page: Int? = 1
    ) -> AnyPublisher<[OrderHistory], NetworkError> {
        
        return Future { promise in
            Task {
                do {
                    // Згідно з документацією для активних замовлень використовуємо /orders/my
                    var endpoint = "/orders/my"
                    var queryItems: [String] = []
                    
                    if let limit = limit {
                        queryItems.append("limit=\(limit)")
                    }
                    
                    if let page = page {
                        queryItems.append("page=\(page)")
                    }
                    
                    if !queryItems.isEmpty {
                        endpoint += "?" + queryItems.joined(separator: "&")
                    }
                    
                    print("🔍 OrderHistoryService: Запит активних замовлень до \(endpoint)")
                    print("📊 OrderHistoryService: Деталі запиту активних замовлень:")
                    print("   - Повний URL: \(self.networkService.getBaseURL())\(endpoint)")
                    print("   - Сторінка: \(page ?? 1), Ліміт: \(limit ?? 20)")
                    
                    let result: [OrderHistory] = try await self.networkService.fetch(endpoint: endpoint)
                    
                    // Логування активних замовлень видалено для production
                    
                    promise(.success(result))
                } catch {
                    print("❌ OrderHistoryService: Помилка отримання активних замовлень - \(error)")
                    promise(.failure(NetworkError.serverError))
                }
            }
            }
            .eraseToAnyPublisher()
    }
    
    func fetchOrderDetails(orderId: String) -> AnyPublisher<OrderHistory, NetworkError> {
        return Future { promise in
            Task {
                do {
                    let result: OrderHistory = try await self.networkService.fetch(endpoint: "/orders/\(orderId)")
                    promise(.success(result))
                } catch {
                    promise(.failure(NetworkError.serverError))
                }
            }
            }
            .eraseToAnyPublisher()
    }
    
    func fetchOrderPaymentStatus(orderId: String) -> AnyPublisher<OrderPaymentInfo, NetworkError> {
        return Future { promise in
            Task {
                do {
                    let response: OrderPaymentStatusResponse = try await self.networkService.fetch(endpoint: "/orders/\(orderId)/payment-status")
                    
                    let paymentInfo = OrderPaymentInfo(
                    id: response.paymentId ?? "",
                    status: PaymentStatus(rawValue: response.status) ?? .pending,
                    amount: response.paidAmount,
                    method: nil,
                    transactionId: nil,
                    createdAt: "",
                    completedAt: nil,
                    paymentUrl: nil
                )
                    
                    promise(.success(paymentInfo))
                } catch {
                    promise(.failure(NetworkError.serverError))
                }
            }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Допоміжні методи
    
    private func loadCoffeeShopInfo(for coffeeShopId: String) async {
        do {
            struct CoffeeShopInfo: Codable {
                let id: String
                let name: String
                let address: String?
            }
            
            let coffeeShop: CoffeeShopInfo = try await networkService.fetch(endpoint: "/coffee-shops/\(coffeeShopId)")
            
            // Зберігаємо інформацію в кеші для майбутнього використання безпечно
            DispatchQueue.main.async {
                CoffeeShopCache.shared.setCoffeeShop(coffeeShop.id, name: coffeeShop.name, address: coffeeShop.address)
            }
            
        } catch {
            print("❌ OrderHistoryService: Помилка завантаження кав'ярні \(coffeeShopId): \(error)")
        }
    }
    
    // MARK: - Методи для діагностики
    
    func diagnoseFetchIssue() async {
        print("🔍 OrderHistoryService: Початок діагностики проблеми з замовленнями")
        
        // 1. Перевіряємо інформацію про користувача
        await diagnoseUserInfo()
        
        // 2. Тестуємо різні endpoints
        await testDifferentEndpoints()
        
        // 3. Тестуємо конкретне замовлення
        await testSpecificOrder("90ae80b5-b06a-4554-9d97-63d0e0587239")
        
        // 4. НОВИЙ: Тестуємо пошук нових замовлень
        await testRecentOrders()
    }
    
    private func diagnoseUserInfo() async {
        print("\n👤 OrderHistoryService: Діагностика користувача")
        
        do {
            // Спробуємо отримати профіль користувача
            struct UserProfile: Codable {
                let id: String
                let email: String
                let firstName: String?
                let lastName: String?
                let roles: [UserRole]?
            }
            
            struct UserRole: Codable {
                let name: String
                let description: String
            }
            
            let profile: UserProfile = try await networkService.fetch(endpoint: "/user/profile")
            print("✅ Профіль користувача отримано:")
            print("   - ID: \(profile.id)")
            print("   - Email: \(profile.email)")
            print("   - Ім'я: \(profile.firstName ?? "не вказано")")
            print("   - Прізвище: \(profile.lastName ?? "не вказано")")
            print("   - Ролі: \(profile.roles?.map { $0.name } ?? ["немає"])")
            
            if let roles = profile.roles {
                for role in roles {
                    print("     - \(role.name): \(role.description)")
                }
            }
            
        } catch {
            print("❌ Не вдалося отримати профіль користувача: \(error)")
        }
    }
    
    private func testDifferentEndpoints() async {
        print("\n🧪 OrderHistoryService: Тестування різних endpoints")
        
        let endpoints = [
            "/orders/my",
            "/orders/my/history",
            "/orders/my?limit=50",
            "/orders/my/history?limit=50",
            "/orders/my/history?status[]=completed",
            "/orders/my/history?status[]=cancelled",
            "/orders/my?status[]=created&status[]=pending"
        ]
        
        for endpoint in endpoints {
            print("\n🔗 Тестую endpoint: \(endpoint)")
            do {
                let result: [OrderHistory] = try await networkService.fetch(endpoint: endpoint)
                print("✅ Відповідь: \(result.count) замовлень")
                if !result.isEmpty {
                    print("   Перше замовлення: \(result[0].orderNumber) (\(result[0].status.rawValue))")
                }
            } catch {
                print("❌ Помилка: \(error)")
            }
        }
    }
    
    private func testSpecificOrder(_ orderId: String) async {
        print("\n🎯 OrderHistoryService: Тестування конкретного замовлення")
        print("   ID замовлення: \(orderId)")
        
        do {
            let order: OrderHistory = try await networkService.fetch(endpoint: "/orders/\(orderId)")
            print("✅ Замовлення знайдено:")
            print("   - Номер: \(order.orderNumber)")
            print("   - Статус: \(order.status.rawValue)")
            print("   - Сума: \(order.totalAmount) ₴")
            print("   - Оплачено: \(order.isPaid)")
            print("   - Дата створення: \(order.formattedCreatedDate)")
        } catch {
            print("❌ Не вдалося отримати замовлення: \(error)")
        }
    }
    
    // НОВИЙ МЕТОД: Тестування нових замовлень
    private func testRecentOrders() async {
        print("\n🆕 OrderHistoryService: Пошук нових замовлень")
        
        // Перевіряємо активні замовлення
        do {
            let activeOrders: [OrderHistory] = try await networkService.fetch(endpoint: "/orders/my?limit=50")
            print("🟢 Активні замовлення: \(activeOrders.count)")
            
            let recentActive = activeOrders.filter { order in
                // Замовлення за останні 2 години
                if let date = ISO8601DateFormatter().date(from: order.createdAt) {
                    return Date().timeIntervalSince(date) < 7200 // 2 години
                }
                return false
            }
            
            if !recentActive.isEmpty {
                print("🎯 Знайдено \(recentActive.count) нових активних замовлень:")
                for order in recentActive {
                    print("   - \(order.orderNumber): \(order.status.rawValue) (\(order.totalAmount) ₴)")
                }
            } else {
                print("⚠️ Немає нових активних замовлень за останні 2 години")
            }
        } catch {
            print("❌ Помилка отримання активних замовлень: \(error)")
        }
        
        // Перевіряємо історію
        do {
            let historyOrders: [OrderHistory] = try await networkService.fetch(endpoint: "/orders/my/history?limit=50")
            print("📚 Історичні замовлення: \(historyOrders.count)")
            
            let recentHistory = historyOrders.filter { order in
                if let date = ISO8601DateFormatter().date(from: order.createdAt) {
                    return Date().timeIntervalSince(date) < 7200 // 2 години
                }
                return false
            }
            
            if !recentHistory.isEmpty {
                print("🎯 Знайдено \(recentHistory.count) нових історичних замовлень:")
                for order in recentHistory {
                    print("   - \(order.orderNumber): \(order.status.rawValue) (\(order.totalAmount) ₴)")
                }
            }
        } catch {
            print("❌ Помилка отримання історії: \(error)")
        }
    }
}

// MARK: - Supporting Types

struct OrderPaymentStatusResponse: Codable {
    let orderId: String
    let paymentId: String?
    let status: String
    let paidAmount: Double
    let isPaid: Bool
    let paymentUrl: String?
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

// MARK: - Mock Service для тестування

class MockOrderHistoryService: OrderHistoryServiceProtocol {
    func fetchOrderHistory(
        statuses: [OrderStatus]?,
        limit: Int?,
        page: Int?
    ) -> AnyPublisher<[OrderHistory], NetworkError> {
        
        let mockOrders = createMockOrderHistory()
        
        return Just(mockOrders)
            .setFailureType(to: NetworkError.self)
            .eraseToAnyPublisher()
    }
    
    func fetchActiveOrders(
        limit: Int?,
        page: Int?
    ) -> AnyPublisher<[OrderHistory], NetworkError> {
        
        let mockOrders = createMockOrderHistory().filter { 
            [OrderStatus.created, .pending, .accepted, .preparing, .ready].contains($0.status)
        }
        
        return Just(mockOrders)
            .setFailureType(to: NetworkError.self)
            .eraseToAnyPublisher()
    }
    
    func fetchOrderDetails(orderId: String) -> AnyPublisher<OrderHistory, NetworkError> {
        let mockOrder = createMockOrderHistory().first!
        
        return Just(mockOrder)
            .setFailureType(to: NetworkError.self)
            .eraseToAnyPublisher()
    }
    
    func fetchOrderPaymentStatus(orderId: String) -> AnyPublisher<OrderPaymentInfo, NetworkError> {
        let mockPayment = OrderPaymentInfo(
            id: "payment-1",
            status: .completed,
            amount: 120.0,
            method: "card",
            transactionId: "txn-123",
            createdAt: "2023-05-20T14:30:00Z",
            completedAt: "2023-05-20T14:32:00Z",
            paymentUrl: nil
        )
        
        return Just(mockPayment)
            .setFailureType(to: NetworkError.self)
            .eraseToAnyPublisher()
    }
    
    private func createMockOrderHistory() -> [OrderHistory] {
        return [
            OrderHistory(
                id: "order-1",
                orderNumber: "CAF-\(Date().timeIntervalSince1970)",
                status: OrderStatus.completed,
                totalAmount: 195.0,
                coffeeShopId: "shop-1",
                coffeeShopName: "Coffee House Central",
                coffeeShop: CoffeeShopInfo(
                    id: "shop-1",
                    name: "Coffee House Central",
                    address: "вул. Хрещатик, 1"
                ),
                isPaid: true,
                createdAt: "2023-12-01T10:30:00Z",
                completedAt: "2023-12-01T11:00:00Z",
                items: [
                    OrderHistoryItem(
                        id: "item-1",
                        name: "Капучино",
                        price: 95.0,
                        basePrice: 70.0,
                        finalPrice: 95.0,
                        quantity: 1,
                        customization: OrderItemCustomization(
                            selectedIngredients: nil,
                            selectedOptions: nil,
                            selectedSizeData: nil,
                            customizationDetails: CustomizationDetails(
                                size: CustomizationSizeDetail(name: "Великий", price: 10.0),
                                options: [
                                    CustomizationOptionDetail(
                                        name: "Ванільний сироп",
                                        price: 15.0,
                                        totalPrice: 15.0,
                                        quantity: 1
                                    )
                                ]
                            ),
                            customizationSummary: "Розмір: Великий (+10.00 ₴) | Ванільний сироп (+15.00 ₴)"
                        ),
                        sizeName: "Великий"
                    ),
                    OrderHistoryItem(
                        id: "item-2",
                        name: "Американо",
                        price: 50.0,
                        basePrice: 50.0,
                        finalPrice: 50.0,
                        quantity: 2,
                        customization: OrderItemCustomization(
                            customizationSummary: "Без кастомізацій"
                        ),
                        sizeName: "Середній"
                    )
                ],
                statusHistory: [
                    OrderStatusHistoryItem(
                        id: "history-1",
                        status: OrderStatus.created,
                        comment: "Замовлення створено",
                        createdAt: "2023-12-01T10:30:00Z",
                        createdBy: String?.none
                    ),
                    OrderStatusHistoryItem(
                        id: "history-2",
                        status: OrderStatus.completed,
                        comment: "Замовлення завершено",
                        createdAt: "2023-12-01T11:00:00Z",
                        createdBy: "Бариста Марія"
                    )
                ],
                payment: OrderPaymentInfo(
                    id: "payment-1",
                    status: .completed,
                    amount: 195.0,
                    method: "Monobank",
                    transactionId: "TXN123456",
                    createdAt: "2023-12-01T10:31:00Z",
                    completedAt: "2023-12-01T10:32:00Z",
                    paymentUrl: nil
                )
            )
        ]
    }
}