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
    @Published var optionSelections: [String: [String: Int]] = [:]
    
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
                if option.required {
                    optionSelections[option.id] = [:]
                    
                    // Додавання першого вибору для обов'язкових опцій
                    if let firstChoice = option.choices.first {
                        if firstChoice.allowQuantity == true {
                            optionSelections[option.id]?[firstChoice.id] = firstChoice.defaultQuantity ?? 1
                        } else {
                            optionSelections[option.id]?[firstChoice.id] = 1
                        }
                    }
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
                if let selectedChoices = optionSelections[option.id] {
                    for (choiceId, quantity) in selectedChoices {
                        if let selectedChoice = option.choices.first(where: { $0.id == choiceId }),
                           let price = selectedChoice.price {
                            extraPrice += price
                            
                            // Якщо вибір підтримує кількість, додаємо додаткову ціну за одиниці понад стандартну кількість
                            if selectedChoice.allowQuantity == true, 
                               let defaultQuantity = selectedChoice.defaultQuantity,
                               let pricePerAdditionalUnit = selectedChoice.pricePerAdditionalUnit,
                               quantity > defaultQuantity {
                                let additionalUnits = quantity - defaultQuantity
                                extraPrice += Decimal(additionalUnits) * pricePerAdditionalUnit
                            }
                        }
                    }
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
        // Отримуємо поточну кав'ярню
        guard let coffeeShopId = menuItem.menuGroupId?.split(separator: ":").first.map(String.init) else {
            print("Неможливо визначити ID кав'ярні")
            return
        }
        
        // Отримуємо сервіс корзини
        let cartService = CartService.shared
        
        // Перевіряємо на конфлікт кав'ярень
        if !cartService.getCart().canAddItemFromCoffeeShop(coffeeShopId: coffeeShopId) {
            // Тут можна обробити конфлікт (наприклад, показати вікно з попередженням)
            print("Конфлікт кав'ярень при додаванні в корзину")
            
            // ViewModel повинен повідомити View про конфлікт кав'ярень
            // (в реальному коді тут буде прив'язка до UI)
            return
        }
        
        // Створюємо об'єкт для додавання в корзину
        let cartItem = CartItem(
            from: menuItem,
            coffeeShopId: coffeeShopId,
            quantity: quantity,
            selectedSize: selectedSize?.abbreviation,
            customization: createCustomizationData()
        )
        
        // Додаємо товар в корзину через сервіс
        let success = cartService.addItem(cartItem)
        
        if success {
            print("Товар успішно додано до корзини")
        } else {
            print("Помилка додавання товару до корзини")
        }
    }
    
    /// Створення даних кастомізації для корзини
    private func createCustomizationData() -> [String: Any] {
        var customizationData: [String: Any] = [:]
        
        // Додаємо інформацію про розмір
        if let size = selectedSize {
            customizationData["size"] = [
                "id": size.id,
                "name": size.name,
                "abbreviation": size.abbreviation,
                "additionalPrice": size.additionalPrice
            ]
        }
        
        // Додаємо інформацію про кастомізовані інгредієнти
        if !ingredientCustomizations.isEmpty {
            var ingredients: [[String: Any]] = []
            
            for (ingredientId, amount) in ingredientCustomizations {
                // Знаходимо оригінальний інгредієнт для отримання додаткової інформації
                if let ingredient = menuItem.ingredients?.first(where: { $0.id == ingredientId || $0.name == ingredientId }) {
                    ingredients.append([
                        "id": ingredient.id ?? ingredient.name,
                        "name": ingredient.name,
                        "amount": amount
                    ])
                }
            }
            
            if !ingredients.isEmpty {
                customizationData["ingredients"] = ingredients
            }
        }
        
        // Додаємо інформацію про вибрані опції
        if !optionSelections.isEmpty {
            var options: [[String: Any]] = []
            
            for (optionId, selections) in optionSelections {
                // Знаходимо оригінальну опцію для отримання додаткової інформації
                if let option = menuItem.customizationOptions?.first(where: { $0.id == optionId }) {
                    var choices: [[String: Any]] = []
                    
                    for (choiceId, quantity) in selections {
                        // Знаходимо вибір для отримання назви
                        if let choice = option.choices.first(where: { $0.id == choiceId }) {
                            choices.append([
                                "id": choice.id,
                                "name": choice.name,
                                "quantity": quantity,
                                "price": choice.price as Any
                            ])
                        }
                    }
                    
                    options.append([
                        "id": option.id,
                        "name": option.name,
                        "choices": choices
                    ])
                }
            }
            
            if !options.isEmpty {
                customizationData["options"] = options
            }
        }
        
        return customizationData
    }
    
    /// Оновлення налаштувань кастомізації
    func updateCustomization() {
        calculateCustomizationPrice()
    }
    
    /// Перевірка, чи вибраний варіант для опції
    func isChoiceSelected(optionId: String, choiceId: String) -> Bool {
        return optionSelections[optionId]?[choiceId] != nil
    }
    
    /// Отримання кількості для вибраного варіанту
    func getQuantityForChoice(optionId: String, choiceId: String) -> Int {
        return optionSelections[optionId]?[choiceId] ?? 0
    }
    
    /// Додавання опції кастомізації
    func toggleCustomizationChoice(optionId: String, choiceId: String) {
        // Отримуємо опцію за ID
        guard let option = menuItem.customizationOptions?.first(where: { $0.id == optionId }) else {
            return
        }
        
        // Отримуємо вибір за ID
        guard let choice = option.choices.first(where: { $0.id == choiceId }) else {
            return
        }
        
        // Перевіряємо, чи є запис для цієї опції
        if optionSelections[optionId] == nil {
            optionSelections[optionId] = [:]
        }
        
        // Перевіряємо, чи можна вибрати кілька варіантів для цієї опції
        let allowMultiple = option.allowMultipleChoices ?? false
        
        // Отримуємо поточні вибори для цієї опції
        let currentSelections = optionSelections[optionId] ?? [:]
        
        // Якщо вибір вже існує, видаляємо його (окрім випадків, коли опція обов'язкова і це останній вибір)
        if currentSelections[choiceId] != nil {
            // Якщо опція обов'язкова і це єдиний вибір, не видаляємо
            if option.required && currentSelections.count <= 1 {
                return
            }
            
            // Інакше видаляємо вибір
            optionSelections[optionId]?.removeValue(forKey: choiceId)
        } else {
            // Якщо не дозволено вибирати кілька варіантів, очищаємо попередні вибори
            if !allowMultiple {
                optionSelections[optionId] = [:]
            }
            
            // Додаємо новий вибір з відповідною кількістю
            if choice.allowQuantity == true {
                optionSelections[optionId]?[choiceId] = choice.defaultQuantity ?? 1
            } else {
                optionSelections[optionId]?[choiceId] = 1
            }
        }
        
        // Оновлюємо ціну
        calculateCustomizationPrice()
    }
    
    /// Зміна кількості для опції кастомізації
    func updateCustomizationQuantity(optionId: String, choiceId: String, quantity: Int) {
        // Перевіряємо, чи є запис для цієї опції
        if optionSelections[optionId] == nil {
            optionSelections[optionId] = [:]
        }
        
        // Оновлюємо кількість
        optionSelections[optionId]?[choiceId] = quantity
        
        // Оновлюємо ціну
        calculateCustomizationPrice()
    }
}
