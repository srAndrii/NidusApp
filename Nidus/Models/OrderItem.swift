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
    let basePrice: Decimal?
    let finalPrice: Decimal?
    let quantity: Int
    let sizeName: String?
    var customization: [String: Any]?
    let customizationSummary: String?
    let createdAt: Date
    var updatedAt: Date
    
    // Обчислювана властивість для загальної суми
    var total: Decimal {
        return price * Decimal(quantity)
    }
    
    // Спеціальні методи для кодування/декодування через JSON
    enum CodingKeys: String, CodingKey {
        case id, orderId, menuItemId, name, price, basePrice, finalPrice, quantity, sizeName, customization, customizationDetails, customizationSummary, createdAt, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        orderId = try container.decode(String.self, forKey: .orderId)
        menuItemId = try container.decode(String.self, forKey: .menuItemId)
        name = try container.decode(String.self, forKey: .name)
        
        // Обробка price як рядка або числа
        if let priceString = try? container.decode(String.self, forKey: .price) {
            if let decimalValue = Decimal(string: priceString) {
                price = decimalValue
            } else {
                throw DecodingError.dataCorruptedError(forKey: .price, in: container, debugDescription: "Не вдалося конвертувати рядок в Decimal")
            }
        } else {
            price = try container.decode(Decimal.self, forKey: .price)
        }
        
        // Обробка basePrice як рядка або числа (опціональне поле)
        if container.contains(.basePrice) {
            if let basePriceString = try? container.decode(String.self, forKey: .basePrice) {
                if let decimalValue = Decimal(string: basePriceString) {
                    basePrice = decimalValue
                } else {
                    basePrice = nil
                }
            } else {
                basePrice = try container.decodeIfPresent(Decimal.self, forKey: .basePrice)
            }
        } else {
            basePrice = nil
        }
        
        // Обробка finalPrice як рядка або числа (опціональне поле)
        if container.contains(.finalPrice) {
            if let finalPriceString = try? container.decode(String.self, forKey: .finalPrice) {
                if let decimalValue = Decimal(string: finalPriceString) {
                    finalPrice = decimalValue
                } else {
                    finalPrice = nil
                }
            } else {
                finalPrice = try container.decodeIfPresent(Decimal.self, forKey: .finalPrice)
            }
        } else {
            finalPrice = nil
        }
        
        quantity = try container.decode(Int.self, forKey: .quantity)
        sizeName = try container.decodeIfPresent(String.self, forKey: .sizeName)
        customizationSummary = try container.decodeIfPresent(String.self, forKey: .customizationSummary)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        // Тимчасово ігноруємо customization через проблеми з декодуванням
        customization = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(orderId, forKey: .orderId)
        try container.encode(menuItemId, forKey: .menuItemId)
        try container.encode(name, forKey: .name)
        try container.encode(price, forKey: .price)
        try container.encodeIfPresent(basePrice, forKey: .basePrice)
        try container.encodeIfPresent(finalPrice, forKey: .finalPrice)
        try container.encode(quantity, forKey: .quantity)
        try container.encodeIfPresent(sizeName, forKey: .sizeName)
        try container.encodeIfPresent(customizationSummary, forKey: .customizationSummary)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        
        if let customization = customization,
           let data = try? JSONSerialization.data(withJSONObject: customization),
           let customizationString = String(data: data, encoding: .utf8) {
            try container.encode(customizationString, forKey: .customization)
        }
    }
}
