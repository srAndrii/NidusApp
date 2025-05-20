//
//  CartItem.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 5/18/25.
//

import Foundation

struct CartItem: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    let menuItemId: String
    let coffeeShopId: String
    var quantity: Int
    var name: String
    var price: Decimal
    var imageUrl: String?
    var customization: [String: Any]?
    
    // Розмір для товарів з розмірами
    var selectedSize: String?
    
    // Обчислювана вартість елемента
    var totalPrice: Decimal {
        var finalPrice = price
        
        // Додаємо вартість опцій кастомізації
        if let customization = customization {
            // Додаємо ціну розміру, якщо є
            if let sizeData = customization["size"] as? [String: Any],
               let additionalPrice = sizeData["additionalPrice"] as? Decimal {
                finalPrice += additionalPrice
            }
            
            // Додаємо ціну опцій кастомізації
            if let options = customization["options"] as? [[String: Any]] {
                for option in options {
                    if let choices = option["choices"] as? [[String: Any]] {
                        for choice in choices {
                            if let choicePrice = choice["price"] as? Decimal,
                               let quantity = choice["quantity"] as? Int {
                                finalPrice += choicePrice * Decimal(quantity)
                            }
                        }
                    }
                }
            }
        }
        
        return finalPrice * Decimal(quantity)
    }
    
    // Ціна за одиницю товару з урахуванням кастомізації
    var unitPrice: Decimal {
        var finalPrice = price
        
        // Додаємо вартість опцій кастомізації
        if let customization = customization {
            // Додаємо ціну розміру, якщо є
            if let sizeData = customization["size"] as? [String: Any],
               let additionalPrice = sizeData["additionalPrice"] as? Decimal {
                finalPrice += additionalPrice
            }
            
            // Додаємо ціну опцій кастомізації
            if let options = customization["options"] as? [[String: Any]] {
                for option in options {
                    if let choices = option["choices"] as? [[String: Any]] {
                        for choice in choices {
                            if let choicePrice = choice["price"] as? Decimal,
                               let quantity = choice["quantity"] as? Int {
                                finalPrice += choicePrice * Decimal(quantity)
                            }
                        }
                    }
                }
            }
        }
        
        return finalPrice
    }
    
    // Метод для отримання компактного опису кастомізації для UI
    func getCustomizationSummary() -> String? {
        guard let customization = customization else {
            print("📝 CartItem.getCustomizationSummary: Немає даних кастомізації для товару \(name)")
            return nil
        }
        
        print("📝 CartItem.getCustomizationSummary: Отримуємо опис кастомізації для товару \(name)")
        print("   - Розмір: \(selectedSize ?? "не вказано")")
        print("   - Дані кастомізації: \(customization)")
        
        var summaryParts: [String] = []
        
        // Додаємо розмір якщо є
        if let size = selectedSize {
            summaryParts.append("Розмір: \(size)")
        }
        
        // Додаємо опції кастомізації
        if let options = customization["options"] as? [[String: Any]] {
            print("   - Кількість опцій: \(options.count)")
            for option in options.prefix(2) {
                if let name = option["name"] as? String,
                   let choices = option["choices"] as? [[String: Any]],
                   !choices.isEmpty {
                    let choiceNames = choices.compactMap { $0["name"] as? String }
                    let choiceText = choiceNames.joined(separator: ", ")
                    summaryParts.append("\(name): \(choiceText)")
                }
            }
            
            // Додаємо "+N" якщо є більше опцій
            if options.count > 2 {
                summaryParts.append("+ ще \(options.count - 2)")
            }
        }
        
        print("   - Сформований опис: \(summaryParts.joined(separator: "; "))")
        return summaryParts.isEmpty ? nil : summaryParts.joined(separator: "; ")
    }
    
    // Спеціальні методи для кодування/декодування через JSON
    enum CodingKeys: String, CodingKey {
        case id, menuItemId, coffeeShopId, quantity, name, price, imageUrl, customization, selectedSize
    }
    
    // Ініціалізатор для створення з MenuItem
    init(from menuItem: MenuItem, coffeeShopId: String, quantity: Int = 1, selectedSize: String? = nil, customization: [String: Any]? = nil) {
        self.menuItemId = menuItem.id
        self.coffeeShopId = coffeeShopId
        self.quantity = quantity
        self.name = menuItem.name
        self.price = menuItem.price
        self.imageUrl = menuItem.imageUrl
        self.selectedSize = selectedSize
        self.customization = customization
    }
    
    // Декодер для JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        menuItemId = try container.decode(String.self, forKey: .menuItemId)
        coffeeShopId = try container.decode(String.self, forKey: .coffeeShopId)
        quantity = try container.decode(Int.self, forKey: .quantity)
        name = try container.decode(String.self, forKey: .name)
        price = try container.decode(Decimal.self, forKey: .price)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        selectedSize = try container.decodeIfPresent(String.self, forKey: .selectedSize)
        
        if let customizationString = try container.decodeIfPresent(String.self, forKey: .customization),
           let data = customizationString.data(using: .utf8),
           let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            customization = json
        }
    }
    
    // Кодер для JSON
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(menuItemId, forKey: .menuItemId)
        try container.encode(coffeeShopId, forKey: .coffeeShopId)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(name, forKey: .name)
        try container.encode(price, forKey: .price)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(selectedSize, forKey: .selectedSize)
        
        if let customization = customization,
           let data = try? JSONSerialization.data(withJSONObject: customization),
           let customizationString = String(data: data, encoding: .utf8) {
            try container.encode(customizationString, forKey: .customization)
        }
    }
    
    // Для Equatable
    static func == (lhs: CartItem, rhs: CartItem) -> Bool {
        return lhs.id == rhs.id
    }
}
