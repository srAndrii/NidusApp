//
//  OrderStatus.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//
// OrderStatus.swift
import Foundation

enum OrderStatus: String, Codable {
    case created = "created"
    case pending = "pending"
    case accepted = "accepted"
    case preparing = "preparing"
    case ready = "ready"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var localizedName: String {
        switch self {
        case .created:
            return "Створено"
        case .pending:
            return "В обробці"
        case .accepted:
            return "Прийнято"
        case .preparing:
            return "Готується"
        case .ready:
            return "Готове до видачі"
        case .completed:
            return "Виконано"
        case .cancelled:
            return "Скасовано"
        }
    }
}
