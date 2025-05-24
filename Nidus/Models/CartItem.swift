//
//  CartItem.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 5/18/25.
//

import Foundation

struct CartItem: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    let menuItemId: String
    let coffeeShopId: String
    var quantity: Int
    var name: String
    var price: Decimal
    var imageUrl: String?
    var customization: [String: Any]?
    
    // Розмір для товарів з розмірами
    var selectedSize: String?
    
    // Обчислювана вартість елемента
    var totalPrice: Decimal {
        var finalPrice = price
        
        print("💰 CartItem.totalPrice: Розрахунок ціни для \(name) (ID: \(menuItemId))")
        print("   - Базова ціна: \(price)")
        
        // Додаємо вартість опцій кастомізації
        if let customization = customization {
            print("   - Дані кастомізації: \(customization)")
            
            // Додаємо ціну розміру, якщо є
            if let sizeData = customization["size"] as? [String: Any],
               let additionalPrice = sizeData["additionalPrice"] as? Decimal {
                finalPrice += additionalPrice
                print("   - Додано ціну за розмір: +\(additionalPrice)")
            }
            
            // Додаємо ціну інгредієнтів
            if let ingredients = customization["ingredients"] as? [[String: Any]] {
                print("   - Знайдено інгредієнти: \(ingredients.count)")
                for ingredient in ingredients {
                    if let amount = ingredient["amount"] as? Double,
                       let id = ingredient["id"] as? String,
                       let name = ingredient["name"] as? String {
                        // Тут треба врахувати ціну за інгредієнти, які перевищують безкоштовну кількість
                        // Використовуємо логіку з MenuItemDetailViewModel
                        if let freeAmount = ingredient["freeAmount"] as? Double,
                           let pricePerUnit = ingredient["pricePerUnit"] as? Decimal,
                           amount > freeAmount {
                            let extraUnits = amount - freeAmount
                            let ingredientExtraPrice = Decimal(Double(extraUnits)) * pricePerUnit
                            finalPrice += ingredientExtraPrice
                            print("     - Інгредієнт \(name): кількість=\(amount), безкоштовно=\(freeAmount), додаткова ціна=+\(ingredientExtraPrice)")
                        } else {
                            print("     - Інгредієнт \(name): кількість=\(amount), ціна не додається")
                        }
                    }
                }
            }
            
            // Додаємо ціну опцій кастомізації
            if let options = customization["options"] as? [[String: Any]] {
                print("   - Знайдено опції: \(options.count)")
                for option in options {
                    if let optionName = option["name"] as? String,
                       let choices = option["choices"] as? [[String: Any]] {
                        print("     - Опція \(optionName): вибрано варіантів \(choices.count)")
                        for choice in choices {
                            if let choiceName = choice["name"] as? String,
                               let choicePrice = choice["price"] as? Decimal,
                               let quantity = choice["quantity"] as? Int {
                                // Врахуємо ціну за додаткові одиниці, якщо вказано
                                if let pricePerAdditionalUnit = choice["pricePerAdditionalUnit"] as? Decimal,
                                   let defaultQuantity = choice["defaultQuantity"] as? Int,
                                   quantity > defaultQuantity {
                                    let additionalUnits = quantity - defaultQuantity
                                    let additionalPrice = choicePrice + (pricePerAdditionalUnit * Decimal(additionalUnits))
                                    finalPrice += additionalPrice
                                    print("       - \(choiceName): базова ціна=\(choicePrice), к-сть=\(quantity), база=\(defaultQuantity), додат.ціна/од=\(pricePerAdditionalUnit), всього=+\(additionalPrice)")
                                } else {
                                    let totalChoicePrice = choicePrice * Decimal(quantity)
                                    finalPrice += totalChoicePrice
                                    print("       - \(choiceName): ціна=\(choicePrice), к-сть=\(quantity), всього=+\(totalChoicePrice)")
                                }
                            }
                        }
                    }
                }
            }
            
            print("   - Фінальна ціна за одиницю: \(finalPrice)")
        } else {
            print("   - Немає кастомізації")
        }
        
        let total = finalPrice * Decimal(quantity)
        print("   - Кількість: \(quantity), загальна вартість: \(total)")
        
        return total
    }
    
    // Ціна за одиницю товару з урахуванням кастомізації
    var unitPrice: Decimal {
        var finalPrice = price
        
        // Додаємо вартість опцій кастомізації
        if let customization = customization {
            // Додаємо ціну розміру, якщо є
            if let sizeData = customization["size"] as? [String: Any],
               let additionalPrice = sizeData["additionalPrice"] as? Decimal {
                finalPrice += additionalPrice
            }
            
            // Додаємо ціну інгредієнтів
            if let ingredients = customization["ingredients"] as? [[String: Any]] {
                for ingredient in ingredients {
                    if let amount = ingredient["amount"] as? Double,
                       let id = ingredient["id"] as? String,
                       let name = ingredient["name"] as? String {
                        // Тут треба врахувати ціну за інгредієнти, які перевищують безкоштовну кількість
                        // Використовуємо логіку з MenuItemDetailViewModel
                        if let freeAmount = ingredient["freeAmount"] as? Double,
                           let pricePerUnit = ingredient["pricePerUnit"] as? Decimal,
                           amount > freeAmount {
                            let extraUnits = amount - freeAmount
                            let ingredientExtraPrice = Decimal(Double(extraUnits)) * pricePerUnit
                            finalPrice += ingredientExtraPrice
                        }
                    }
                }
            }
            
            // Додаємо ціну опцій кастомізації
            if let options = customization["options"] as? [[String: Any]] {
                for option in options {
                    if let choices = option["choices"] as? [[String: Any]] {
                        for choice in choices {
                            if let choicePrice = choice["price"] as? Decimal,
                               let quantity = choice["quantity"] as? Int {
                                // Врахуємо ціну за додаткові одиниці, якщо вказано
                                if let pricePerAdditionalUnit = choice["pricePerAdditionalUnit"] as? Decimal,
                                   let defaultQuantity = choice["defaultQuantity"] as? Int,
                                   quantity > defaultQuantity {
                                    let additionalUnits = quantity - defaultQuantity
                                    finalPrice += choicePrice + (pricePerAdditionalUnit * Decimal(additionalUnits))
                                } else {
                                    finalPrice += choicePrice * Decimal(quantity)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return finalPrice
    }
    
    // Метод для отримання компактного опису кастомізації для UI
    func getCustomizationSummary() -> String? {
        guard let customization = customization else {
            print("📝 CartItem.getCustomizationSummary: Немає даних кастомізації для товару \(name)")
            return nil
        }
        
        print("📝 CartItem.getCustomizationSummary: Отримуємо опис кастомізації для товару \(name)")
        print("   - Розмір: \(selectedSize ?? "не вказано")")
        print("   - Дані кастомізації: \(customization)")
        
        var summaryParts: [String] = []
        
        // Не додаємо розмір (тепер він буде у назві)
        
        // Додаємо інгредієнти
        if let ingredients = customization["ingredients"] as? [[String: Any]] {
            for ingredient in ingredients {
                if let name = ingredient["name"] as? String,
                   let amount = ingredient["amount"] as? Double,
                   amount > 0 {
                    summaryParts.append("\(name): \(Int(amount))")
                }
            }
        }
        
        // Додаємо опції кастомізації
        if let options = customization["options"] as? [[String: Any]] {
            print("   - Кількість опцій: \(options.count)")
            for option in options {
                if let name = option["name"] as? String,
                   let choices = option["choices"] as? [[String: Any]],
                   !choices.isEmpty {
                    var choiceTexts: [String] = []
                    
                    for choice in choices {
                        if let choiceName = choice["name"] as? String {
                            // Додаємо кількість, якщо вона більше 1
                            if let quantity = choice["quantity"] as? Int, quantity > 1 {
                                choiceTexts.append("\(choiceName) (\(quantity))")
                            } else {
                                choiceTexts.append(choiceName)
                            }
                        }
                    }
                    
                    let choiceText = choiceTexts.joined(separator: ", ")
                    summaryParts.append("\(name): \(choiceText)")
                }
            }
        }
        
        print("   - Сформований опис: \(summaryParts.joined(separator: "; "))")
        return summaryParts.isEmpty ? nil : summaryParts.joined(separator: "; ")
    }
    
    // Порівняння кастомізації з іншим CartItem
    func hasSameCustomization(as other: CartItem) -> Bool {
        // Якщо обидва не мають кастомізації - вони однакові
        if self.customization == nil && other.customization == nil {
            print("📝 CartItem.hasSameCustomization: Обидва товари без кастомізації")
            return true
        }
        
        // Якщо тільки один має кастомізацію - вони різні
        if self.customization == nil || other.customization == nil {
            print("📝 CartItem.hasSameCustomization: Тільки один товар має кастомізацію")
            return false
        }
        
        // Порівнюємо дані JSON як рядки для повного порівняння
        if let selfData = try? JSONSerialization.data(withJSONObject: self.customization!),
           let otherData = try? JSONSerialization.data(withJSONObject: other.customization!),
           let selfStr = String(data: selfData, encoding: .utf8),
           let otherStr = String(data: otherData, encoding: .utf8) {
            let areEqual = selfStr == otherStr
            print("📝 CartItem.hasSameCustomization: Порівняння даних кастомізації:")
            if !areEqual {
                print("   - Товари відрізняються кастомізацією:")
                print("   - Існуючий: \(selfStr)")
                print("   - Новий: \(otherStr)")
            } else {
                print("   - Товари мають однакову кастомізацію")
            }
            return areEqual
        }
        
        print("📝 CartItem.hasSameCustomization: Не вдалося порівняти дані кастомізації")
        return false
    }
    
    // Спеціальні методи для кодування/декодування через JSON
    enum CodingKeys: String, CodingKey {
        case id, menuItemId, coffeeShopId, quantity, name, price, imageUrl, customization, selectedSize
    }
    
    // Ініціалізатор для створення з MenuItem
    init(from menuItem: MenuItem, coffeeShopId: String, quantity: Int = 1, selectedSize: String? = nil, customization: [String: Any]? = nil) {
        self.menuItemId = menuItem.id
        self.coffeeShopId = coffeeShopId
        self.quantity = quantity
        self.name = menuItem.name
        self.price = menuItem.price
        self.imageUrl = menuItem.imageUrl
        self.selectedSize = selectedSize
        self.customization = customization
    }
    
    // Декодер для JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        menuItemId = try container.decode(String.self, forKey: .menuItemId)
        coffeeShopId = try container.decode(String.self, forKey: .coffeeShopId)
        quantity = try container.decode(Int.self, forKey: .quantity)
        name = try container.decode(String.self, forKey: .name)
        price = try container.decode(Decimal.self, forKey: .price)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        selectedSize = try container.decodeIfPresent(String.self, forKey: .selectedSize)
        
        if let customizationString = try container.decodeIfPresent(String.self, forKey: .customization),
           let data = customizationString.data(using: .utf8),
           let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            // Перетворюємо числові значення до правильних типів
            var normalizedCustomization = json
            
            // Нормалізуємо size.additionalPrice до Decimal
            if var sizeData = json["size"] as? [String: Any],
               let additionalPrice = sizeData["additionalPrice"] {
                sizeData["additionalPrice"] = Decimal(Double("\(additionalPrice)") ?? 0)
                normalizedCustomization["size"] = sizeData
            }
            
            // Нормалізуємо інгредієнти
            if let ingredients = json["ingredients"] as? [[String: Any]] {
                var normalizedIngredients: [[String: Any]] = []
                
                for var ingredient in ingredients {
                    // Нормалізуємо pricePerUnit до Decimal
                    if let pricePerUnit = ingredient["pricePerUnit"] {
                        ingredient["pricePerUnit"] = Decimal(Double("\(pricePerUnit)") ?? 0)
                    }
                    
                    // Нормалізуємо freeAmount до Double
                    if let freeAmount = ingredient["freeAmount"] {
                        ingredient["freeAmount"] = Double("\(freeAmount)") ?? 0
                    }
                    
                    // Нормалізуємо amount до Double
                    if let amount = ingredient["amount"] {
                        ingredient["amount"] = Double("\(amount)") ?? 0
                    }
                    
                    normalizedIngredients.append(ingredient)
                }
                normalizedCustomization["ingredients"] = normalizedIngredients
            }
            
            // Нормалізуємо опції кастомізації
            if let options = json["options"] as? [[String: Any]] {
                var normalizedOptions: [[String: Any]] = []
                
                for option in options {
                    var normalizedOption = option
                    
                    if let choices = option["choices"] as? [[String: Any]] {
                        var normalizedChoices: [[String: Any]] = []
                        
                        for var choice in choices {
                            // Нормалізуємо price до Decimal
                            if let price = choice["price"] {
                                choice["price"] = Decimal(Double("\(price)") ?? 0)
                            }
                            
                            // Нормалізуємо pricePerAdditionalUnit до Decimal
                            if let pricePerAdditionalUnit = choice["pricePerAdditionalUnit"] {
                                choice["pricePerAdditionalUnit"] = Decimal(Double("\(pricePerAdditionalUnit)") ?? 0)
                            }
                            
                            // Нормалізуємо quantity до Int
                            if let quantity = choice["quantity"] {
                                choice["quantity"] = Int("\(quantity)") ?? 1
                            }
                            
                            // Нормалізуємо defaultQuantity до Int
                            if let defaultQuantity = choice["defaultQuantity"] {
                                choice["defaultQuantity"] = Int("\(defaultQuantity)") ?? 1
                            }
                            
                            normalizedChoices.append(choice)
                        }
                        
                        normalizedOption["choices"] = normalizedChoices
                    }
                    
                    normalizedOptions.append(normalizedOption)
                }
                normalizedCustomization["options"] = normalizedOptions
            }
            
            customization = normalizedCustomization
        }
    }
    
    // Кодер для JSON
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(menuItemId, forKey: .menuItemId)
        try container.encode(coffeeShopId, forKey: .coffeeShopId)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(name, forKey: .name)
        try container.encode(price, forKey: .price)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(selectedSize, forKey: .selectedSize)
        
        if let customization = customization,
           let data = try? JSONSerialization.data(withJSONObject: customization),
           let customizationString = String(data: data, encoding: .utf8) {
            try container.encode(customizationString, forKey: .customization)
        }
    }
    
    // Для Equatable
    static func == (lhs: CartItem, rhs: CartItem) -> Bool {
        return lhs.id == rhs.id
    }
}
