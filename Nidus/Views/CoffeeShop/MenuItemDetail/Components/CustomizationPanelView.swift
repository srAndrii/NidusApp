import SwiftUI

/// Панель кастомізації товару, яка об'єднує всі компоненти кастомізації
struct CustomizationPanelView: View {
    // MARK: - Властивості
    let menuItem: MenuItem
    @ObservedObject var viewModel: MenuItemDetailViewModel
    
    // MARK: - Конструктор
    init(menuItem: MenuItem, viewModel: MenuItemDetailViewModel) {
        self.menuItem = menuItem
        self.viewModel = viewModel
    }
    
    // MARK: - View
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Заголовок секції
            Text("Кастомізація")
                .font(.headline)
                .foregroundColor(Color("primaryText"))
            
            // Секція кастомізації інгредієнтів
            ingredientsSection
            
            // Секція опцій кастомізації
            optionsSection
            
            // Загальна додаткова вартість кастомізації
            if viewModel.customizationExtraPrice > 0 {
                HStack {
                    Text("Додаткова вартість:")
                        .font(.subheadline)
                        .foregroundColor(Color("primaryText"))
                    
                    Spacer()
                    
                    Text("+\(formatPrice(viewModel.customizationExtraPrice)) ₴")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("primary"))
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Компоненти
    
    /// Секція кастомізації інгредієнтів
    private var ingredientsSection: some View {
        Group {
            if let ingredients = menuItem.ingredients, !ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Інгредієнти")
                        .font(.subheadline)
                        .foregroundColor(Color("secondaryText"))
                    
                    VStack(spacing: 10) {
                        ForEach(ingredients.filter { $0.isCustomizable }, id: \.name) { ingredient in
                            IngredientCustomizationView(
                                ingredient: ingredient,
                                value: Binding(
                                    get: { viewModel.ingredientCustomizations[ingredient.name] ?? ingredient.amount },
                                    set: { newValue in
                                        viewModel.ingredientCustomizations[ingredient.name] = newValue
                                        viewModel.updateCustomization()
                                    }
                                )
                            )
                        }
                    }
                    
                    // Показуємо фіксовані інгредієнти
                    if ingredients.contains(where: { !$0.isCustomizable }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Фіксовані інгредієнти")
                                .font(.caption)
                                .foregroundColor(Color("secondaryText"))
                            
                            ForEach(ingredients.filter { !$0.isCustomizable }, id: \.name) { ingredient in
                                HStack {
                                    Text(ingredient.name)
                                        .font(.caption)
                                        .foregroundColor(Color("secondaryText"))
                                    
                                    Spacer()
                                    
                                    Text("\(String(format: "%.1f", ingredient.amount)) \(ingredient.unit)")
                                        .font(.caption)
                                        .foregroundColor(Color("secondaryText"))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(8)
                        .background(Color("cardColor").opacity(0.3))
                        .cornerRadius(8)
                    }
                }
            } else {
                EmptyView()
            }
        }
    }
    
    /// Секція опцій кастомізації
    private var optionsSection: some View {
        Group {
            if let options = menuItem.customizationOptions, !options.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Опції")
                        .font(.subheadline)
                        .foregroundColor(Color("secondaryText"))
                    
                    VStack(spacing: 10) {
                        ForEach(options) { option in
                            CustomizationOptionView(
                                option: option,
                                selectedChoiceId: Binding(
                                    get: { viewModel.optionSelections[option.id] ?? "" },
                                    set: { newValue in
                                        viewModel.optionSelections[option.id] = newValue
                                        viewModel.updateCustomization()
                                    }
                                )
                            )
                        }
                    }
                }
            } else {
                EmptyView()
            }
        }
    }
    
    // MARK: - Допоміжні методи
    
    /// Форматування ціни
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        
        return formatter.string(from: NSDecimalNumber(decimal: price)) ?? "\(price)"
    }
}

// MARK: - Preview
struct CustomizationPanelView_Previews: PreviewProvider {
    static var previews: some View {
        // Тестові дані для превью
        let customizedItem = MenuItem(
            id: "custom-1",
            name: "Кастомізована кава",
            price: 85.0,
            description: "Кава з можливістю налаштування інгредієнтів та додаткових опцій",
            imageUrl: nil,
            isAvailable: true,
            menuGroupId: "group-1",
            ingredients: [
//                Ingredient(name: "Кава", amount: 7, unit: "г", isCustomizable: true, minAmount: 5, maxAmount: 12),
//                Ingredient(name: "Вода", amount: 150, unit: "мл", isCustomizable: true, minAmount: 100, maxAmount: 200),
//                Ingredient(name: "Цукор", amount: 10, unit: "г", isCustomizable: true, minAmount: 0, maxAmount: 20),
     
            ],
            customizationOptions: [
                CustomizationOption(
                    id: "milk-type",
                    name: "Тип молока",
                    choices: [
                        CustomizationChoice(id: "no-milk", name: "Без молока", price: nil),
                        CustomizationChoice(id: "regular", name: "Звичайне", price: nil),
                        CustomizationChoice(id: "oat", name: "Вівсяне", price: Decimal(15)),
                        CustomizationChoice(id: "almond", name: "Мигдальне", price: Decimal(20))
                    ],
                    required: true
                ),
                CustomizationOption(
                    id: "syrup",
                    name: "Сироп",
                    choices: [
                        CustomizationChoice(id: "no-syrup", name: "Без сиропу", price: nil),
                        CustomizationChoice(id: "vanilla", name: "Ванільний", price: Decimal(10)),
                        CustomizationChoice(id: "caramel", name: "Карамельний", price: Decimal(10))
                    ],
                    required: false
                )
            ],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let viewModel = MenuItemDetailViewModel(menuItem: customizedItem)
        
        return ScrollView {
            CustomizationPanelView(menuItem: customizedItem, viewModel: viewModel)
                .padding()
        }
        .background(Color("backgroundColor"))
        .preferredColorScheme(.dark)
    }
}
