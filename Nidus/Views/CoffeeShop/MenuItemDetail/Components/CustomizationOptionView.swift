//
//  CustomizationOptionView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/8/25.
//

import SwiftUI

/// Компонент для відображення групи опцій кастомізації
struct CustomizationOptionView: View {
    // MARK: - Властивості
    let option: CustomizationOption
    @ObservedObject var viewModel: MenuItemDetailViewModel
    @State private var isExpanded = true
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - View
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Заголовок опції з можливістю згортання/розгортання
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(option.name)
                            .font(.headline)
                            .foregroundColor(Color("primaryText"))
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        if option.required {
                            Text("* Обов'язково")
                                .font(.caption)
                                .foregroundColor(Color("primary"))
                        }
                        
                        if option.allowMultipleChoices == true {
                            Text("(Можна вибрати кілька)")
                                .font(.caption)
                                .foregroundColor(Color("secondaryText"))
                        }
                    }
                    
                    // Показуємо вибрані варіанти
                    if let selections = viewModel.optionSelections[option.id], !selections.isEmpty {
                        HStack {
                            Text("Вибрано: ")
                                .font(.caption)
                                .foregroundColor(Color("secondaryText"))
                            
                            // Показуємо макс. 2 вибрані опції
                            let selectedChoices = selections.keys.prefix(2)
                            ForEach(Array(selectedChoices.enumerated()), id: \.element) { index, choiceId in
                                if let choice = option.choices.first(where: { $0.id == choiceId }) {
                                    if index > 0 {
                                        Text(", ")
                                            .font(.caption)
                                            .foregroundColor(Color("secondaryText"))
                                    }
                                    
                                    Text(choice.name)
                                        .font(.caption)
                                        .foregroundColor(Color("primary"))
                                        .lineLimit(1)
                                    
                                    if let quantity = selections[choiceId], quantity > 1 {
                                        Text("×\(quantity)")
                                            .font(.caption)
                                            .foregroundColor(Color("secondaryText"))
                                    }
                                }
                            }
                            
                            // Якщо є більше варіантів, показуємо +N
                            if selections.count > 2 {
                                Text(" +\(selections.count - 2)")
                                    .font(.caption)
                                    .foregroundColor(Color("secondaryText"))
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Color("secondaryText"))
                }
            }
            
            // Варіанти вибору (згортаються/розгортаються)
            if isExpanded {
                // Сітка варіантів вибору з можливістю скролінгу
                VStack(spacing: 12) {
                    ForEach(option.choices) { choice in
                        ChoiceCardView(
                            choice: choice,
                            isSelected: viewModel.isChoiceSelected(optionId: option.id, choiceId: choice.id),
                            quantity: viewModel.getQuantityForChoice(optionId: option.id, choiceId: choice.id),
                            onSelect: {
                                viewModel.toggleCustomizationChoice(optionId: option.id, choiceId: choice.id)
                            },
                            onQuantityChanged: { newQuantity in
                                viewModel.updateCustomizationQuantity(optionId: option.id, choiceId: choice.id, quantity: newQuantity)
                            }
                        )
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(16)
        .background(
            ZStack {
                // Скляний фон
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.clear)
                    .overlay(
                        BlurView(
                            style: colorScheme == .light ? .systemThinMaterial : .systemMaterialDark,
                            opacity: colorScheme == .light ? 0.95 : 0.95
                        )
                    )
                    .overlay(
                        Group {
                            if colorScheme == .light {
                                // Тонування для світлої теми
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color("nidusMistyBlue").opacity(0.25),
                                        Color("nidusCoolGray").opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .opacity(0.4)
                                
                                Color("nidusLightBlueGray").opacity(0.12)
                            } else {
                                // Темна тема
                                Color.black.opacity(0.15)
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            colorScheme == .light 
                                ? Color("nidusCoolGray").opacity(0.4)
                                : Color.black.opacity(0.35),
                            colorScheme == .light
                                ? Color("nidusLightBlueGray").opacity(0.25)
                                : Color.black.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
    }
}

/// Картка для вибору опції кастомізації
struct ChoiceCardView: View {
    // MARK: - Властивості
    let choice: CustomizationChoice
    let isSelected: Bool
    let quantity: Int
    let onSelect: () -> Void
    let onQuantityChanged: (Int) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    /// Перевірка, чи можна зменшити кількість
    private var canDecrease: Bool {
        guard choice.allowQuantity == true else { return false }
        let minQuantity = choice.minQuantity ?? 1
        return quantity > minQuantity
    }
    
    /// Перевірка, чи можна збільшити кількість
    private var canIncrease: Bool {
        guard choice.allowQuantity == true else { return false }
        let maxQuantity = choice.maxQuantity ?? Int.max
        return quantity < maxQuantity
    }
    
    /// Форматування ціни опції
    private var priceText: String? {
        guard let price = choice.price, price > 0 else { return nil }
        return "+\(formatPrice(price)) ₴"
    }
    
    /// Форматування ціни
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        
        return formatter.string(from: NSDecimalNumber(decimal: price)) ?? "\(price)"
    }
    
    // MARK: - View
    var body: some View {
        HStack(spacing: 12) {
            // Кнопка вибору
            Button(action: onSelect) {
                ZStack {
                    // Фон кнопки
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.clear)
                        .overlay(
                            BlurView(
                                style: colorScheme == .light ? .systemThinMaterial : .systemMaterialDark,
                                opacity: colorScheme == .light ? 0.95 : 0.95
                            )
                        )
                        .overlay(
                            Group {
                                if isSelected {
                                    // Фон для вибраного стану
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color("primary").opacity(0.8),
                                            Color("primary")
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                } else if colorScheme == .light {
                                    // Фон для невибраного стану (світла тема)
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color("nidusMistyBlue").opacity(0.25),
                                            Color("nidusCoolGray").opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .opacity(0.4)
                                    
                                    Color("nidusLightBlueGray").opacity(0.12)
                                } else {
                                    // Фон для невибраного стану (темна тема)
                                    Color.black.opacity(0.15)
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Інформація про опцію
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            // Назва опції
                            Text(choice.name)
                                .font(.subheadline)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .foregroundColor(isSelected ? .white : Color("primaryText"))
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            Spacer()
                            
                            // Іконка вибору
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                            }
                        }
                        
                        // Додаткова ціна (якщо є)
                        if let priceText = priceText {
                            Text(priceText)
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(isSelected ? .white.opacity(0.9) : Color("primary"))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .frame(maxWidth: .infinity)
            
            // Селектор кількості (якщо allowQuantity = true)
            if choice.allowQuantity == true && isSelected {
                HStack(spacing: 12) {
                    // Кнопка зменшення
                    Button(action: {
                        if canDecrease {
                            onQuantityChanged(quantity - 1)
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    .disabled(!canDecrease)
                    .opacity(canDecrease ? 1.0 : 0.5)
                    
                    // Поточна кількість
                    Text("\(quantity)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(minWidth: 24)
                        .multilineTextAlignment(.center)
                    
                    // Кнопка збільшення
                    Button(action: {
                        if canIncrease {
                            onQuantityChanged(quantity + 1)
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    .disabled(!canIncrease)
                    .opacity(canIncrease ? 1.0 : 0.5)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("primary"))
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
struct CustomizationOptionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Приклад з простими опціями
            let simpleOption = CustomizationOption(
                id: "milk-type",
                name: "Тип молока",
                choices: [
                    CustomizationChoice(id: "regular", name: "Звичайне", price: nil),
                    CustomizationChoice(id: "oat", name: "Вівсяне", price: Decimal(15)),
                    CustomizationChoice(id: "almond", name: "Мигдальне", price: Decimal(20))
                ],
                required: true,
                allowMultipleChoices: false
            )
            
            // Приклад з опціями, що підтримують кількість
            let quantityOption = CustomizationOption(
                id: "toppings",
                name: "Топінги",
                choices: [
                    CustomizationChoice(
                        id: "chocolate", 
                        name: "Шоколад", 
                        price: Decimal(10), 
                        allowQuantity: true,
                        defaultQuantity: 1,
                        minQuantity: 1,
                        maxQuantity: 3,
                        pricePerAdditionalUnit: Decimal(5)
                    ),
                    CustomizationChoice(
                        id: "caramel", 
                        name: "Карамельний", 
                        price: Decimal(10),
                        allowQuantity: true,
                        defaultQuantity: 1,
                        minQuantity: 1,
                        maxQuantity: 3,
                        pricePerAdditionalUnit: Decimal(5)
                    )
                ],
                required: false,
                allowMultipleChoices: true
            )
            
            // Створимо ViewModel для превью
            let menuItem = MenuItem(
                id: "coffee-1",
                name: "Капучино",
                price: Decimal(70),
                customizationOptions: [simpleOption, quantityOption],
                createdAt: Date(),
                updatedAt: Date()
            )
            
            let viewModel = MenuItemDetailViewModel(menuItem: menuItem)
            
            // Відображення компонентів
            CustomizationOptionView(option: simpleOption, viewModel: viewModel)
            CustomizationOptionView(option: quantityOption, viewModel: viewModel)
        }
        .padding()
        .background(Color("backgroundColor"))
        .onAppear {
            // Налаштовуємо стан вибраних опцій для превью
            let viewModel = MenuItemDetailViewModel(menuItem: MenuItem(
                id: "coffee-1",
                name: "Капучино",
                price: Decimal(70),
                customizationOptions: [
                    CustomizationOption(
                        id: "milk-type",
                        name: "Тип молока",
                        choices: [],
                        required: true
                    ),
                    CustomizationOption(
                        id: "syrup",
                        name: "Сироп",
                        choices: [],
                        required: false
                    )
                ],
                createdAt: Date(),
                updatedAt: Date()
            ))
            
            viewModel.toggleCustomizationChoice(optionId: "milk-type", choiceId: "oat")
            viewModel.toggleCustomizationChoice(optionId: "syrup", choiceId: "vanilla")
            viewModel.updateCustomizationQuantity(optionId: "syrup", choiceId: "vanilla", quantity: 2)
        }
    }
}
