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
    
    /// Описи розмірів для підказок
    private let sizeDescriptions: [String: String] = [
        "S": "Малий",
        "M": "Середній",
        "L": "Великий",
        "XL": "Дуже великий"
    ]
    
    // MARK: - View
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Заголовок секції
            HStack {
                Text("Розмір")
                    .font(.headline)
                    .foregroundColor(Color("primaryText"))
                
                Spacer()
                
                // Підказка про вибраний розмір
                if let description = sizeDescriptions[selectedSize] {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(Color("secondaryText"))
                }
            }
            
            // Селектор розмірів
            HStack(spacing: 12) {
                ForEach(availableSizes, id: \.self) { size in
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
                }
                
                Spacer()
            }
        }
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
        // Адаптивний розмір: маленькі екрани - менші кнопки
        return screenWidth < 375 ? 50 : 60
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
