//
//  MenuGroup.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import Foundation

struct MenuGroup: Identifiable, Codable {
    let id: String
    let name: String
    var description: String?
    var displayOrder: Int
    var coffeeShopId: String?  // Змінено на опціональне
    var menuItems: [MenuItem]?
    var createdAt: Date
    var updatedAt: Date
    
    // Кастомний ініціалізатор для додавання coffeeShopId, якщо його немає в JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        displayOrder = try container.decode(Int.self, forKey: .displayOrder)
        coffeeShopId = try container.decodeIfPresent(String.self, forKey: .coffeeShopId)
        menuItems = try container.decodeIfPresent([MenuItem].self, forKey: .menuItems)
        
        // Обробка дат
        let dateFormatter = ISO8601DateFormatter()
        
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt),
           let date = dateFormatter.date(from: createdAtString) {
            createdAt = date
        } else {
            createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        }
        
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt),
           let date = dateFormatter.date(from: updatedAtString) {
            updatedAt = date
        } else {
            updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        }
    }
    
    // Стандартний ініціалізатор для створення об'єктів в коді
    init(id: String, name: String, description: String? = nil, displayOrder: Int,
         coffeeShopId: String? = nil, menuItems: [MenuItem]? = nil,
         createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.displayOrder = displayOrder
        self.coffeeShopId = coffeeShopId
        self.menuItems = menuItems
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
