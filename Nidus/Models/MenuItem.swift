//
//  MenuItem.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import Foundation

struct MenuItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let price: Decimal
    var description: String?
    var imageUrl: String?
    var isAvailable: Bool
    var menuGroupId: String?        // Зроблено опціональним
    var menuGroup: MenuGroup?       // Додано для підтримки JSON формату з API
    var ingredients: [Ingredient]?
    var customizationOptions: [CustomizationOption]?
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, price, description, imageUrl, isAvailable, menuGroupId, menuGroup, ingredients, customizationOptions, createdAt, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        // Покращене декодування price - підтримка як числових, так і рядкових значень
        do {
            // Спочатку спробуємо декодувати як Decimal (числовий формат)
            price = try container.decode(Decimal.self, forKey: .price)
        } catch {
            // Якщо не вдалося, спробуємо декодувати як String і конвертувати в Decimal
            if let priceString = try? container.decode(String.self, forKey: .price),
               let decimalValue = Decimal(string: priceString.replacingOccurrences(of: ",", with: ".")) {
                price = decimalValue
            } else {
                // Якщо конвертація не вдалася, все одно викидаємо початкову помилку
                throw error
            }
        }
        
        description = try container.decodeIfPresent(String.self, forKey: .description)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        // Покращене декодування isAvailable - підтримка як булевих, так і рядкових значень
        do {
            // Спочатку спробуємо декодувати як Bool
            isAvailable = try container.decode(Bool.self, forKey: .isAvailable)
        } catch {
            // Якщо не вдалося, спробуємо декодувати як String і конвертувати в Bool
            if let availableString = try? container.decode(String.self, forKey: .isAvailable) {
                isAvailable = availableString.lowercased() == "true"
            } else {
                // Якщо не вдалося, встановлюємо значення за замовчуванням
                isAvailable = true
            }
        }
        
        // Спочатку спробуємо отримати menuGroupId напряму
        menuGroupId = try container.decodeIfPresent(String.self, forKey: .menuGroupId)
        
        // Також спробуємо отримати menuGroup як об'єкт
        menuGroup = try container.decodeIfPresent(MenuGroup.self, forKey: .menuGroup)
        
        // Якщо menuGroupId не знайдено, але є menuGroup, використовуємо його id
        if menuGroupId == nil, let group = menuGroup {
            menuGroupId = group.id
        }
        
        ingredients = try container.decodeIfPresent([Ingredient].self, forKey: .ingredients)
        customizationOptions = try container.decodeIfPresent([CustomizationOption].self, forKey: .customizationOptions)
        
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
    
    // Стандартний ініціалізатор
    init(id: String, name: String, price: Decimal, description: String? = nil,
         imageUrl: String? = nil, isAvailable: Bool = true, menuGroupId: String? = nil,
         menuGroup: MenuGroup? = nil, ingredients: [Ingredient]? = nil,
         customizationOptions: [CustomizationOption]? = nil, createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.price = price
        self.description = description
        self.imageUrl = imageUrl
        self.isAvailable = isAvailable
        self.menuGroupId = menuGroupId
        self.menuGroup = menuGroup
        self.ingredients = ingredients
        self.customizationOptions = customizationOptions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MenuItem, rhs: MenuItem) -> Bool {
        return lhs.id == rhs.id
    }
}

// Також додаємо Hashable для інших структур, які використовуються в MenuItem

struct Ingredient: Codable, Hashable {
    let name: String
    let amount: Double
    let unit: String
    let isCustomizable: Bool
    let minAmount: Double?
    let maxAmount: Double?
    let freeAmount: Double? // Додано: безкоштовна кількість інгредієнта
    let pricePerUnit: Decimal? // Додано: ціна за одиницю понад безкоштовну кількість
    
    // Потрібно для Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: Ingredient, rhs: Ingredient) -> Bool {
        return lhs.name == rhs.name
    }
}

struct CustomizationOption: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let choices: [CustomizationChoice]
    let required: Bool
    
    // Потрібно для Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CustomizationOption, rhs: CustomizationOption) -> Bool {
        return lhs.id == rhs.id
    }
}

struct CustomizationChoice: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let price: Decimal?
    
    // Потрібно для Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CustomizationChoice, rhs: CustomizationChoice) -> Bool {
        return lhs.id == rhs.id
    }
}
