//
//  MenuItemCustomizationEditor.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/5/25.
//


import SwiftUI

struct MenuItemCustomizationEditor: View {
    @Binding var isCustomizable: Bool
    @Binding var ingredients: [Ingredient]
    @Binding var customizationOptions: [CustomizationOption]
    
    @State private var selectedTab: Int = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Загальний перемикач для кастомізації
            Toggle("Дозволити кастомізацію", isOn: $isCustomizable)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color("cardColor"))
                .cornerRadius(8)
                .padding(.horizontal)
            
            // Якщо кастомізація увімкнена, показуємо редактори
            if isCustomizable {
                // Заголовки вкладок
                Picker("", selection: $selectedTab) {
                    Text("Інгредієнти").tag(0)
                    Text("Опції").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Вміст вкладок
                VStack {
                    if selectedTab == 0 {
                        IngredientsEditorView(ingredients: $ingredients)
                    } else {
                        CustomizationOptionsEditorView(customizationOptions: $customizationOptions)
                    }
                }
                .animation(.default, value: selectedTab)
                .transition(.slide)
            } else {
                // Інформаційне повідомлення, якщо кастомізація вимкнена
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 30))
                        .foregroundColor(Color("secondaryText"))
                        .padding(.top, 8)
                    
                    Text("Кастомізація вимкнена")
                        .font(.headline)
                        .foregroundColor(Color("primaryText"))
                    
                    Text("Увімкніть кастомізацію, щоб налаштувати інгредієнти та опції вибору для клієнтів.")
                        .font(.subheadline)
                        .foregroundColor(Color("secondaryText"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity)
                .background(Color("cardColor"))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            // Інформаційний блок
            if isCustomizable {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Рекомендації для кастомізації:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("primaryText"))
                    
                    Text("• Інгредієнти - складові продукту, кількість яких можна змінювати (напр. цукор, кількість еспресо)")
                        .font(.caption)
                        .foregroundColor(Color("secondaryText"))
                    
                    Text("• Опції кастомізації - групи взаємовиключних варіантів, які можна додати (напр. тип молока, вибір сиропу)")
                        .font(.caption)
                        .foregroundColor(Color("secondaryText"))
                    
                    Text("• Для опцій можна встановити додаткову ціну за вибір певного варіанту")
                        .font(.caption)
                        .foregroundColor(Color("secondaryText"))
                }
                .padding()
                .background(Color("cardColor").opacity(0.5))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
}

// Розширення для інтеграції з формами меню
extension MenuItemCustomizationEditor {
    
    // Ініціалізатор для використання в формах
    init(
        menuItem: Binding<MenuItemFormModel>
    ) {
        self._isCustomizable = menuItem.isCustomizable
        self._ingredients = menuItem.ingredients
        self._customizationOptions = menuItem.customizationOptions
    }
}

// Розширена модель форми меню-айтема для підтримки кастомізації
struct MenuItemFormModel {
    var name: String = ""
    var price: String = ""
    var description: String = ""
    var isAvailable: Bool = true
    var isCustomizable: Bool = false
    var ingredients: [Ingredient] = []
    var customizationOptions: [CustomizationOption] = []
    
    // Ініціалізатор з існуючого пункту меню
    init(from menuItem: MenuItem? = nil) {
        if let item = menuItem {
            name = item.name
            price = "\(item.price)"
            description = item.description ?? ""
            isAvailable = item.isAvailable
            
            // Визначаємо, чи є кастомізація
            isCustomizable = item.ingredients?.contains(where: { $0.isCustomizable }) ?? false ||
                             item.customizationOptions?.isEmpty == false
            
            // Копіюємо інгредієнти та опції
            ingredients = item.ingredients ?? []
            customizationOptions = item.customizationOptions ?? []
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
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

struct MenuItemCustomizationEditor_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            MenuItemCustomizationEditor(
                isCustomizable: .constant(true),
                ingredients: .constant([
                    Ingredient(name: "Еспресо", amount: 1, unit: "шт.", isCustomizable: true, minAmount: 1, maxAmount: 3),
                    Ingredient(name: "Молоко", amount: 150, unit: "мл", isCustomizable: false)
                ]),
                customizationOptions: .constant([
                    CustomizationOption(
                        id: "1",
                        name: "Сироп",
                        choices: [
                            CustomizationChoice(id: "1", name: "Ванільний", price: 10),
                            CustomizationChoice(id: "2", name: "Карамельний", price: 10)
                        ],
                        required: false
                    )
                ])
            )
            .padding(.vertical)
            .background(Color("backgroundColor"))
            .preferredColorScheme(.dark)
        }
    }
}
