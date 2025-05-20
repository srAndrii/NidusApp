//
//  Untitled.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 5/18/25.
//

import Foundation

struct Cart: Codable {
    var items: [CartItem] = []
    var coffeeShopId: String? = nil
    
    // Обчислювані властивості
    var isEmpty: Bool {
        return items.isEmpty
    }
    
    var itemCount: Int {
        return items.reduce(0) { $0 + $1.quantity }
    }
    
    var totalPrice: Decimal {
        return items.reduce(Decimal(0)) { $0 + $1.totalPrice }
    }
    
    // Форматована загальна сума
    var formattedTotalPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "UAH"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: totalPrice)) ?? "₴\(totalPrice)"
    }
    
    // Перевірка, чи додавання нового товару з іншої кав'ярні можливе
    func canAddItemFromCoffeeShop(coffeeShopId: String) -> Bool {
        // Якщо корзина порожня або містить товари з тієї ж кав'ярні
        let isEmpty = items.isEmpty
        let isSameCoffeeShop = self.coffeeShopId == coffeeShopId
        
        print("📝 Cart.canAddItemFromCoffeeShop: Корзина порожня? \(isEmpty), Той же ID кав'ярні? \(isSameCoffeeShop)")
        print("   - Поточний ID кав'ярні в корзині: \(self.coffeeShopId ?? "не встановлений")")
        print("   - ID кав'ярні нового товару: \(coffeeShopId)")
        
        return isEmpty || isSameCoffeeShop
    }
    
    // Додавання товару до корзини
    mutating func addItem(_ item: CartItem) {
        // Якщо корзина порожня, встановлюємо ID кав'ярні
        if items.isEmpty {
            self.coffeeShopId = item.coffeeShopId
            print("📝 Cart: Корзина була порожня, встановлено ID кав'ярні: \(item.coffeeShopId)")
        }
        
        // Перевіряємо, чи вже є такий товар у корзині
        if let index = items.firstIndex(where: { $0.menuItemId == item.menuItemId && $0.selectedSize == item.selectedSize }) {
            // Збільшуємо кількість існуючого товару
            items[index].quantity += item.quantity
            print("📝 Cart: Збільшено кількість існуючого товару \(item.name) до \(items[index].quantity)")
        } else {
            // Додаємо новий товар
            items.append(item)
            print("📝 Cart: Додано новий товар \(item.name), кількість товарів тепер: \(items.count)")
        }
    }
    
    // Оновлення кількості товару
    mutating func updateQuantity(for itemId: String, quantity: Int) {
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            items[index].quantity = max(1, quantity)  // Мінімальна кількість - 1
        }
    }
    
    // Видалення товару з корзини
    mutating func removeItem(at index: Int) {
        guard index < items.count else { return }
        items.remove(at: index)
        
        // Якщо корзина порожня, скидаємо ID кав'ярні
        if items.isEmpty {
            coffeeShopId = nil
        }
    }
    
    // Видалення товару за ID
    mutating func removeItem(withId id: String) {
        items.removeAll(where: { $0.id == id })
        
        // Якщо корзина порожня, скидаємо ID кав'ярні
        if items.isEmpty {
            coffeeShopId = nil
        }
    }
    
    // Очищення корзини
    mutating func clear() {
        items.removeAll()
        coffeeShopId = nil
    }
}
