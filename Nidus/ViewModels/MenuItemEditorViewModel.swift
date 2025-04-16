//
//  MenuItemEditorViewModel.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/11/25.
//


import Combine
import SwiftUI

class MenuItemEditorViewModel: ObservableObject {
    // Базові властивості пункту меню
    @Published var name: String
    @Published var price: String
    @Published var description: String
    @Published var isAvailable: Bool
    @Published var isCustomizable: Bool
    @Published var imageUrl: String?
    @Published var selectedImage: UIImage?
    @Published var customizationTabIndex: Int = 0
    @Published var hasMultipleSizes: Bool
    
    // Вкладені дані для кастомізації
    @Published var ingredients: [Ingredient]
    @Published var customizationOptions: [CustomizationOption]
    @Published var sizes: [Size]
    
    // Стан для UI
    @Published var selectedTab: Int = 0
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    // Ініціалізація з існуючого MenuItem
    init(from menuItem: MenuItem) {
        self.name = menuItem.name
        self.price = "\(menuItem.price)"
        self.description = menuItem.description ?? ""
        self.isAvailable = menuItem.isAvailable
        self.imageUrl = menuItem.imageUrl
        self.isCustomizable = (menuItem.ingredients != nil && !menuItem.ingredients!.isEmpty) ||
                             (menuItem.customizationOptions != nil && !menuItem.customizationOptions!.isEmpty)
        self.ingredients = menuItem.ingredients ?? []
        self.customizationOptions = menuItem.customizationOptions ?? []
        self.hasMultipleSizes = menuItem.hasMultipleSizes ?? false
        self.sizes = menuItem.sizes ?? []
    }
    
    // MARK: - Методи для роботи з інгредієнтами
    
    func addIngredient(_ ingredient: Ingredient) {
        // Тут ми більше не перевіряємо на дублікат, а просто додаємо з унікальним ID
        ingredients.append(ingredient)
        print("🔄 Додано інгредієнт: \(ingredient.id ?? "без ID"), назва: \(ingredient.name), всього: \(ingredients.count)")
    }
    
    func updateIngredient(at index: Int, with ingredient: Ingredient) {
        guard index >= 0 && index < ingredients.count else {
            print("❌ Неможливо оновити інгредієнт: індекс за межами масиву")
            return
        }
        ingredients[index] = ingredient
        print("🔄 Оновлено інгредієнт[\(index)]: \(ingredient.name)")
    }
    
    func removeIngredient(at index: Int) {
        guard index >= 0 && index < ingredients.count else {
            print("❌ Неможливо видалити інгредієнт: індекс за межами масиву")
            return
        }
        let ingredientName = ingredients[index].name
        ingredients.remove(at: index)
        print("🔄 Видалено інгредієнт: \(ingredientName), залишилось: \(ingredients.count)")
    }
    
    // MARK: - Методи для роботи з опціями кастомізації
    
    func addCustomizationOption(name: String, required: Bool) {
        let newOption = CustomizationOption(
            id: UUID().uuidString,
            name: name,
            choices: [],
            required: required
        )
        customizationOptions.append(newOption)
        print("🔄 Додано опцію: \(name), всього: \(customizationOptions.count)")
        logCustomizationOptions()
    }
    
    func updateCustomizationOption(at index: Int, name: String, required: Bool) {
        guard index >= 0 && index < customizationOptions.count else {
            print("❌ Неможливо оновити опцію: індекс за межами масиву")
            return
        }
        
        // Створюємо оновлену опцію
        let updatedOption = CustomizationOption(
            id: customizationOptions[index].id,
            name: name,
            choices: customizationOptions[index].choices,
            required: required
        )
        
        // Оновлюємо масив
        customizationOptions[index] = updatedOption
        print("🔄 Оновлено опцію[\(index)]: \(name)")
        logCustomizationOptions()
    }
    
    func removeCustomizationOption(at index: Int) {
        guard index >= 0 && index < customizationOptions.count else {
            print("❌ Неможливо видалити опцію: індекс за межами масиву")
            return
        }
        let optionName = customizationOptions[index].name
        customizationOptions.remove(at: index)
        print("🔄 Видалено опцію: \(optionName), залишилось: \(customizationOptions.count)")
        logCustomizationOptions()
    }
    
    // MARK: - Методи для роботи з варіантами вибору
    
