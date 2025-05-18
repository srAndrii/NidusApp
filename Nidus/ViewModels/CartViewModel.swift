//
//  CartViewModel.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 5/18/25.
//

import Foundation
import Combine
import SwiftUI

class CartViewModel: ObservableObject {
    // MARK: - Published властивості
    
    // Стан корзини
    @Published var cart: Cart = Cart()
    
    // Стан завантаження
    @Published var isLoading = false
    
    // Повідомлення про помилку
    @Published var error: String?
    
    // Показ WebView для оплати
    @Published var showPaymentWebView = false
    
    // URL для WebView
    @Published var paymentUrl: URL?
    
    // Ідентифікатор поточного замовлення
    @Published var currentOrderId: String?
    
    // Показувати вікно конфлікту із іншою кав'ярнею
    @Published var showCoffeeShopConflict = false
    
    // Назва кав'ярні для вікна очищення корзини
    @Published var newCoffeeShopName: String = ""
    
    // Товар, який намагаємось додати (для конфлікту)
    @Published var pendingItem: CartItem?
    
    // Стан оплати
    @Published var paymentStatus: OrderPaymentStatusDto?
    
    // Показувати сповіщення про успішну оплату
    @Published var showPaymentSuccess = false
    
    // Для отримання даних про кав'ярню
    @Published var currentCoffeeShop: CoffeeShop?
    
    // MARK: - Сервіси і скасування підписок
    
    private let cartService = CartService.shared
    private let paymentService = PaymentService.shared
    private let coffeeShopRepository = DIContainer.shared.coffeeShopRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Ініціалізація
    
    init() {
        // Підписуємось на зміни у сервісі корзини
        cartService.cartPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedCart in
                self?.cart = updatedCart
                self?.loadCoffeeShopDetails()
            }
            .store(in: &cancellables)
        
        // Завантажуємо початковий стан корзини
        self.cart = cartService.getCart()
        
