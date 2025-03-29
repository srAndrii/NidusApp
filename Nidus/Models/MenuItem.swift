//
//  MenuItem.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import Foundation

struct MenuItem: Identifiable, Codable {
    let id: String
    let name: String
    let price: Decimal
    var description: String?
    var imageUrl: String?
    var isAvailable: Bool
    var ingredients: [Ingredient]?
    var customizationOptions: [CustomizationOption]?
    let menuGroupId: String
    var createdAt: Date
    var updatedAt: Date
}

struct Ingredient: Codable {
    let name: String
    let amount: Double
    let unit: String
    let isCustomizable: Bool
    let minAmount: Double?
    let maxAmount: Double?
}

struct CustomizationOption: Identifiable, Codable {
    let id: String
    let name: String
    let choices: [CustomizationChoice]
    let required: Bool
}

struct CustomizationChoice: Identifiable, Codable {
    let id: String
    let name: String
    let price: Decimal?
}
