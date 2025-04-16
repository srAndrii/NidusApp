//
//  MenuItemFormModel.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/11/25.
//
import Foundation

struct MenuItemFormModel {
    var name: String = ""
    var price: String = ""
    var description: String = ""
    var isAvailable: Bool = true
    var isCustomizable: Bool = false
    var hasMultipleSizes: Bool = false
    var ingredients: [Ingredient] = []
    var customizationOptions: [CustomizationOption] = []
    var sizes: [Size] = []
    
    // Ініціалізатор з існуючого пункту меню
    init(from menuItem: MenuItem? = nil) {
        if let item = menuItem {
            name = item.name
            price = "\(item.price)"
            description = item.description ?? ""
            isAvailable = item.isAvailable
            
            // Перевіряємо наявність інгредієнтів або опцій кастомізації
            isCustomizable = (item.ingredients != nil && !item.ingredients!.isEmpty) ||
                             (item.customizationOptions != nil && !item.customizationOptions!.isEmpty)
            
            // Підтримка розмірів
            hasMultipleSizes = item.hasMultipleSizes ?? false
            
            // Копіюємо інгредієнти, опції та розміри
            ingredients = item.ingredients ?? []
            customizationOptions = item.customizationOptions ?? []
            sizes = item.sizes ?? []
        }
    }
    
    // Конвертація в MenuItem
    func toMenuItem(groupId: String, itemId: String? = nil) -> MenuItem? {
        guard let priceDecimal = Decimal(string: price.replacingOccurrences(of: ",", with: ".")) else {
            return nil
        }
        
        return MenuItem(
            id: itemId ?? UUID().uuidString,
            name: name,
            price: priceDecimal,
            description: description.isEmpty ? nil : description,
            isAvailable: isAvailable,
            menuGroupId: groupId,
            ingredients: isCustomizable ? ingredients : nil,
            customizationOptions: isCustomizable ? customizationOptions : nil,
            hasMultipleSizes: hasMultipleSizes,
            sizes: hasMultipleSizes && !sizes.isEmpty ? sizes : nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
