//
//  SwiftUIView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/8/25.
//

import SwiftUI

/// Компонент для відображення кнопки "Назад"
struct BackButtonView: View {
    // MARK: - Властивості
    @Environment(\.presentationMode) var presentationMode
    var color: Color = Color("primary") // Змінено на оранжевий колір із теми
    var backgroundColor: Color = Color.black.opacity(0.4)
    
    // MARK: - View
    var body: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .padding(10)
                .background(Circle().fill(backgroundColor))
                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
        }
    }
}

// MARK: - Preview
struct BackButtonView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            BackButtonView()
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
