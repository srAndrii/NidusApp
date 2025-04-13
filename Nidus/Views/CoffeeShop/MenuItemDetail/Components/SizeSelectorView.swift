//
//  Untitled.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/8/25.
//

import SwiftUI

/// Компонент для вибору розміру товару
struct SizeSelectorView: View {
    // MARK: - Властивості
    @Binding var selectedSize: String
    let availableSizes: [String]
    let onSizeChanged: (String) -> Void
    var showTitle: Bool = false // Новий параметр для показу/приховування заголовка
    
    /// Описи розмірів для підписів
    private let sizeDescriptions: [String: String] = [
        "S": "Малий",
        "M": "Середній",
        "L": "Великий",
        "XL": "Дуже великий"
    ]
    
    // MARK: - View
    var body: some View {
        HStack(alignment: .center) {
            // Заголовок секції (тільки якщо showTitle=true)
            if showTitle {
                Text("Розмір")
                    .font(.headline)
                    .foregroundColor(Color("primaryText"))
                
                Spacer()
            }
            
            // Кнопки розмірів у горизонтальному ряду
            HStack(spacing: 16) {
                ForEach(availableSizes, id: \.self) { size in
                    VStack(spacing: 4) {
                        // Кнопка розміру
                        SizeButton(
                            size: size,
                            isSelected: selectedSize == size,
                            onSelect: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if selectedSize != size {
                                        selectedSize = size
                                        onSizeChanged(size)
                                    }
                                }
                            }
                        )
                        
                        // Підпис під кнопкою з фіксованою шириною
                        Text(sizeDescriptions[size] ?? "")
                            .font(.caption)
                            .foregroundColor(selectedSize == size ? Color("primary") : Color("secondaryText"))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(minWidth: 60)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(5)
        // Не використовуємо фон тут, оскільки він буде у батьківському компоненті
    }
}

/// Кнопка вибору розміру
struct SizeButton: View {
    // MARK: - Властивості
    let size: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    /// Діаметр кнопки залежно від розміру екрана
    private var buttonDiameter: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        // Адаптивний розмір для мобільних екранів
        return screenWidth < 375 ? 45 : 50
    }
    
    // MARK: - View
    var body: some View {
        Button(action: onSelect) {
            ZStack {
                // Фон кнопки
                Circle()
                    .fill(isSelected ? Color("primary") : Color("inputField"))
                    .frame(width: buttonDiameter, height: buttonDiameter)
                    .shadow(color: isSelected ? Color("primary").opacity(0.3) : Color.clear, radius: 5, x: 0, y: 2)
                
                // Текст розміру
                Text(size)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : Color("secondaryText"))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0) // Невелике збільшення при виборі
    }
}
// MARK: - Preview
struct SizeSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Стандартні розміри
            SizeSelectorView(
                selectedSize: .constant("M"),
                availableSizes: ["S", "M", "L"],
                onSizeChanged: { _ in }
            )
            .previewDisplayName("Standard Sizes")
            
            // Розширені розміри
            SizeSelectorView(
                selectedSize: .constant("M"),
                availableSizes: ["S", "M", "L", "XL"],
                onSizeChanged: { _ in }
            )
            .previewDisplayName("Extended Sizes")
        }
        .padding()
        .background(Color("backgroundColor"))
        .preferredColorScheme(.dark)
    }
}
