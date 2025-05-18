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
        return price * Decimal(quantity)
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
