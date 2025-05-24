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
        print("📝 CartService.setupTabBarManager: Встановлюємо TabBarManager")
        self.tabBarManager = manager
        // Оновлюємо лічильник товарів у бейджі
        updateBadgeCount()
        print("✅ CartService.setupTabBarManager: TabBarManager успішно встановлено і бейдж оновлено")
    }
    
    // MARK: - Публічні методи для роботи з корзиною
    
    // Отримати поточний стан корзини
    func getCart() -> Cart {
        return cart
    }
    
    // Додати товар до корзини
    func addItem(_ item: CartItem) -> Bool {
        print("📝 CartService: Спроба додати товар до корзини: \(item.name)")
        // Перевіряємо, чи можна додати товар з цієї кав'ярні
        if cart.canAddItemFromCoffeeShop(coffeeShopId: item.coffeeShopId) {
            print("✅ CartService: Товар \(item.name) можна додати з кав'ярні \(item.coffeeShopId)")
            var updatedCart = cart
            updatedCart.addItem(item)
            cart = updatedCart
            saveCart()
            cartSubject.send(cart)
            
            // Оновлюємо лічильник товарів у бейджі
            updateBadgeCount()
            
            print("✅ CartService: Товар успішно додано, нова кількість товарів: \(cart.items.count)")
            return true
        }
        print("❌ CartService: Неможливо додати товар з іншої кав'ярні. Поточна кав'ярня: \(cart.coffeeShopId ?? "не встановлена"), нова кав'ярня: \(item.coffeeShopId)")
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
            if let tabBarManager = self.tabBarManager {
                tabBarManager.updateCartItemsCount(self.cart.itemCount)
                print("📝 CartService.updateBadgeCount: Оновлено лічильник кошика до \(self.cart.itemCount)")
            } else {
                print("⚠️ CartService.updateBadgeCount: TabBarManager не встановлено")
            }
        }
    }
    
    // Завантаження корзини з UserDefaults
    private func loadCart() -> Cart? {
        guard let data = UserDefaults.standard.data(forKey: cartStorageKey) else {
            print("📝 CartService.loadCart: Немає збережених даних корзини")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let loadedCart = try decoder.decode(Cart.self, from: data)
            print("✅ CartService.loadCart: Успішно завантажено корзину з \(loadedCart.items.count) товарами")
            
            // Логуємо деталі про кастомізацію для діагностики
            for (index, item) in loadedCart.items.enumerated() {
                print("📦 CartService.loadCart: Товар #\(index + 1): \(item.name), ID: \(item.id)")
                print("   - Базова ціна: \(item.price)")
                print("   - Кількість: \(item.quantity)")
                
                if let size = item.selectedSize {
                    print("   - Розмір: \(size)")
                }
                
                if let customization = item.customization {
                    print("   - Дані кастомізації: \(customization)")
                    
                    // Перевіряємо наявність даних про розмір
                    if let sizeData = customization["size"] as? [String: Any] {
                        print("     • Розмір: \(sizeData)")
                        if let additionalPrice = sizeData["additionalPrice"] {
                            print("       + Додаткова ціна за розмір: \(additionalPrice) (тип: \(type(of: additionalPrice)))")
                        }
                    }
                    
                    // Перевіряємо дані інгредієнтів
                    if let ingredients = customization["ingredients"] as? [[String: Any]] {
                        print("     • Інгредієнти (\(ingredients.count)):")
                        for (i, ingredient) in ingredients.enumerated() {
                            print("       \(i+1). \(ingredient["name"] ?? "Без назви")")
                            if let amount = ingredient["amount"] {
                                print("          Кількість: \(amount) (тип: \(type(of: amount)))")
                            }
                            if let freeAmount = ingredient["freeAmount"] {
                                print("          Безкоштовна кількість: \(freeAmount) (тип: \(type(of: freeAmount)))")
                            }
                            if let pricePerUnit = ingredient["pricePerUnit"] {
                                print("          Ціна за одиницю: \(pricePerUnit) (тип: \(type(of: pricePerUnit)))")
                            }
                        }
                    }
                    
                    // Перевіряємо дані опцій
                    if let options = customization["options"] as? [[String: Any]] {
                        print("     • Опції кастомізації (\(options.count)):")
                        for (i, option) in options.enumerated() {
                            print("       \(i+1). \(option["name"] ?? "Без назви")")
                            
                            if let choices = option["choices"] as? [[String: Any]] {
                                print("          Вибори (\(choices.count)):")
                                for (j, choice) in choices.enumerated() {
                                    print("            \(j+1). \(choice["name"] ?? "Без назви")")
                                    if let price = choice["price"] {
                                        print("               Ціна: \(price) (тип: \(type(of: price)))")
                                    }
                                    if let quantity = choice["quantity"] {
                                        print("               Кількість: \(quantity) (тип: \(type(of: quantity)))")
                                    }
                                    if let defaultQuantity = choice["defaultQuantity"] {
                                        print("               Базова кількість: \(defaultQuantity) (тип: \(type(of: defaultQuantity)))")
                                    }
                                    if let pricePerAdditionalUnit = choice["pricePerAdditionalUnit"] {
                                        print("               Ціна за додаткову одиницю: \(pricePerAdditionalUnit) (тип: \(type(of: pricePerAdditionalUnit)))")
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Розрахунок ціни
                print("   - Розрахована ціна за одиницю: \(item.unitPrice)")
                print("   - Загальна вартість: \(item.totalPrice)")
            }
            
            return loadedCart
        } catch {
            print("❌ CartService.loadCart: Помилка декодування корзини: \(error)")
            return nil
        }
    }
    
    // Збереження корзини в UserDefaults
    private func saveCart() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(cart)
            UserDefaults.standard.set(data, forKey: cartStorageKey)
            print("✅ CartService.saveCart: Корзина успішно збережена з \(cart.items.count) товарами")
        } catch {
            print("❌ CartService.saveCart: Помилка кодування корзини: \(error)")
        }
    }
}
