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
    @Environment(\.colorScheme) private var colorScheme
    
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
    
    /// Додаткова ціна за інгредієнт понад безкоштовну кількість
    private var additionalPrice: Decimal? {
        // Якщо немає ціни за одиницю або не визначена безкоштовна кількість, повертаємо nil
        guard let pricePerUnit = ingredient.pricePerUnit, 
              let freeAmount = ingredient.freeAmount else {
            return nil
        }
        
        // Якщо поточне значення менше або дорівнює безкоштовній кількості, додаткова ціна відсутня
        if freeAmount >= value {
            return nil
        }
        
        // Інакше рахуємо додаткову ціну для перевищення
        let excessAmount = value - freeAmount
        let additionalCost = Decimal(excessAmount) * pricePerUnit
        
        return additionalCost
    }
    
    /// Форматування ціни для відображення
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        
        return formatter.string(from: NSDecimalNumber(decimal: price)) ?? "\(price)"
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
                
                // Тільки поточне значення без додаткової ціни
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
                    
                    // Індикатор безкоштовної кількості, якщо він визначений
                    if let freeAmount = ingredient.freeAmount {
                        let minValue = ingredient.minAmount ?? 0
                        let maxValue = ingredient.maxAmount ?? (ingredient.amount * 2)
                        let range = maxValue - minValue
                        
                        if range > 0 {
                            let freePosition = min(1.0, (freeAmount - minValue) / range) * geometry.size.width
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.7))
                                .frame(width: 2, height: 12)
                                .cornerRadius(1)
                                .position(x: freePosition, y: 4)
                        }
                    }
                }
            }
            .frame(height: 18) // Збільшена висота для GeometryReader, щоб помістити текст
            
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
                
                // Показуємо тільки додаткову ціну, якщо вона є
                if let additionalPrice = additionalPrice, additionalPrice > 0 {
                    Text("+₴\(formatPrice(additionalPrice))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("primary"))
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
        .background(
            ZStack {
                // Скляний фон
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear)
                    .overlay(
                        BlurView(
                            style: colorScheme == .light ? .systemThinMaterial : .systemMaterialDark,
                            opacity: colorScheme == .light ? 0.95 : 0.95,
                            backgroundColor: nil
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
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
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
        // Завжди крок 1 для будь-якого типу інгредієнтів
        return 1.0
    }
}

// MARK: - Preview
struct IngredientCustomizationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Базовий інгредієнт
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
            .previewDisplayName("Базовий інгредієнт")
            
            // Інгредієнт з додатковою ціною
            IngredientCustomizationView(
                ingredient: Ingredient(
                    id: "milk-id",
                    name: "Молоко",
                    amount: 150,
                    unit: "мл",
                    isCustomizable: true,
                    minAmount: 100,
                    maxAmount: 200,
                    freeAmount: 150,
                    pricePerUnit: Decimal(0.1)
                ),
                value: .constant(180)
            )
            .previewDisplayName("Інгредієнт з ціною")
        }
        .padding()
        .background(Color("backgroundColor"))
    }
}
