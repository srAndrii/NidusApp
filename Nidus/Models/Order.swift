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
