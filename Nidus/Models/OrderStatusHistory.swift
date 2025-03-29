//
//  OrderStatusHistory.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

// OrderStatusHistory.swift
import Foundation

struct OrderStatusHistory: Identifiable, Codable {
    let id: String
    let orderId: String
    let status: OrderStatus
    var comment: String?
    let changedByUserId: String
    let createdAt: Date
}