    func addChoiceToOption(at optionIndex: Int, name: String, price: Decimal?) {
        guard optionIndex >= 0 && optionIndex < customizationOptions.count else {
            print("❌ Неможливо додати вибір: індекс опції за межами масиву")
            return
        }
        
        // Створюємо новий вибір
        let newChoice = CustomizationChoice(
            id: UUID().uuidString,
            name: name,
            price: price
        )
        
        // Створюємо нову опцію з доданим вибором
        var updatedChoices = customizationOptions[optionIndex].choices
        updatedChoices.append(newChoice)
        
        let updatedOption = CustomizationOption(
            id: customizationOptions[optionIndex].id,
            name: customizationOptions[optionIndex].name,
            choices: updatedChoices,
            required: customizationOptions[optionIndex].required
        )
        
        // Оновлюємо масив опцій
        customizationOptions[optionIndex] = updatedOption
        
        print("🔄 Додано вибір '\(name)' до опції '\(customizationOptions[optionIndex].name)'")
        print("🔄 Тепер опція має \(updatedChoices.count) виборів")
        logCustomizationOptions()
    }
    
    func updateChoiceInOption(optionIndex: Int, choiceIndex: Int, name: String, price: Decimal?) {
        guard optionIndex >= 0 && optionIndex < customizationOptions.count else {
            print("❌ Неможливо оновити вибір: індекс опції за межами масиву")
            return
        }
        
        guard choiceIndex >= 0 && choiceIndex < customizationOptions[optionIndex].choices.count else {
            print("❌ Неможливо оновити вибір: індекс вибору за межами масиву")
            return
        }
        
        // Створюємо оновлений вибір
        let updatedChoice = CustomizationChoice(
            id: customizationOptions[optionIndex].choices[choiceIndex].id,
            name: name,
            price: price
        )
        
        // Створюємо оновлений масив виборів
        var updatedChoices = customizationOptions[optionIndex].choices
        updatedChoices[choiceIndex] = updatedChoice
        
        // Створюємо оновлену опцію
        let updatedOption = CustomizationOption(
            id: customizationOptions[optionIndex].id,
            name: customizationOptions[optionIndex].name,
            choices: updatedChoices,
            required: customizationOptions[optionIndex].required
        )
        
        // Оновлюємо масив опцій
        customizationOptions[optionIndex] = updatedOption
        
        print("🔄 Оновлено вибір['\(choiceIndex)'] в опції[\(optionIndex)]")
        logCustomizationOptions()
    }
    
    func removeChoiceFromOption(optionIndex: Int, choiceIndex: Int) {
        guard optionIndex >= 0 && optionIndex < customizationOptions.count else {
            print("❌ Неможливо видалити вибір: індекс опції за межами масиву")
            return
        }
        
        guard choiceIndex >= 0 && choiceIndex < customizationOptions[optionIndex].choices.count else {
            print("❌ Неможливо видалити вибір: індекс вибору за межами масиву")
            return
        }
        
        // Створюємо оновлений масив виборів
        var updatedChoices = customizationOptions[optionIndex].choices
        let choiceName = updatedChoices[choiceIndex].name
        updatedChoices.remove(at: choiceIndex)
        
        // Створюємо оновлену опцію
        let updatedOption = CustomizationOption(
            id: customizationOptions[optionIndex].id,
            name: customizationOptions[optionIndex].name,
            choices: updatedChoices,
            required: customizationOptions[optionIndex].required
        )
        
        // Оновлюємо масив опцій
        customizationOptions[optionIndex] = updatedOption
        
        print("🔄 Видалено вибір '\(choiceName)' з опції[\(optionIndex)]")
        print("🔄 Залишилось \(updatedChoices.count) виборів")
        logCustomizationOptions()
    }
    
    // MARK: - Методи для роботи з розмірами
    
    func addSize(name: String, abbreviation: String, additionalPrice: Decimal, isDefault: Bool) {
        // Перевірка чи є вже розмір за замовчуванням
        if isDefault {
            // Якщо додається новий розмір за замовчуванням, переконайтесь що інші розміри не є за замовчуванням
            for i in 0..<sizes.count {
                if sizes[i].isDefault {
                    let updatedSize = Size(
                        id: sizes[i].id,
                        name: sizes[i].name,
                        abbreviation: sizes[i].abbreviation,
                        additionalPrice: sizes[i].additionalPrice,
                        isDefault: false
                    )
                    sizes[i] = updatedSize
                }
            }
        } else if sizes.isEmpty || !sizes.contains(where: { $0.isDefault }) {
            // Якщо розмірів немає або немає розміру за замовчуванням, встановлюємо поточний як за замовчуванням
            let newSize = Size(
                name: name,
                abbreviation: abbreviation,
                additionalPrice: additionalPrice,
                isDefault: true
            )
            sizes.append(newSize)
            return
        }
        
        // Додавання нового розміру
        let newSize = Size(
            name: name,
            abbreviation: abbreviation,
            additionalPrice: additionalPrice,
            isDefault: isDefault
        )
        sizes.append(newSize)
        print("🔄 Додано розмір: \(name), всього: \(sizes.count)")
    }
    
