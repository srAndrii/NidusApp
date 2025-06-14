import Foundation
import Combine
import SwiftUI
import UIKit

@MainActor
class OrderHistoryViewModel: ObservableObject {
    @Published var orders: [OrderHistory] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: String?
    @Published var selectedFilter: OrderHistoryFilter = .all
    @Published var searchText = ""
    @Published var showingOrderDetails = false
    @Published var selectedOrder: OrderHistory?
    
    // Використовуємо справжній сервіс замість mock
    private let orderHistoryServiceProtocol: OrderHistoryServiceProtocol = OrderHistoryService()
    
    // Публічний доступ для діагностики
    var orderHistoryService: OrderHistoryService {
        return orderHistoryServiceProtocol as! OrderHistoryService
    }
    private var cancellables = Set<AnyCancellable>()
    private var currentPage = 1
    private var hasMoreData = true
    private let pageSize = 20
    private var webSocketCancellable: AnyCancellable?
    
    init() {
        setupSearchDebounce()
        setupOrderCreationListener()
        setupWebSocketListener()
        loadOrderHistory()
    }
    
    // MARK: - Public Methods
    
    func loadOrderHistory() {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        currentPage = 1
        hasMoreData = true
        
        fetchOrders(page: currentPage, isLoadMore: false)
    }
    
    func loadMoreOrdersIfNeeded() {
        guard !isLoadingMore && hasMoreData else { return }
        
        isLoadingMore = true
        currentPage += 1
        fetchOrders(page: currentPage, isLoadMore: true)
    }
    
    func refreshOrders() {
        loadOrderHistory()
    }
    
    func filterChanged(to filter: OrderHistoryFilter) {
        selectedFilter = filter
        loadOrderHistory()
    }
    
    func selectOrder(_ order: OrderHistory) {
        selectedOrder = order
        showingOrderDetails = true
    }
    
    func searchOrders(with text: String) {
        searchText = text
        // Пошук виконується через debounce
    }
    
    // MARK: - Computed Properties
    
