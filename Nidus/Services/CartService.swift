//
//  CartService.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 5/18/25.
//

import Foundation
import Combine

class CartService {
    // Синглтон для доступу до сервісу
    static let shared = CartService()
    
    // Публікатор для сповіщення про зміни в корзині
    private let cartSubject = PassthroughSubject<Cart, Never>()
    var cartPublisher: AnyPublisher<Cart, Never> {
        return cartSubject.eraseToAnyPublisher()
    }
    
    // Ключ для збереження корзини в UserDefaults
    private let cartStorageKey = "nidus_cart"
    
    // Поточний стан корзини
    private var cart = Cart()
    
    // Посилання на TabBarManager для оновлення бейджа
    private weak var tabBarManager: TabBarManager?
    
    private init() {
        // При ініціалізації завантажуємо корзину з UserDefaults
        if let savedCart = loadCart() {
            self.cart = savedCart
        }
    }
    
    // Метод для встановлення табберу після ініціалізації DI контейнера
    func setupTabBarManager(_ manager: TabBarManager) {
        self.tabBarManager = manager
        // Оновлюємо лічильник товарів у бейджі
        updateBadgeCount()
    }
    
    // MARK: - Публічні методи для роботи з корзиною
    
    // Отримати поточний стан корзини
    func getCart() -> Cart {
        return cart
    }
    
    // Додати товар до корзини
    func addItem(_ item: CartItem) -> Bool {
        // Перевіряємо, чи можна додати товар з цієї кав'ярні
        if cart.canAddItemFromCoffeeShop(coffeeShopId: item.coffeeShopId) {
            var updatedCart = cart
            updatedCart.addItem(item)
            cart = updatedCart
            saveCart()
            cartSubject.send(cart)
            
            // Оновлюємо лічильник товарів у бейджі
            updateBadgeCount()
            
            return true
        }
        return false
    }
    
    // Оновити кількість товару
    func updateQuantity(for itemId: String, quantity: Int) {
        var updatedCart = cart
        updatedCart.updateQuantity(for: itemId, quantity: quantity)
        cart = updatedCart
        saveCart()
        cartSubject.send(cart)
        
        // Оновлюємо лічильник товарів у бейджі
        updateBadgeCount()
    }
    
    // Видалити товар за ID
    func removeItem(withId id: String) {
        var updatedCart = cart
        updatedCart.removeItem(withId: id)
        cart = updatedCart
        saveCart()
        cartSubject.send(cart)
        
        // Оновлюємо лічильник товарів у бейджі
        updateBadgeCount()
    }
    
    // Видалити товар за індексом
    func removeItem(at index: Int) {
        var updatedCart = cart
        updatedCart.removeItem(at: index)
        cart = updatedCart
        saveCart()
        cartSubject.send(cart)
        
        // Оновлюємо лічильник товарів у бейджі
        updateBadgeCount()
    }
    
    // Очистити корзину
    func clearCart() {
        var updatedCart = cart
        updatedCart.clear()
        cart = updatedCart
        saveCart()
        cartSubject.send(cart)
        
        // Оновлюємо лічильник товарів у бейджі
        updateBadgeCount()
    }
    
    // MARK: - Приватні методи для роботи зі сховищем
    
    // Оновлення лічильника товарів у бейджі таббару
    private func updateBadgeCount() {
        DispatchQueue.main.async {
            self.tabBarManager?.updateCartItemsCount(self.cart.itemCount)
        }
    }
    
    // Завантаження корзини з UserDefaults
    private func loadCart() -> Cart? {
        guard let data = UserDefaults.standard.data(forKey: cartStorageKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(Cart.self, from: data)
        } catch {
            print("Помилка декодування корзини: \(error)")
            return nil
        }
    }
    
    // Збереження корзини в UserDefaults
    private func saveCart() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(cart)
            UserDefaults.standard.set(data, forKey: cartStorageKey)
        } catch {
            print("Помилка кодування корзини: \(error)")
        }
    }
}
