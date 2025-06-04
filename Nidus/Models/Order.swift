//
//  Order.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import Foundation

struct Order: Identifiable, Codable {
    let id: String
    let userId: String
    let coffeeShopId: String
    var status: OrderStatus
    let totalAmount: Decimal
    var items: [OrderItem]?
    var statusHistory: [OrderStatusHistory]?
    var comment: String?
    var isPaid: Bool
    var scheduledFor: Date?
    let createdAt: Date
    var updatedAt: Date
    
    // MARK: - Custom Decoding
    enum CodingKeys: String, CodingKey {
        case id, userId, coffeeShopId, status, totalAmount, items, statusHistory, comment, isPaid, scheduledFor, createdAt, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        coffeeShopId = try container.decode(String.self, forKey: .coffeeShopId)
        status = try container.decode(OrderStatus.self, forKey: .status)
        items = try container.decodeIfPresent([OrderItem].self, forKey: .items)
        statusHistory = try container.decodeIfPresent([OrderStatusHistory].self, forKey: .statusHistory)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        isPaid = try container.decode(Bool.self, forKey: .isPaid)
        scheduledFor = try container.decodeIfPresent(Date.self, forKey: .scheduledFor)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        // Обробка totalAmount як рядка або числа
        if let totalAmountString = try? container.decode(String.self, forKey: .totalAmount) {
            if let decimalValue = Decimal(string: totalAmountString) {
                totalAmount = decimalValue
            } else {
                throw DecodingError.dataCorruptedError(forKey: .totalAmount, in: container, debugDescription: "Не вдалося конвертувати рядок в Decimal")
            }
        } else {
            totalAmount = try container.decode(Decimal.self, forKey: .totalAmount)
        }
    }
    
    // Обчислювані властивості для відображення у додатку
    var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "UAH"
        return formatter.string(from: NSDecimalNumber(decimal: totalAmount)) ?? "\(totalAmount)"
    }
    
    var formattedStatus: String {
        switch status {
        case .created:
            return "Створено"
        case .pending:
            return "В обробці"
        case .accepted:
            return "Прийнято"
        case .preparing:
            return "Готується"
        case .ready:
            return "Готово"
        case .completed:
            return "Завершено"
        case .cancelled:
            return "Скасовано"
        }
    }
}
