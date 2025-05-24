import Foundation
import Combine
import SwiftUI

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
    
    init() {
        setupSearchDebounce()
        setupOrderCreationListener()
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
        
        // Вибираємо правильний метод згідно з документацією
        let publisher: AnyPublisher<[OrderHistory], NetworkError>
        
        if selectedFilter == .all {
            // Для всіх замовлень використовуємо історію, але без фільтра статусів
            publisher = orderHistoryServiceProtocol.fetchOrderHistory(
                statuses: nil, // без фільтра - всі статуси
                limit: pageSize,
                page: page
            )
        } else if statuses?.contains(where: { [.completed, .cancelled].contains($0) }) == true {
            // Для завершених/скасованих використовуємо /orders/my/history
            publisher = orderHistoryServiceProtocol.fetchOrderHistory(
                statuses: statuses,
                limit: pageSize,
                page: page
            )
        } else {
            // Для активних замовлень використовуємо /orders/my
            publisher = orderHistoryServiceProtocol.fetchActiveOrders(
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
    
    init(order: OrderHistory, orderHistoryService: OrderHistoryServiceProtocol = OrderHistoryService()) {
        self.order = order
        self.orderHistoryService = orderHistoryService
        self.paymentInfo = order.payment
        
        if paymentInfo == nil {
            loadPaymentInfo()
        }
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
}