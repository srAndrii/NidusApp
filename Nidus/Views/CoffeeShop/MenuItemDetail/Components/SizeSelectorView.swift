//
//  SizeSelectorView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/8/25.
//

import SwiftUI

/// Компонент для вибору розміру товару
struct SizeSelectorView: View {
    // MARK: - Властивості
    @Binding var selectedSize: String
    @Environment(\.colorScheme) private var colorScheme
    
    // Структура для передачі розмірів
    var sizes: [Size] = []
    let onSizeChanged: (String) -> Void
    var showTitle: Bool = false // Параметр для показу/приховування заголовка
    
    // Базовий розмір кнопки для найменшого розміру
    private let baseButtonSize: CGFloat = 50
    
    // MARK: - Ініціалізатор
    init(selectedSize: Binding<String>, sizes: [Size], onSizeChanged: @escaping (String) -> Void, showTitle: Bool = false) {
        self._selectedSize = selectedSize
        self.sizes = sizes
        self.onSizeChanged = onSizeChanged
        self.showTitle = showTitle
    }
    
    // MARK: - View
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Заголовок секції (тільки якщо showTitle=true)
            if showTitle {
                Text("Розмір")
                    .font(.headline)
                    .foregroundColor(Color("primaryText"))
            }
            
            // Горизонтальний скрол для кнопок розміру
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Сортуємо розміри за порядковим номером
                    let sortedSizes = sizes.sorted { $0.order < $1.order }
                    
