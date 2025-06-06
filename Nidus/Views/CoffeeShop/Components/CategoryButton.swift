//
//  CategoryButton.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/8/25.
//

import SwiftUI

/// Компонент для відображення кнопки категорії в горизонтальному списку

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Назва категорії
                Text(title)
                    .font(.callout)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? Color("primary") : Color("secondaryText"))
                
                // Індикатор вибраної категорії
                if isSelected {
                    Circle()
                        .fill(Color("primary"))
                        .frame(width: 5, height: 5)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 5, height: 5)
                }
            }
            .padding(.horizontal, 6)
        }
    }
}


// MARK: - Preview
struct CategoryButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CategoryButton(title: "Всі", isSelected: true, action: {})
                .previewDisplayName("Selected")
            
            CategoryButton(title: "Гарячі напої", isSelected: false, action: {})
                .previewDisplayName("Not Selected")
        }
        .padding()
        .background(Color("backgroundColor"))
        .previewLayout(.sizeThatFits)
    }
}
