//
//  StatusBadge.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/8/25.
//

import SwiftUI

/// Компонент для відображення статусу у вигляді бейджа
struct StatusBadge: View {
    // MARK: - Властивості
    let isActive: Bool
    let activeText: String
    let inactiveText: String
    let activeColor: Color
    let inactiveColor: Color
    
    // MARK: - View
    var body: some View {
        HStack(spacing: 4) {
            // Індикатор статусу (кружечок)
            Circle()
                .fill(isActive ? activeColor : inactiveColor)
                .frame(width: 8, height: 8)
            
            // Текст статусу
            Text(isActive ? activeText : inactiveText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isActive ? activeColor : inactiveColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            (isActive ? activeColor : inactiveColor)
                .opacity(0.1)
                .cornerRadius(12)
        )
    }
}

// MARK: - Preview
struct StatusBadge_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StatusBadge(
                isActive: true,
                activeText: "Відкрито",
                inactiveText: "Закрито",
                activeColor: .green,
                inactiveColor: .red
            )
            .previewDisplayName("Active")
            
            StatusBadge(
                isActive: false,
                activeText: "Відкрито",
                inactiveText: "Закрито",
                activeColor: .green,
                inactiveColor: .red
            )
            .previewDisplayName("Inactive")
        }
        .padding()
        .background(Color("backgroundColor"))
        .previewLayout(.sizeThatFits)
    }
}
