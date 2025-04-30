//
//  MenuItemDetailViewModel.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/8/25.
//

import Foundation
import Combine

/// ViewModel для екрану деталей пункту меню
class MenuItemDetailViewModel: ObservableObject {
    // MARK: - Опубліковані властивості
    
    /// Поточний пункт меню
    @Published var menuItem: MenuItem
    
    /// Поточна ціна з урахуванням вибраного розміру та кастомізацій
    @Published var currentPrice: Decimal
    
    /// Кастомізації інгредієнтів (назва: значення)
    @Published var ingredientCustomizations: [String: Double] = [:]
    
    /// Вибрані опції кастомізації (id опції: id вибору)
    @Published var optionSelections: [String: String] = [:]
    
    /// Додаткова ціна за кастомізацію
    @Published var customizationExtraPrice: Decimal = 0
    
    /// Поточний вибраний розмір
    @Published var selectedSize: Size?
    
    // MARK: - Обчислювані властивості
    
    /// Перевіряє, чи має товар опції для кастомізації
    var hasCustomizationOptions: Bool {
        return (menuItem.ingredients != nil && !menuItem.ingredients!.isEmpty) ||
               (menuItem.customizationOptions != nil && !menuItem.customizationOptions!.isEmpty)
    }
    
    /// Чи має товар кілька розмірів
    var hasMultipleSizes: Bool {
        return menuItem.hasMultipleSizes == true && menuItem.sizes != nil && !menuItem.sizes!.isEmpty
    }
    
    /// Список доступних розмірів, відсортованих за порядком
    var availableSizes: [Size] {
        return (menuItem.sizes ?? []).sorted(by: { $0.isDefault ? false : !$1.isDefault })
    }
    
    // MARK: - Ініціалізатор
    init(menuItem: MenuItem) {
        self.menuItem = menuItem
        self.currentPrice = menuItem.price
        
        // Ініціалізація розміру за замовчуванням
        if let defaultSize = menuItem.sizes?.first(where: { $0.isDefault }) {
            self.selectedSize = defaultSize
            self.currentPrice = menuItem.price + defaultSize.additionalPrice
        }
        
        // Ініціалізація значень кастомізації інгредієнтів за замовчуванням
        if let ingredients = menuItem.ingredients {
            for ingredient in ingredients {
                if ingredient.isCustomizable {
                    ingredientCustomizations[ingredient.id ?? ingredient.name] = ingredient.amount
                }
            }
        }
        
        // Ініціалізація вибору опцій кастомізації за замовчуванням
        if let options = menuItem.customizationOptions {
            for option in options {
                if option.required, let firstChoice = option.choices.first {
                    optionSelections[option.id] = firstChoice.id
                }
            }
        }
        
        // Обчислення ціни з урахуванням кастомізацій
        calculateCustomizationPrice()
    }
    
    // MARK: - Методи
    
    /// Оновлення ціни на основі вибраного розміру
    func updatePrice(for sizeAbbreviation: String) {
        // Пошук вибраного розміру у нашому масиві
        if let newSize = menuItem.sizes?.first(where: { $0.abbreviation == sizeAbbreviation }) {
            selectedSize = newSize
            // Оновлюємо ціну з урахуванням розміру
            currentPrice = menuItem.price + newSize.additionalPrice + customizationExtraPrice
        } else {
            // Стара логіка для зворотної сумісності
        let sizeMultiplier: Decimal
            switch sizeAbbreviation {
        case "S":
            sizeMultiplier = 0.8
        case "L":
            sizeMultiplier = 1.2
        default: // "M"
            sizeMultiplier = 1.0
        }
        
        let basePrice = menuItem.price
        currentPrice = (basePrice * sizeMultiplier) + customizationExtraPrice
        }
    }
    
    /// Обчислення додаткової ціни за кастомізацію
    func calculateCustomizationPrice() {
        var extraPrice: Decimal = 0
        
        // Перевіряємо вибрані опції на додаткову ціну
        if let options = menuItem.customizationOptions {
            for option in options {
                if let selectedChoiceId = optionSelections[option.id],
                   let selectedChoice = option.choices.first(where: { $0.id == selectedChoiceId }),
                   let price = selectedChoice.price {
                    extraPrice += price
                }
            }
        }
        
        // Додаємо ціну за додаткові інгредієнти понад безкоштовну кількість
        if let ingredients = menuItem.ingredients {
            for ingredient in ingredients {
                if ingredient.isCustomizable {
                    let currentAmount = ingredientCustomizations[ingredient.id ?? ingredient.name] ?? ingredient.amount
                    let freeAmount = ingredient.freeAmount ?? 0
                    let pricePerUnit = ingredient.pricePerUnit ?? 0
                    
                    // Якщо поточна кількість перевищує безкоштовну
                    if currentAmount > freeAmount {
                        // Обчислюємо додаткову ціну за кожну одиницю понад безкоштовну кількість
                        let extraUnits = currentAmount - freeAmount
                        let ingredientExtraPrice = Decimal(Double(extraUnits)) * pricePerUnit
                        extraPrice += ingredientExtraPrice
                    }
                }
            }
        }
        
        customizationExtraPrice = extraPrice
        
        // Оновлюємо ціну з урахуванням розміру і кастомізації
        if let size = selectedSize {
            currentPrice = menuItem.price + size.additionalPrice + extraPrice
        } else {
        currentPrice = menuItem.price + extraPrice
        }
    }
    
    /// Додавання товару до кошика
    func addToCart(quantity: Int) {
        // В майбутньому тут буде реальна логіка додавання до кошика
        print("Додано до кошика: \(menuItem.name), кількість: \(quantity)")
        print("Поточна ціна: \(currentPrice)")
        
        // Логування розміру
        if let size = selectedSize {
            print("Розмір: \(size.name) (\(size.abbreviation)), додаткова ціна: \(size.additionalPrice)")
        }
        
        // Логування кастомізацій інгредієнтів
        for (name, value) in ingredientCustomizations {
            print("Інгредієнт \(name): \(value)")
        }
        
        // Логування вибраних опцій
        for (optionId, choiceId) in optionSelections {
            if let option = menuItem.customizationOptions?.first(where: { $0.id == optionId }),
               let choice = option.choices.first(where: { $0.id == choiceId }) {
                print("Опція \(option.name): \(choice.name)")
            }
        }
        
        // Тут буде виклик API для створення замовлення
    }
    
    /// Оновлення налаштувань кастомізації
    func updateCustomization() {
        calculateCustomizationPrice()
    }
}