    var filteredOrders: [OrderHistory] {
        var filtered = orders
        
        // Фільтрація за статусом
        if let statuses = selectedFilter.statuses {
            filtered = filtered.filter { statuses.contains($0.status) }
        }
        
        // Пошук за текстом
        if !searchText.isEmpty {
            filtered = filtered.filter { order in
                order.orderNumber.localizedCaseInsensitiveContains(searchText) ||
                order.coffeeShopName?.localizedCaseInsensitiveContains(searchText) == true ||
                order.items.contains { item in
                    item.name.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
        
        return filtered
    }
    
    var hasOrders: Bool {
        !orders.isEmpty
    }
    
    var isEmptyState: Bool {
        !isLoading && orders.isEmpty
    }
    
    // MARK: - Private Methods
    
    private func fetchOrders(page: Int, isLoadMore: Bool) {
        let statuses = selectedFilter.statuses
        
        print("🔄 OrderHistoryViewModel: Завантаження замовлень - фільтр: \(selectedFilter.displayName), сторінка: \(page)")
        
        // ВИПРАВЛЕННЯ: Правильна логіка для різних фільтрів
        if selectedFilter == .all {
            // Для "Всі" завантажуємо як активні, так і історичні замовлення
            fetchAllOrders(page: page, isLoadMore: isLoadMore)
            return
        }
        
        // Вибираємо правильний метод згідно з документацією
        let publisher: AnyPublisher<[OrderHistory], NetworkError>
        
        if selectedFilter == .pending {
            // Для активних замовлень (в обробці) використовуємо /orders/my
            publisher = orderHistoryServiceProtocol.fetchActiveOrders(
                limit: pageSize,
                page: page
            )
        } else {
            // Для завершених/скасованих використовуємо /orders/my/history
            publisher = orderHistoryServiceProtocol.fetchOrderHistory(
                statuses: statuses,
                limit: pageSize,
                page: page
            )
        }
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<NetworkError>) in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.handleError(error)
                    }
                    
                    self?.isLoading = false
                    self?.isLoadingMore = false
                },
                receiveValue: { [weak self] newOrders in
                    self?.handleOrdersReceived(newOrders, isLoadMore: isLoadMore)
                }
            )
            .store(in: &cancellables)
    }
    
    // НОВИЙ МЕТОД: Завантаження всіх замовлень (активні + історія)
    private func fetchAllOrders(page: Int, isLoadMore: Bool) {
        // Якщо це не перша сторінка, завантажуємо тільки історію (активні вже завантажені)
        if page > 1 {
            orderHistoryServiceProtocol.fetchOrderHistory(
                statuses: nil,
                limit: pageSize,
                page: page - 1 // Коригуємо номер сторінки для історії
            )
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.handleError(error)
                    }
                    
                    self?.isLoadingMore = false
                },
                receiveValue: { [weak self] historyOrders in
                    if isLoadMore {
                        self?.orders.append(contentsOf: historyOrders)
                    }
                    self?.hasMoreData = historyOrders.count == self?.pageSize
                }
            )
            .store(in: &cancellables)
            return
        }
        
        // Для першої сторінки завантажуємо спочатку активні замовлення
        let activeOrdersPublisher = orderHistoryServiceProtocol.fetchActiveOrders(limit: pageSize, page: 1)
        let historyOrdersPublisher = orderHistoryServiceProtocol.fetchOrderHistory(
            statuses: nil,
            limit: pageSize,
            page: 1
        )
        
        Publishers.CombineLatest(activeOrdersPublisher, historyOrdersPublisher)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.handleError(error)
                    }
                    
                    self?.isLoading = false
                },
                receiveValue: { [weak self] (activeOrders, historyOrders) in
                    print("✅ OrderHistoryViewModel: Завантажено \(activeOrders.count) активних та \(historyOrders.count) історичних замовлень")
                    
                    // Об'єднуємо замовлення: спочатку активні, потім історія
                    let allOrders = activeOrders + historyOrders
                    
                    // Сортуємо за датою створення (найновіші спочатку)
                    let sortedOrders = allOrders.sorted { first, second in
                        let firstDate = ISO8601DateFormatter().date(from: first.createdAt) ?? Date.distantPast
                        let secondDate = ISO8601DateFormatter().date(from: second.createdAt) ?? Date.distantPast
                        return firstDate > secondDate
                    }
                    
                    if isLoadMore {
                        self?.orders.append(contentsOf: sortedOrders)
                    } else {
                        self?.orders = sortedOrders
                    }
                    
                    // Встановлюємо hasMoreData на основі кількості історичних замовлень
                    self?.hasMoreData = historyOrders.count == self?.pageSize
                    self?.error = nil
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleOrdersReceived(_ newOrders: [OrderHistory], isLoadMore: Bool) {
        if isLoadMore {
            orders.append(contentsOf: newOrders)
        } else {
            orders = newOrders
        }
        
        // Перевіряємо, чи є ще дані
        hasMoreData = newOrders.count == pageSize
        
        error = nil
    }
    
    private func handleError(_ networkError: NetworkError) {
        switch networkError {
        case .unauthorized:
            error = "Потрібна авторизація"
        case .noInternetConnection:
            error = "Немає інтернет-з'єднання"
        case .serverError:
            error = "Помилка сервера"
        case .decodingError:
            error = "Помилка обробки даних"
        default:
            error = "Сталася помилка. Спробуйте пізніше"
        }
    }
    
    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { _ in
                // Пошук оновлюється автоматично через filteredOrders
            }
            .store(in: &cancellables)
    }
    
    private func setupOrderCreationListener() {
        // Прослуховуємо повідомлення про створення нових замовлень
        NotificationCenter.default.publisher(for: Notification.Name("OrderCreated"))
            .debounce(for: .seconds(2), scheduler: RunLoop.main) // Затримка щоб сервер встиг обробити
            .sink { [weak self] _ in
                print("🔔 OrderHistoryViewModel: Отримано сповіщення про нове замовлення - оновлюємо список")
                self?.refreshOrders()
            }
            .store(in: &cancellables)
        
        // Також прослуховуємо зміни статусу замовлень
        NotificationCenter.default.publisher(for: Notification.Name("OrderStatusUpdated"))
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                print("🔔 OrderHistoryViewModel: Отримано сповіщення про зміну статусу - оновлюємо список")
                self?.refreshOrders()
            }
            .store(in: &cancellables)
    }
    
    private func setupWebSocketListener() {
        // Підписуємося на оновлення статусів через WebSocket
        webSocketCancellable = OrderWebSocketManager.shared.orderStatusUpdatePublisher
            .sink { [weak self] updateData in
                print("🔄 OrderHistoryViewModel: Отримано WebSocket оновлення для замовлення \(updateData.orderId)")
                print("   Новий статус: \(updateData.newStatus.rawValue)")
                
                // Оновлюємо локальне замовлення
                self?.updateOrderStatus(
                    orderId: updateData.orderId,
                    newStatus: updateData.newStatus,
                    comment: updateData.comment
                )
            }
    }
    
    private func updateOrderStatus(orderId: String, newStatus: OrderStatus, comment: String?) {
        // Знаходимо замовлення в списку
        if let index = orders.firstIndex(where: { $0.id == orderId }) {
            let oldOrder = orders[index]
            
            // Створюємо новий запис історії статусів
            var updatedStatusHistory = oldOrder.statusHistory
            if comment != nil || oldOrder.statusHistory.last?.status != newStatus {
                let newStatusHistoryItem = OrderStatusHistoryItem(
                    id: UUID().uuidString,
                    status: newStatus,
                    comment: comment,
                    createdAt: ISO8601DateFormatter().string(from: Date()),
                    createdBy: "system"
                )
                updatedStatusHistory.append(newStatusHistoryItem)
            }
            
            // Створюємо нове замовлення з оновленим статусом
            let updatedOrder = OrderHistory(
                id: oldOrder.id,
                orderNumber: oldOrder.orderNumber,
                status: newStatus,
                totalAmount: oldOrder.totalAmount,
                coffeeShopId: oldOrder.coffeeShopId,
                coffeeShopName: oldOrder.coffeeShopName,
                coffeeShop: oldOrder.coffeeShop,
                isPaid: oldOrder.isPaid,
                createdAt: oldOrder.createdAt,
                completedAt: oldOrder.completedAt,
                items: oldOrder.items,
                statusHistory: updatedStatusHistory,
                payment: oldOrder.payment
            )
            
            // Оновлюємо замовлення в списку
            orders[index] = updatedOrder
            
            print("✅ OrderHistoryViewModel: Оновлено статус замовлення \(orderId) на \(newStatus.rawValue)")
            
            // Якщо це поточне вибране замовлення, оновлюємо його теж
            if selectedOrder?.id == orderId {
                selectedOrder = updatedOrder
            }
        } else {
            print("⚠️ OrderHistoryViewModel: Замовлення \(orderId) не знайдено в списку, оновлюємо весь список")
            refreshOrders()
        }
    }
}

