//
//  OrderStatus.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//
import Foundation

enum OrderStatus: String, Codable {
    case created = "CREATED"
    case accepted = "ACCEPTED"
    case preparing = "PREPARING"
    case ready = "READY"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"
}