                    // Створюємо кнопки для кожного розміру
                    ForEach(sortedSizes) { size in
                        sizeButton(
                            size: size,
                            isSelected: selectedSize == size.abbreviation,
                            buttonSize: calculateButtonSize(for: size, in: sortedSizes),
                            onSelect: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if selectedSize != size.abbreviation {
                                        selectedSize = size.abbreviation
                                        onSizeChanged(size.abbreviation)
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 10)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: sizes.count <= 3 ? .center : .leading) // Центрування, якщо мало елементів
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            // Автоматично встановлюємо розмір за замовчуванням при першому з'явленні
            if selectedSize.isEmpty, let defaultSize = sizes.first(where: { $0.isDefault }) {
                selectedSize = defaultSize.abbreviation
                onSizeChanged(defaultSize.abbreviation)
            }
        }
    }
    
    // MARK: - Допоміжні методи і компоненти
    
    /// Обчислення розміру кнопки відносно розміру
    private func calculateButtonSize(for size: Size, in sortedSizes: [Size]) -> CGFloat {
        // Якщо є лише один розмір, використовуємо базовий розмір
        if sortedSizes.count == 1 {
            return baseButtonSize
        }
        
        // Знаходимо мінімальний і максимальний порядковий номер
        let minOrder = sortedSizes.map { $0.order }.min() ?? 1
        let maxOrder = sortedSizes.map { $0.order }.max() ?? minOrder
        
        // Якщо всі розміри мають однаковий порядковий номер, використовуємо базовий розмір
        if maxOrder == minOrder {
            return baseButtonSize
        }
        
        // Мінімальний та максимальний розмір кнопок
        let minButtonSize: CGFloat = baseButtonSize
        let maxButtonSize: CGFloat = baseButtonSize * 1.5
        
        // Розраховуємо розмір кнопки відносно порядкового номера
        let scaleFactor = CGFloat(size.order - minOrder) / CGFloat(maxOrder - minOrder)
        return minButtonSize + scaleFactor * (maxButtonSize - minButtonSize)
    }
    
    /// Компонент кнопки розміру
    private func sizeButton(size: Size, isSelected: Bool, buttonSize: CGFloat, onSelect: @escaping () -> Void) -> some View {
        VStack(spacing: 4) {
            // Кнопка розміру
            Button(action: onSelect) {
                ZStack {
                    // Фон кнопки зі скляним ефектом
                    Circle()
                        .fill(Color.clear)
                        .overlay(
                            BlurView(
                                style: colorScheme == .light ? .systemThinMaterial : .systemMaterialDark,
                                opacity: isSelected ? 0.9 : 0.6
                            )
                            .clipShape(Circle()) // Обрізаємо ефект блюру по формі круга
                        )
                        .overlay(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color("primary").opacity(0.8), Color("primary")]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .opacity(isSelected ? 1.0 : 0.0)
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            isSelected ? Color("primary").opacity(0.7) : Color("nidusCoolGray").opacity(0.5),
                                            isSelected ? Color("primary").opacity(0.9) : Color("nidusLightBlueGray").opacity(0.3)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .frame(width: buttonSize, height: buttonSize) // Динамічний розмір кнопки
                        .shadow(color: isSelected ? Color("primary").opacity(0.3) : Color.clear, radius: 6, x: 0, y: 3)
                        .background(Color.clear) // Прозорий фон навколо круга
                    
                    // Відображення тексту розміру залежно від типу (цифровий або буквений)
                    if let (value, unit) = parseNumericAbbreviation(size.abbreviation) {
                        // Цифровий розмір (типу "200мл")
                        VStack(spacing: 0) {
                            Text(value)
                                .font(fontSizeForButton(buttonSize: buttonSize, isBold: true))
                                .fontWeight(.bold)
                                .foregroundColor(isSelected ? .white : Color("primaryText"))
                            
                            Text(unit)
                                .font(fontSizeForButton(buttonSize: buttonSize, isBold: false, smallerBy: 2))
                                .fontWeight(.medium)
                                .foregroundColor(isSelected ? .white : Color("primaryText"))
                        }
                    } else {
                        // Буквений розмір
                        // Адаптуємо розмір шрифту залежно від довжини абревіатури та розміру кнопки
                        Text(size.abbreviation)
                            .font(fontForAbbreviation(size.abbreviation, buttonSize: buttonSize))
                            .fontWeight(.bold)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                            .foregroundColor(isSelected ? .white : Color("primaryText"))
                            .frame(width: buttonSize * 0.8)
                    }
                }
                .background(Color.clear) // Прозорий фон навколо кнопки
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isSelected ? 1.05 : 1.0) // Невелике збільшення при виборі
            .background(Color.clear) // Прозорий фон кнопки
            
            // Назва розміру під кнопкою
            Text(size.name)
                .font(.caption)
                .foregroundColor(isSelected ? Color("primary") : Color("secondaryText"))
                .fixedSize(horizontal: false, vertical: true)
                .frame(minWidth: buttonSize)
                .multilineTextAlignment(.center)
            
            // Додаткова ціна (якщо є)
            if size.additionalPrice != 0 {
                Text(formatAdditionalPrice(size.additionalPrice))
                    .font(.caption2)
                    .foregroundColor(isSelected ? Color("primary") : Color("secondaryText"))
                    .opacity(0.8)
            }
        }
        .frame(height: buttonSize * 2.2) // Зменшуємо висоту для вирівнювання всіх елементів
        .background(Color.clear) // Прозорий фон для всього компонента
    }
    
    /// Підбір шрифту відповідно до розміру кнопки
    private func fontSizeForButton(buttonSize: CGFloat, isBold: Bool, smallerBy: CGFloat = 0) -> Font {
        let calculatedSize = max(buttonSize / 3.5 - smallerBy, 8) // Мінімальний розмір шрифту 8
        
        return isBold ? Font.system(size: calculatedSize, weight: .bold) : Font.system(size: calculatedSize)
    }
    
    /// Визначення шрифту для абревіатури залежно від довжини та розміру кнопки
    private func fontForAbbreviation(_ abbreviation: String, buttonSize: CGFloat) -> Font {
        let length = abbreviation.count
        let baseSize = buttonSize / 3
        
        let fontSize: CGFloat
        switch length {
        case 1:
            fontSize = baseSize // Повний розмір для 1 символу
        case 2:
            fontSize = baseSize * 0.9 // 90% для 2 символів
        case 3:
            fontSize = baseSize * 0.8 // 80% для 3 символів
        default:
            fontSize = baseSize * 0.7 // 70% для більше 3 символів
        }
        
        return Font.system(size: max(fontSize, 8), weight: .bold) // Мінімальний розмір 8
    }
    
    /// Розділення абревіатури на числову частину та одиницю виміру
    /// Повертає tuple (value, unit) якщо абревіатура містить цифри та літери
    /// Наприклад "200мл" -> ("200", "мл")
    private func parseNumericAbbreviation(_ abbreviation: String) -> (String, String)? {
        // Регулярний вираз для пошуку цифр на початку та нецифрових символів в кінці
        let pattern = "^(\\d+)([^\\d]+)$"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: abbreviation.utf16.count)
            
            if let match = regex.firstMatch(in: abbreviation, options: [], range: range) {
                // Отримуємо числову частину
                if let valueRange = Range(match.range(at: 1), in: abbreviation) {
                    let value = String(abbreviation[valueRange])
                    
                    // Отримуємо одиницю виміру
                    if let unitRange = Range(match.range(at: 2), in: abbreviation) {
                        let unit = String(abbreviation[unitRange])
                        return (value, unit)
                    }
                }
            }
        } catch {
            print("Помилка при розборі абревіатури: \(error)")
        }
        
        return nil
    }
    
    /// Форматування додаткової ціни
    private func formatAdditionalPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        
        let formattedPrice = formatter.string(from: NSDecimalNumber(decimal: abs(price))) ?? "\(abs(price))"
        
        return price > 0 ? "+₴\(formattedPrice)" : "-₴\(formattedPrice)"
    }
}