// MARK: - Order Details ViewModel

@MainActor
class OrderDetailsViewModel: ObservableObject {
    @Published var order: OrderHistory
    @Published var paymentInfo: OrderPaymentInfo?
    @Published var isLoadingPayment = false
    @Published var error: String?
    
    private let orderHistoryService: OrderHistoryServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var webSocketCancellable: AnyCancellable?
    
    init(order: OrderHistory, orderHistoryService: OrderHistoryServiceProtocol = OrderHistoryService()) {
        self.order = order
        self.orderHistoryService = orderHistoryService
        self.paymentInfo = order.payment
        
        // Витягуємо назви з існуючих даних замовлення безпечно
        Task {
            // Спочатку витягуємо назви з замовлення
            CustomizationNameService.shared.extractNamesFromOrder(order)
            
            // Завантажуємо додаткові назви з API тільки якщо потрібно
            await loadCustomizationNamesIfNeeded()
            
            // Оновлюємо UI після завантаження
            await MainActor.run {
                self.objectWillChange.send()
            }
        }
        
        if paymentInfo == nil {
            loadPaymentInfo()
        }
        
        // Підписуємося на повідомлення про успішну оплату
        NotificationCenter.default.publisher(for: .paymentSuccessful)
            .sink { [weak self] _ in
                print("🔔 OrderDetailsViewModel: Отримано повідомлення про успішну оплату")
                self?.refreshPaymentInfo()
            }
            .store(in: &cancellables)
        
        // Підписуємося на WebSocket оновлення для цього замовлення
        setupWebSocketListener()
    }
    