    func updateSize(at index: Int, name: String, abbreviation: String, additionalPrice: Decimal, isDefault: Bool) {
        guard index >= 0 && index < sizes.count else {
            print("❌ Неможливо оновити розмір: індекс за межами масиву")
            return
        }
        
        // Якщо оновлений розмір стає розміром за замовчуванням, знімаємо цей статус з інших розмірів
        if isDefault {
            for i in 0..<sizes.count {
                if i != index && sizes[i].isDefault {
                    let updatedSize = Size(
                        id: sizes[i].id,
                        name: sizes[i].name,
                        abbreviation: sizes[i].abbreviation,
                        additionalPrice: sizes[i].additionalPrice,
                        isDefault: false
                    )
                    sizes[i] = updatedSize
                }
            }
        }
        
        // Якщо знімаємо статус за замовчуванням з єдиного розміру за замовчуванням, не дозволяємо це
        if !isDefault && sizes[index].isDefault && !sizes.contains(where: { $0.isDefault && $0.id != sizes[index].id }) {
            print("❌ Неможливо видалити єдиний розмір за замовчуванням")
            return
        }
        
        // Оновлення розміру
        let updatedSize = Size(
            id: sizes[index].id,
            name: name,
            abbreviation: abbreviation,
            additionalPrice: additionalPrice,
            isDefault: isDefault
        )
        sizes[index] = updatedSize
        print("🔄 Оновлено розмір[\(index)]: \(name)")
    }
    
    func removeSize(at index: Int) {
        guard index >= 0 && index < sizes.count else {
            print("❌ Неможливо видалити розмір: індекс за межами масиву")
            return
        }
        
        // Перевірка чи це розмір за замовчуванням
        let isDefaultSize = sizes[index].isDefault
        let sizeName = sizes[index].name
        
        // Видалення розміру
        sizes.remove(at: index)
        print("🔄 Видалено розмір: \(sizeName), залишилось: \(sizes.count)")
        
        // Якщо був видалений розмір за замовчуванням і є інші розміри, встановлюємо перший як за замовчуванням
        if isDefaultSize && !sizes.isEmpty && !sizes.contains(where: { $0.isDefault }) {
            let firstSize = sizes[0]
            let updatedSize = Size(
                id: firstSize.id,
                name: firstSize.name,
                abbreviation: firstSize.abbreviation,
                additionalPrice: firstSize.additionalPrice,
                isDefault: true
            )
            sizes[0] = updatedSize
            print("🔄 Встановлено розмір за замовчуванням: \(updatedSize.name)")
        }
    }
    
    // MARK: - Конверсія даних форми в MenuItem
    
    func toMenuItem(groupId: String, itemId: String) -> MenuItem? {
        guard let priceDecimal = Decimal(string: price.replacingOccurrences(of: ",", with: ".")) else {
            print("❌ Неможливо конвертувати ціну: \(price)")
            return nil
        }
        
        print("📊 Конвертація MenuItemEditorViewModel -> MenuItem")
        print("📊 id: \(itemId), name: \(name), price: \(priceDecimal)")
        print("📊 isCustomizable: \(isCustomizable)")
        print("📊 hasMultipleSizes: \(hasMultipleSizes)")
        
        if isCustomizable {
            print("📊 ingredients: \(ingredients.count)")
            print("📊 customizationOptions: \(customizationOptions.count)")
            
            for (i, option) in customizationOptions.enumerated() {
                print("📊 опція[\(i)]: \(option.name), choices: \(option.choices.count)")
            }
        }
        
        if hasMultipleSizes {
            print("📊 sizes: \(sizes.count)")
            for (i, size) in sizes.enumerated() {
                print("📊 розмір[\(i)]: \(size.name), isDefault: \(size.isDefault)")
            }
        }
        
        return MenuItem(
            id: itemId,
            name: name,
            price: priceDecimal,
            description: description.isEmpty ? nil : description,
            imageUrl: imageUrl,
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
    
    // MARK: - Допоміжні методи
    
    private func logCustomizationOptions() {
        print("📋 Стан опцій кастомізації:")
        for (i, option) in customizationOptions.enumerated() {
            print("📋 [\(i)] \(option.name) (required: \(option.required))")
            print("📋   Вибори (\(option.choices.count)):")
            for (j, choice) in option.choices.enumerated() {
                print("📋     [\(j)] \(choice.name) (price: \(choice.price?.description ?? "немає"))")
            }
        }
    }
}