// MARK: - Preview
struct SizeSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Перегляд з різними буквеними абревіатурами (багато розмірів)
            SizeSelectorView(
                selectedSize: .constant("M"),
                sizes: [
                    Size(id: "size-0", name: "Малюсінький", abbreviation: "XS", additionalPrice: -25, isDefault: false, order: 1),
                    Size(id: "size-1", name: "Малий", abbreviation: "S", additionalPrice: -15, isDefault: false, order: 2),
                    Size(id: "size-2", name: "Середній", abbreviation: "M", additionalPrice: 0, isDefault: true, order: 3),
                    Size(id: "size-3", name: "Великий", abbreviation: "L", additionalPrice: 20, isDefault: false, order: 4),
                    Size(id: "size-4", name: "Дуже великий", abbreviation: "XL", additionalPrice: 30, isDefault: false, order: 5),
                    Size(id: "size-5", name: "Величезний", abbreviation: "XXL", additionalPrice: 40, isDefault: false, order: 6),
                    Size(id: "size-6", name: "Гігантський", abbreviation: "XXXL", additionalPrice: 50, isDefault: false, order: 7)
                ],
                onSizeChanged: { _ in },
                showTitle: true
            )
            .previewDisplayName("Many Sizes")
            .frame(width: 375) // Симулюємо екран iPhone
            .padding()
            
            // Перегляд з цифровими абревіатурами
            SizeSelectorView(
                selectedSize: .constant("350мл"),
                sizes: [
                    Size(id: "size-6", name: "Малий", abbreviation: "200мл", additionalPrice: -15, isDefault: false, order: 1),
                    Size(id: "size-7", name: "Середній", abbreviation: "350мл", additionalPrice: 0, isDefault: true, order: 2),
                    Size(id: "size-8", name: "Великий", abbreviation: "450мл", additionalPrice: 20, isDefault: false, order: 3)
                ],
                onSizeChanged: { _ in },
                showTitle: true
            )
            .previewDisplayName("Numeric Abbreviations")
            .padding()
        }
        .background(Color("backgroundColor"))
    }
}
