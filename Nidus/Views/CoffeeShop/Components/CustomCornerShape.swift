//
//  Untitled.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/8/25.
//

import SwiftUI

/// Форма для створення заокруглень тільки на вибраних кутах
struct CustomCornerShape: Shape {
    // MARK: - Властивості
    var radius: CGFloat
    var corners: UIRectCorner
    
    // MARK: - Shape
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
struct CustomCornerShape_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Всі кути
            CustomCornerShape(radius: 20, corners: .allCorners)
                .fill(Color.blue)
                .frame(width: 200, height: 100)
                .previewDisplayName("All Corners")
            
            // Тільки верхні кути
            CustomCornerShape(radius: 20, corners: [.topLeft, .topRight])
                .fill(Color.green)
                .frame(width: 200, height: 100)
                .previewDisplayName("Top Corners")
            
            // Тільки нижні кути
            CustomCornerShape(radius: 20, corners: [.bottomLeft, .bottomRight])
                .fill(Color.orange)
                .frame(width: 200, height: 100)
                .previewDisplayName("Bottom Corners")
        }
        .padding()
        .background(Color("backgroundColor"))
        .previewLayout(.sizeThatFits)
    }
}
