//
//  IngredientCustomizationView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/8/25.
//

import SwiftUI

/// Компонент для кастомізації окремого інгредієнту
struct IngredientCustomizationView: View {
    // MARK: - Властивості
    let ingredient: Ingredient
    @Binding var value: Double
    
    /// Форматування значення для відображення
    private var formattedValue: String {
        return String(format: "%.1f", value)
    }
    
    /// Відсоток заповнення слайдера (для візуалізації)
    private var sliderFillPercentage: Double {
        let minValue = ingredient.minAmount ?? 0
        let maxValue = ingredient.maxAmount ?? (ingredient.amount * 2)
        let range = maxValue - minValue
        
        if range > 0 {
            return Swift.min(1.0, (value - minValue) / range)
        } else {
            return 0.5
        }
    }
    
    private var cardGradient: LinearGradient {
        return LinearGradient(
            gradient: Gradient(colors: [Color("cardTop"), Color("cardBottom")]),
            startPoint: .bottomTrailing,
            endPoint:.top
        )
    }
    
    // MARK: - View
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Заголовок з назвою інгредієнта і поточним значенням
            HStack {
                Text(ingredient.name)
                    .font(.subheadline)
                    .foregroundColor(Color("primaryText"))
                
                Spacer()
                
                Text("\(formattedValue) \(ingredient.unit)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("primary"))
            }
            
            // Слайдер з візуальним заповненням - новий підхід з GeometryReader
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Фон слайдера - тепер має фіксовану ширину
                    Rectangle()
                        .fill(Color("inputField"))
                        .frame(width: geometry.size.width, height: 8)
                        .cornerRadius(4)
                    
                    // Заповнена частина слайдера - обмежена шириною контейнера
                    Rectangle()
                        .fill(Color("primary"))
                        .frame(width: sliderFillPercentage * geometry.size.width, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8) // Фіксована висота для GeometryReader
            
            // Контроль для налаштування значення
            HStack {
                // Кнопка зменшення
                Button(action: {
                    decreaseValue()
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundColor(canDecrease() ? Color("primary") : Color("secondaryText").opacity(0.5))
                }
                .disabled(!canDecrease())
                
                Spacer()
                
                // Інформація про допустимі межі
                if let minAmount = ingredient.minAmount, let maxAmount = ingredient.maxAmount {
                    Text("\(String(format: "%.1f", minAmount)) - \(String(format: "%.1f", maxAmount)) \(ingredient.unit)")
                        .font(.caption)
                        .foregroundColor(Color("secondaryText"))
                }
                
                Spacer()
                
                // Кнопка збільшення
                Button(action: {
                    increaseValue()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(canIncrease() ? Color("primary") : Color("secondaryText").opacity(0.5))
                }
                .disabled(!canIncrease())
            }
            .padding(.top, 4)
        }
        .padding(12)
//        .background(Color("cardColor").opacity(0.5))
        .background(cardGradient)
        .cornerRadius(8)
        .frame(maxWidth: UIScreen.main.bounds.width - 32) // Фіксована максимальна ширина
    }
    
    // MARK: - Методи - залишаються без змін
    
    /// Перевірка можливості зменшення значення
    private func canDecrease() -> Bool {
        return value > (ingredient.minAmount ?? 0)
    }
    
    /// Перевірка можливості збільшення значення
    private func canIncrease() -> Bool {
        return value < (ingredient.maxAmount ?? (ingredient.amount * 2))
    }
    
    /// Зменшення значення з кроком
    private func decreaseValue() {
        if canDecrease() {
            let step = calculateStep()
            value = max(ingredient.minAmount ?? 0, value - step)
        }
    }
    
    /// Збільшення значення з кроком
    private func increaseValue() {
        if canIncrease() {
            let step = calculateStep()
            value = min(ingredient.maxAmount ?? (ingredient.amount * 2), value + step)
        }
    }
    
    /// Розрахунок кроку для зміни значення
    private func calculateStep() -> Double {
        // Визначення розумного кроку залежно від одиниці виміру та діапазону
        if ingredient.unit == "шт." {
            return 1 // Для штук крок завжди 1
        } else {
            // Для інших одиниць виміру визначаємо крок залежно від діапазону
            let minValue = ingredient.minAmount ?? 0
            let maxValue = ingredient.maxAmount ?? (ingredient.amount * 2)
            let range = maxValue - minValue
            
            if range <= 10 {
                return 0.5 // Малий діапазон - менший крок
            } else if range <= 100 {
                return 5 // Середній діапазон
            } else {
                return 10 // Великий діапазон - більший крок
            }
        }
    }
}

// MARK: - Preview
struct IngredientCustomizationView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Приклад зі штуками
            IngredientCustomizationView(
                ingredient: Ingredient(
                    name: "Еспресо шоти",
                    amount: 1,
                    unit: "шт.",
                    isCustomizable: true,
                    minAmount: 1,
                    maxAmount: 3
                ),
                value: .constant(1)
            )
            
            // Приклад з грамами
            IngredientCustomizationView(
                ingredient: Ingredient(
                    name: "Цукор",
                    amount: 10,
                    unit: "г",
                    isCustomizable: true,
                    minAmount: 0,
                    maxAmount: 20
                ),
                value: .constant(10)
            )
            
            // Приклад з мілілітрами
            IngredientCustomizationView(
                ingredient: Ingredient(
                    name: "Молоко",
                    amount: 150,
                    unit: "мл",
                    isCustomizable: true,
                    minAmount: 100,
                    maxAmount: 200
                ),
                value: .constant(150)
            )
        }
        .padding()
        .background(Color("backgroundColor"))
        .preferredColorScheme(.dark)
    }
}
