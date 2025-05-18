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
    
    private init() {
        // При ініціалізації завантажуємо корзину з UserDefaults
        if let savedCart = loadCart() {
            self.cart = savedCart
        }
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
    }
    
    // Видалити товар за ID
    func removeItem(withId id: String) {
        var updatedCart = cart
        updatedCart.removeItem(withId: id)
        cart = updatedCart
        saveCart()
        cartSubject.send(cart)
    }
    
    // Видалити товар за індексом
    func removeItem(at index: Int) {
        var updatedCart = cart
        updatedCart.removeItem(at: index)
        cart = updatedCart
        saveCart()
        cartSubject.send(cart)
    }
    
    // Очистити корзину
    func clearCart() {
        var updatedCart = cart
        updatedCart.clear()
        cart = updatedCart
        saveCart()
        cartSubject.send(cart)
    }
    
    // MARK: - Приватні методи для роботи зі сховищем
    
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
