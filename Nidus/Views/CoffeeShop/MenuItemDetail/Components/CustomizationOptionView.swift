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
    @Binding var selectedChoiceId: String
    @State private var isExpanded = true
    
    
    private var cardGradient: LinearGradient {
        return LinearGradient(
            gradient: Gradient(colors: [Color("cardTop"), Color("cardBottom")]),
            startPoint: .top,
            endPoint: .bottomTrailing
        )
    }

    
    
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
                        
                        if option.required {
                            Text("* Обов'язково")
                                .font(.caption)
                                .foregroundColor(Color("primary"))
                        }
                    }
                    
                    if let selectedChoice = option.choices.first(where: { $0.id == selectedChoiceId }) {
                        Text("Вибрано: \(selectedChoice.name)")
                            .font(.caption)
                            .foregroundColor(Color("secondaryText"))
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
                // Горизонтальне прокручування варіантів
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(option.choices) { choice in
                            ChoiceButton(
                                choice: choice,
                                isSelected: selectedChoiceId == choice.id,
                                onSelect: {
                                    selectedChoiceId = choice.id
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
                .transition(.opacity)
            }
        }
        .padding(12)
//        .background(Color("cardColor").opacity(0.5))
        .background(cardGradient)
        .cornerRadius(8)
    }
}

/// Кнопка для вибору опції кастомізації
struct ChoiceButton: View {
    // MARK: - Властивості
    let choice: CustomizationChoice
    let isSelected: Bool
    let onSelect: () -> Void
    
    /// Форматування ціни опції
    var priceText: String? {
        guard let price = choice.price, price > 0 else { return nil }
        return "+\(price) ₴"
    }
    
    // MARK: - View
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                // Назва варіанта вибору
                Text(choice.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : Color("primaryText"))
                
                // Додаткова ціна (якщо є)
                if let priceText = priceText {
                    Text(priceText)
                        .font(.caption)
                        .fontWeight(.regular)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : Color("primary"))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color("primary") : Color("inputField"))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct CustomizationOptionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Приклад з типами молока
            CustomizationOptionView(
                option: CustomizationOption(
                    id: "milk-type",
                    name: "Тип молока",
                    choices: [
                        CustomizationChoice(id: "regular", name: "Звичайне", price: nil),
                        CustomizationChoice(id: "oat", name: "Вівсяне", price: Decimal(15)),
                        CustomizationChoice(id: "almond", name: "Мигдальне", price: Decimal(20)),
                        CustomizationChoice(id: "coconut", name: "Кокосове", price: Decimal(25))
                    ],
                    required: true
                ),
                selectedChoiceId: .constant("oat")
            )
            
            // Приклад з сиропами
            CustomizationOptionView(
                option: CustomizationOption(
                    id: "syrup",
                    name: "Сироп",
                    choices: [
                        CustomizationChoice(id: "no-syrup", name: "Без сиропу", price: nil),
                        CustomizationChoice(id: "vanilla", name: "Ванільний", price: Decimal(10)),
                        CustomizationChoice(id: "caramel", name: "Карамельний", price: Decimal(10)),
                        CustomizationChoice(id: "hazelnut", name: "Фундучний", price: Decimal(15))
                    ],
                    required: false
                ),
                selectedChoiceId: .constant("vanilla")
            )
        }
        .padding()
        .background(Color("backgroundColor"))
    }
}
