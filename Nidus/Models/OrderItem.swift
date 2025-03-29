//
//  OrderItem.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

// OrderItem.swift
import Foundation

struct OrderItem: Identifiable, Codable {
    let id: String
    let orderId: String
    let menuItemId: String
    let name: String
    let price: Decimal
    let quantity: Int
    var customization: [String: Any]?
    let createdAt: Date
    var updatedAt: Date
    
    // Обчислювана властивість для загальної суми
    var total: Decimal {
        return price * Decimal(quantity)
    }
    
    // Спеціальні методи для кодування/декодування через JSON
    enum CodingKeys: String, CodingKey {
        case id, orderId, menuItemId, name, price, quantity, customization, createdAt, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        orderId = try container.decode(String.self, forKey: .orderId)
        menuItemId = try container.decode(String.self, forKey: .menuItemId)
        name = try container.decode(String.self, forKey: .name)
        price = try container.decode(Decimal.self, forKey: .price)
        quantity = try container.decode(Int.self, forKey: .quantity)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        if let customizationString = try container.decodeIfPresent(String.self, forKey: .customization),
           let data = customizationString.data(using: .utf8),
           let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            customization = json
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(orderId, forKey: .orderId)
        try container.encode(menuItemId, forKey: .menuItemId)
        try container.encode(name, forKey: .name)
        try container.encode(price, forKey: .price)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        
        if let customization = customization,
           let data = try? JSONSerialization.data(withJSONObject: customization),
           let customizationString = String(data: data, encoding: .utf8) {
            try container.encode(customizationString, forKey: .customization)
        }
    }
}