        // Завантажуємо дані про кав'ярню, якщо вона є в корзині
        if let coffeeShopId = cart.coffeeShopId {
            loadCoffeeShopDetails(for: coffeeShopId)
        }
    }
    
    // MARK: - Публічні методи
    
    /// Додавання товару до корзини з перевіркою на конфлікт кав'ярні
    func addToCart(item: MenuItem, coffeeShopId: String, coffeeShopName: String, quantity: Int = 1, selectedSize: String? = nil, customization: [String: Any]? = nil) {
        let cartItem = CartItem(
            from: item,
            coffeeShopId: coffeeShopId,
            quantity: quantity,
            selectedSize: selectedSize,
            customization: customization
        )
        
        // Перевіряємо, чи можна додати товар з цієї кав'ярні
        if !cart.canAddItemFromCoffeeShop(coffeeShopId: coffeeShopId) {
            // Зберігаємо дані для конфліктного вікна
            self.pendingItem = cartItem
            self.newCoffeeShopName = coffeeShopName
            self.showCoffeeShopConflict = true
            return
        }
        
        // Додаємо товар, якщо немає конфлікту
        _ = cartService.addItem(cartItem)
    }
    
    /// Очистити корзину і додати товар із нової кав'ярні
    func clearCartAndAddNewItem() {
        guard let item = pendingItem else { return }
        
        cartService.clearCart()
        _ = cartService.addItem(item)
        
        // Скидаємо дані про конфлікт
        self.pendingItem = nil
        self.showCoffeeShopConflict = false
    }
    
    /// Скасувати додавання і залишити поточну корзину
    func cancelAddingNewItem() {
        self.pendingItem = nil
        self.showCoffeeShopConflict = false
    }
    
    /// Оновлення кількості товару
    func updateQuantity(for itemId: String, quantity: Int) {
        cartService.updateQuantity(for: itemId, quantity: quantity)
    }
    
    /// Видалення товару за ID
    func removeItem(withId id: String) {
        cartService.removeItem(withId: id)
    }
    
    /// Видалення товару за індексом
    func removeItem(at index: Int) {
        cartService.removeItem(at: index)
    }
    
    /// Очищення корзини
    func clearCart() {
        cartService.clearCart()
    }
    
    /// Перевірка наявності товарів у корзині
    var isCartEmpty: Bool {
        return cart.isEmpty
    }
    
    /// Форматована загальна сума
    var formattedTotalPrice: String {
        return cart.formattedTotalPrice
    }
    
    /// Завантаження даних про кав'ярню
    private func loadCoffeeShopDetails(for coffeeShopId: String? = nil) {
        let id = coffeeShopId ?? cart.coffeeShopId
        
        guard let coffeeShopId = id else {
            self.currentCoffeeShop = nil
            return
        }
        
        Task {
            do {
                let coffeeShop = try await coffeeShopRepository.getCoffeeShopById(id: coffeeShopId)
                
                await MainActor.run {
                    self.currentCoffeeShop = coffeeShop
                }
            } catch {
                print("Помилка завантаження даних кав'ярні: \(error)")
            }
        }
    }
    
    // MARK: - Методи для оплати
    
    /// Створення замовлення та ініціація оплати
    @MainActor
    func checkout(comment: String? = nil) async -> Bool {
        guard !cart.isEmpty, let coffeeShopId = cart.coffeeShopId else {
            self.error = "Корзина порожня"
            return false
        }
        
        self.isLoading = true
        self.error = nil
        
        do {
            // Створюємо замовлення з оплатою
            let result = try await paymentService.createOrderWithPayment(
                coffeeShopId: coffeeShopId,
                items: cart.items,
                comment: comment
            )
            
            // Зберігаємо ID замовлення
            self.currentOrderId = result.orderId
            
            // Перевіряємо наявність URL для оплати
            if !result.paymentUrl.isEmpty,
               let url = URL(string: result.paymentUrl) {
                self.paymentUrl = url
                self.showPaymentWebView = true
                self.isLoading = false
                return true
            } else {
                self.error = "Не вдалося отримати посилання для оплати"
                self.isLoading = false
                return false
            }
        } catch let error as APIError {
            await handleAPIError(error)
            self.isLoading = false
            return false
        } catch {
            self.error = "Помилка: \(error.localizedDescription)"
            self.isLoading = false
            return false
        }
    }
    
    /// Перевірка статусу оплати замовлення
    @MainActor
    func checkPaymentStatus() async {
        guard let orderId = currentOrderId else {
            self.error = "Немає активного замовлення"
            return
        }
        
        self.isLoading = true
        
        do {
            let status = try await paymentService.getOrderPaymentStatus(orderId: orderId)
            self.paymentStatus = status
            
            // Якщо оплата успішна, очищаємо корзину
            if status.isPaid {
                cartService.clearCart()
                self.showPaymentSuccess = true
            }
            
            self.isLoading = false
        } catch {
            self.error = "Помилка перевірки статусу: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    /// Повторення оплати для поточного замовлення
    @MainActor
    func retryPayment() async -> Bool {
        guard let orderId = currentOrderId else {
            self.error = "Немає активного замовлення"
            return false
        }
        
        self.isLoading = true
        self.error = nil
        
        do {
            let result = try await paymentService.retryPayment(orderId: orderId)
            
            if !result.paymentUrl.isEmpty,
               let url = URL(string: result.paymentUrl) {
                self.paymentUrl = url
                self.showPaymentWebView = true
                self.isLoading = false
                return true
            } else {
                self.error = "Не вдалося отримати посилання для оплати"
                self.isLoading = false
                return false
            }
        } catch let error as APIError {
            await handleAPIError(error)
            self.isLoading = false
            return false
        } catch {
            self.error = "Помилка: \(error.localizedDescription)"
            self.isLoading = false
            return false
        }
    }
    
    /// Скасування замовлення
    @MainActor
    func cancelOrder() async {
        guard let orderId = currentOrderId else {
            self.error = "Немає активного замовлення"
            return
        }
        
        self.isLoading = true
        
        do {
            _ = try await paymentService.cancelOrder(orderId: orderId)
            self.currentOrderId = nil
            self.isLoading = false
        } catch {
            self.error = "Помилка скасування замовлення: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    /// Обробка помилок API
    @MainActor
    private func handleAPIError(_ error: APIError) async {
        switch error {
        case .serverError(_, let message):
            self.error = message ?? "Невідома помилка сервера"
        case .unauthorized:
            self.error = "Необхідна авторизація"
        default:
            self.error = error.localizedDescription
        }
    }
}