    // MARK: - Public Methods
    
    func loadPaymentInfo() {
        guard !isLoadingPayment else { return }
        
        isLoadingPayment = true
        error = nil
        
        orderHistoryService.fetchOrderPaymentStatus(orderId: order.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.handleError(error)
                    }
                    
                    self?.isLoadingPayment = false
                },
                receiveValue: { [weak self] payment in
                    self?.paymentInfo = payment
                    self?.error = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func refreshPaymentInfo() {
        loadPaymentInfo()
    }
    
    func refreshCustomizationNames() {
        Task {
            // Витягуємо назви з існуючих даних замовлення
            CustomizationNameService.shared.extractNamesFromOrder(order)
            
            // Завантажуємо додаткові назви з API
            await loadCustomizationNamesIfNeeded()
            
            // Також завантажуємо інформацію про кав'ярню, якщо її немає
            if order.coffeeShopName == nil && order.coffeeShop == nil {
                await loadCoffeeShopInfo()
            }
            
            // Оновлюємо UI після завантаження
            await MainActor.run {
                self.objectWillChange.send()
            }
        }
    }
    
    func retryPayment() {
        print("🔄 OrderDetailsViewModel.retryPayment() викликано")
        print("   - order.isPaid: \(order.isPaid)")
        print("   - paymentInfo: \(paymentInfo?.status.rawValue ?? "nil")")
        
        // Якщо замовлення вже оплачене, не дозволяємо повторну оплату
        if order.isPaid {
            print("❌ OrderDetailsViewModel: Замовлення вже оплачене")
            error = "Замовлення вже оплачене"
            return
        }
        
        // Якщо є paymentInfo і paymentUrl, відкриваємо його
        if let paymentInfo = paymentInfo, 
           let paymentUrl = paymentInfo.paymentUrl,
           !paymentUrl.isEmpty {
            print("✅ OrderDetailsViewModel: Використовуємо існуючий paymentUrl: \(paymentUrl)")
            openPaymentURL(paymentUrl)
        } else {
            // Інакше викликаємо retry-payment endpoint
            print("🔄 OrderDetailsViewModel: Викликаємо retry-payment endpoint")
            Task {
                await performRetryPayment()
            }
        }
    }
    
    func cancelOrder() async {
        print("🚫 OrderDetailsViewModel.cancelOrder() викликано")
        print("   - order.status: \(order.status.rawValue)")
        print("   - order.isPaid: \(order.isPaid)")
        
        // Перевіряємо, чи можна скасувати замовлення
        // Дозволяємо скасування тільки для статусу 'created'
        guard order.status == .created else {
            await MainActor.run {
                self.error = "Замовлення можна скасувати тільки зі статусом 'Створено'"
            }
            return
        }
        
        do {
            let paymentService = PaymentService.shared
            let canceledOrder = try await paymentService.cancelOrder(orderId: order.id)
            
            await MainActor.run {
                // Оновлюємо локальні дані замовлення
                self.order = OrderHistory(
                    id: canceledOrder.id,
                    orderNumber: self.order.orderNumber, // Використовуємо існуючий orderNumber
                    status: canceledOrder.status,
                    totalAmount: Double(truncating: canceledOrder.totalAmount as NSDecimalNumber),
                    coffeeShopId: self.order.coffeeShopId,
                    coffeeShopName: self.order.coffeeShopName,
                    coffeeShop: self.order.coffeeShop,
                    isPaid: canceledOrder.isPaid,
                    createdAt: self.order.createdAt, // Зберігаємо оригінальну дату створення
                    completedAt: self.order.completedAt, // Зберігаємо існуюче значення
                    items: self.order.items,
                    statusHistory: self.order.statusHistory,
                    payment: self.order.payment
                )
                
                // Відправляємо повідомлення про оновлення статусу
                NotificationCenter.default.post(name: Notification.Name("OrderStatusUpdated"), object: nil)
                
                print("✅ OrderDetailsViewModel: Замовлення успішно скасовано")
            }
        } catch {
            await MainActor.run {
                self.error = "Не вдалося скасувати замовлення: \(error.localizedDescription)"
                print("❌ OrderDetailsViewModel: Помилка скасування: \(error)")
            }
        }
    }
    
    private func performRetryPayment() async {
        do {
            let paymentService = PaymentService.shared
            let result = try await paymentService.retryPayment(orderId: order.id)
            
            await MainActor.run {
                self.openPaymentURL(result.paymentUrl)
            }
        } catch {
            await MainActor.run {
                self.error = "Не вдалося створити нове посилання для оплати"
            }
        }
    }
    
    private func openPaymentURL(_ urlString: String) {
        guard URL(string: urlString) != nil else {
            error = "Неправильне посилання для оплати"
            return
        }
        
        print("🌐 OrderDetailsViewModel: Відкриваємо payment URL: \(urlString)")
        
        // Відправляємо notification для відкриття WebView з MainView
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name("OpenPaymentWebView"),
                object: nil,
                userInfo: ["url": urlString, "orderId": self.order.id]
            )
        }
    }
    
    private func loadCustomizationNamesIfNeeded() async {
        // Перевіряємо, чи потрібно завантажувати назви
        var needsLoading = false
        
        for item in order.items {
            if let customization = item.customization {
                // Якщо є selectedIngredients з ID, але немає назв
                if let ingredients = customization.selectedIngredients {
                    for ingredientId in ingredients.keys {
                        if CustomizationNameService.shared.getIngredientName(for: ingredientId) == nil {
                            needsLoading = true
                            break
                        }
                    }
                }
                
                // Якщо є selectedOptions з ID, але немає назв
                if let options = customization.selectedOptions {
                    for (_, choices) in options {
                        for choice in choices {
                            if choice.name == nil && CustomizationNameService.shared.getOptionName(for: choice.id) == nil {
                                needsLoading = true
                                break
                            }
                        }
                        if needsLoading { break }
                    }
                }
            }
            if needsLoading { break }
        }
        
        if needsLoading {
            print("🔄 OrderDetailsViewModel: Завантажуємо назви кастомізацій з меню")
            await CustomizationNameService.shared.loadNamesFromCoffeeShop(order.coffeeShopId)
        } else {
            print("✅ OrderDetailsViewModel: Назви кастомізацій вже є, завантаження не потрібне")
        }
    }
    
    private func loadCoffeeShopInfo() async {
        do {
            print("🏪 OrderDetailsViewModel: Завантажуємо інформацію про кав'ярню \(order.coffeeShopId)")
            
            struct CoffeeShopInfo: Codable {
                let id: String
                let name: String
                let address: String?
            }
            
            let networkService = NetworkService.shared
            let coffeeShop: CoffeeShopInfo = try await networkService.fetch(endpoint: "/coffee-shops/\(order.coffeeShopId)")
            print("✅ OrderDetailsViewModel: Завантажено кав'ярню: \(coffeeShop.name)")
            
            // Зберігаємо інформацію в кеші безпечно
            await MainActor.run {
                CoffeeShopCache.shared.setCoffeeShop(coffeeShop.id, name: coffeeShop.name, address: coffeeShop.address)
            }
            
        } catch {
            print("❌ OrderDetailsViewModel: Помилка завантаження кав'ярні \(order.coffeeShopId): \(error)")
        }
    }
    
    // MARK: - Computed Properties
    
    var canShowPaymentInfo: Bool {
        paymentInfo != nil || !isLoadingPayment
    }
    
    var totalItemsCount: Int {
        order.items.reduce(0) { $0 + $1.quantity }
    }
    
    var formattedTotalAmount: String {
        String(format: "%.2f ₴", order.totalAmount)
    }
    
    // MARK: - Private Methods
    
    private func handleError(_ networkError: NetworkError) {
        switch networkError {
        case .unauthorized:
            error = "Потрібна авторизація"
        case .noInternetConnection:
            error = "Немає інтернет-з'єднання"
        case .serverError:
            error = "Помилка сервера"
        case .decodingError:
            error = "Помилка обробки даних"
        default:
            error = "Не вдалося завантажити інформацію про оплату"
        }
    }
    
    private func setupWebSocketListener() {
        // Зберігаємо cancellables для proper cleanup
        var cancellables = Set<AnyCancellable>()
        
        // 1. Підписуємося на оновлення статусів через WebSocket для цього конкретного замовлення
        OrderWebSocketManager.shared.orderStatusUpdatePublisher
            .filter { [weak self] updateData in
                updateData.orderId == self?.order.id
            }
            .sink { [weak self] updateData in
                print("🔄 OrderDetailsViewModel: Отримано WebSocket orderStatusUpdated")
                print("   Новий статус: \(updateData.newStatus.rawValue)")
                print("   Comment: \(updateData.comment ?? "nil")")
                print("   CancelledBy: \(updateData.cancelledBy ?? "nil")")
                print("   CancellationActor: \(updateData.cancellationActor ?? "nil")")
                print("   CancellationReason: \(updateData.cancellationReason ?? "nil")")
                print("   NEW - isPaid: \(updateData.isPaid?.description ?? "nil")")
                print("   NEW - isReady: \(updateData.isReady?.description ?? "nil")")
                print("   NEW - estimatedReadyTime: \(updateData.estimatedReadyTime?.description ?? "nil")")
                print("   NEW - staffComment: \(updateData.staffComment ?? "nil")")
                print("   NEW - refundStatus: \(updateData.refundStatus ?? "nil")")
                print("   NEW - refundAmount: \(updateData.refundAmount?.description ?? "nil")")
                
                // Оновлюємо замовлення з розширеними даними
                self?.updateOrderFromWebSocket(updateData)
            }
            .store(in: &cancellables)
        
        // 2. NEW: Підписуємося на спеціалізовану подію orderCancelled
        OrderWebSocketManager.shared.orderCancellationPublisher
            .filter { [weak self] cancellationData in
                cancellationData.orderId == self?.order.id
            }
            .sink { [weak self] cancellationData in
                print("🚫 OrderDetailsViewModel: Отримано WebSocket orderCancelled")
                print("   Order ID: \(cancellationData.orderId)")
                print("   Order Number: \(cancellationData.orderNumber)")
                print("   Cancelled By: \(cancellationData.cancelledBy)")
                print("   Cancellation Actor: \(cancellationData.cancellationActor)")
                print("   Cancellation Reason: \(cancellationData.cancellationReason ?? "nil")")
                print("   Comment: \(cancellationData.comment ?? "nil")")
                print("   Refund Status: \(cancellationData.refundStatus ?? "nil")")
                print("   Refund Amount: \(cancellationData.refundAmount?.description ?? "nil")")
                
                // Обробляємо скасування з повними даними
                self?.handleOrderCancellation(cancellationData)
            }
            .store(in: &cancellables)
        
        // Зберігаємо cancellables
        self.cancellables.formUnion(cancellables)
    }
    
    // NEW: Оновлення замовлення з розширеними WebSocket даними
    private func updateOrderFromWebSocket(_ updateData: OrderWebSocketManager.OrderStatusUpdateData) {
        print("🔧 OrderDetailsViewModel: updateOrderFromWebSocket викликано")
        print("   newStatus: \(updateData.newStatus.rawValue)")
        print("   isPaid: \(updateData.isPaid?.description ?? "nil")")
        print("   isReady: \(updateData.isReady?.description ?? "nil")")
        print("   estimatedReadyTime: \(updateData.estimatedReadyTime?.description ?? "nil")")
        print("   staffComment: \(updateData.staffComment ?? "nil")")
        print("   refundStatus: \(updateData.refundStatus ?? "nil")")
        print("   refundAmount: \(updateData.refundAmount?.description ?? "nil")")
        
        // Якщо замовлення скасовано, завантажуємо повні дані з сервера
        if updateData.newStatus == .cancelled {
            print("🔄 OrderDetailsViewModel: Замовлення скасовано - завантажуємо повні дані з API")
            Task {
                await self.refreshOrderDetails()
            }
            return
        }
        
        // Створюємо новий запис історії статусів
        var updatedStatusHistory = order.statusHistory
        if updateData.comment != nil || order.statusHistory.last?.status != updateData.newStatus {
            let newStatusHistoryItem = OrderStatusHistoryItem(
                id: UUID().uuidString,
                status: updateData.newStatus,
                comment: updateData.staffComment ?? updateData.comment,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                createdBy: updateData.changedBy ?? "system"
            )
            updatedStatusHistory.append(newStatusHistoryItem)
        }
        
        // Оновлюємо замовлення з новими даними
        order = OrderHistory(
            id: order.id,
            orderNumber: order.orderNumber,
            status: updateData.newStatus,
            totalAmount: order.totalAmount,
            coffeeShopId: order.coffeeShopId,
            coffeeShopName: order.coffeeShopName,
            coffeeShop: order.coffeeShop,
            isPaid: updateData.isPaid ?? order.isPaid,
            createdAt: order.createdAt,
            completedAt: order.completedAt,
            items: order.items,
            statusHistory: updatedStatusHistory,
            payment: order.payment,
            cancelledBy: updateData.cancelledBy ?? order.cancelledBy,
            cancellationActor: updateData.cancellationActor ?? order.cancellationActor,
            cancellationReason: updateData.cancellationReason ?? order.cancellationReason,
            comment: updateData.comment ?? order.comment
        )
        
        print("✅ OrderDetailsViewModel: Оновлено замовлення з WebSocket даними")
        print("   NEW isPaid: \(order.isPaid)")
        print("   NEW status: \(order.status.rawValue)")
        
        // Оновлюємо UI
        objectWillChange.send()
    }
    
    // NEW: Обробка спеціалізованої події orderCancelled
    private func handleOrderCancellation(_ cancellationData: OrderWebSocketManager.OrderCancellationData) {
        print("🚫 OrderDetailsViewModel: handleOrderCancellation викликано")
        print("   cancellationReason: \(cancellationData.cancellationReason ?? "nil")")
        print("   comment: \(cancellationData.comment ?? "nil")")
        print("   refundStatus: \(cancellationData.refundStatus ?? "nil")")
        print("   refundAmount: \(cancellationData.refundAmount?.description ?? "nil")")
        
        // Використовуємо новий API для отримання правильного коментаря
        let cancellationMessage = order.getCancellationMessage(from: cancellationData)
        print("   📝 Фінальний коментар: \(cancellationMessage ?? "nil")")
        
        // Завантажуємо повні дані з API для найбільш актуальної інформації
        Task {
            await self.refreshOrderDetails()
        }
        
        // Оновлюємо UI негайно з даними від WebSocket
        order = OrderHistory(
            id: order.id,
            orderNumber: order.orderNumber,
            status: .cancelled,
            totalAmount: order.totalAmount,
            coffeeShopId: order.coffeeShopId,
            coffeeShopName: order.coffeeShopName,
            coffeeShop: order.coffeeShop,
            isPaid: order.isPaid,
            createdAt: order.createdAt,
            completedAt: order.completedAt,
            items: order.items,
            statusHistory: order.statusHistory,
            payment: order.payment,
            cancelledBy: cancellationData.cancelledBy,
            cancellationActor: cancellationData.cancellationActor,
            cancellationReason: cancellationData.cancellationReason,
            comment: cancellationData.comment ?? order.comment
        )
        
        print("✅ OrderDetailsViewModel: Оновлено замовлення з cancellation даними")
        
        // Оновлюємо UI
        objectWillChange.send()
    }
    
    private func updateOrderStatus(newStatus: OrderStatus, comment: String?, cancelledBy: String? = nil, cancellationActor: String? = nil, cancellationReason: String? = nil) {
        print("🔧 OrderDetailsViewModel: updateOrderStatus викликано")
        print("   newStatus: \(newStatus.rawValue)")
        print("   comment: \(comment ?? "nil")")
        print("   cancelledBy: \(cancelledBy ?? "nil")")
        print("   cancellationActor: \(cancellationActor ?? "nil")")
        print("   cancellationReason: \(cancellationReason ?? "nil")")
        
        // Створюємо новий запис історії статусів
        var updatedStatusHistory = order.statusHistory
        if comment != nil || order.statusHistory.last?.status != newStatus {
            let newStatusHistoryItem = OrderStatusHistoryItem(
                id: UUID().uuidString,
                status: newStatus,
                comment: comment,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                createdBy: "system"
            )
            updatedStatusHistory.append(newStatusHistoryItem)
        }
        
        // Створюємо нове замовлення з оновленим статусом
        order = OrderHistory(
            id: order.id,
            orderNumber: order.orderNumber,
            status: newStatus,
            totalAmount: order.totalAmount,
            coffeeShopId: order.coffeeShopId,
            coffeeShopName: order.coffeeShopName,
            coffeeShop: order.coffeeShop,
            isPaid: order.isPaid,
            createdAt: order.createdAt,
            completedAt: order.completedAt,
            items: order.items,
            statusHistory: updatedStatusHistory,
            payment: order.payment,
            cancelledBy: cancelledBy ?? order.cancelledBy,
            cancellationActor: cancellationActor ?? order.cancellationActor,
            cancellationReason: cancellationReason ?? order.cancellationReason,
            comment: comment ?? order.comment
        )
        
        print("✅ OrderDetailsViewModel: Оновлено статус замовлення на \(newStatus.rawValue)")
        print("🔍 Нове замовлення після оновлення:")
        print("   order.cancelledBy: \(order.cancelledBy ?? "nil")")
        print("   order.cancellationActor: \(order.cancellationActor ?? "nil")")
        print("   order.cancellationReason: \(order.cancellationReason ?? "nil")")
        print("   order.comment: \(order.comment ?? "nil")")
        print("   order.cancellationDisplayText: \(order.cancellationDisplayText ?? "nil")")
        print("   order.cancellationComment: \(order.cancellationComment ?? "nil")")
        
        // Оновлюємо UI
        objectWillChange.send()
    }
    
    private func refreshOrderDetails() async {
        print("🔄 OrderDetailsViewModel: Завантажуємо повні дані замовлення \(order.id)")
        
        do {
            // Завантажуємо повні дані замовлення з сервера
            let fullOrderData = try await orderHistoryService.getOrderDetails(orderId: order.id)
            
            DispatchQueue.main.async {
                print("✅ OrderDetailsViewModel: Отримано повні дані замовлення")
                print("   cancellationActor: \(fullOrderData.cancellationActor ?? "nil")")
                print("   cancellationReason: \(fullOrderData.cancellationReason ?? "nil")")
                print("   comment: \(fullOrderData.comment ?? "nil")")
                
                // Оновлюємо замовлення з повними даними
                self.order = fullOrderData
                self.objectWillChange.send()
            }
        } catch {
            print("❌ OrderDetailsViewModel: Помилка завантаження повних даних: \(error)")
        }
    }
    
    deinit {
        webSocketCancellable?.cancel()
    }
}