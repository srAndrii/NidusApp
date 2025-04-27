//
//  View+Extensions.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import SwiftUI

// Розширення для placeholder в TextField
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// Розширення для градієнту карточки
extension LinearGradient {
    static func cardGradient(
        startPoint: UnitPoint = .top,
        endPoint: UnitPoint = .bottomTrailing
    ) -> LinearGradient {
        return LinearGradient(
            gradient: Gradient(colors: [Color("cardTop"), Color("cardBottom")]),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}

// Налаштовуваний ефект скла
struct BlurView: UIViewRepresentable {
    // Стиль розмиття
    // - systemUltraThinMaterial: найбільш прозорий
    // - systemThinMaterial: трохи менш прозорий
    // - systemMaterial: середній рівень прозорості
    // - systemThickMaterial: менш прозорий
    // - systemChromeMaterial: спеціальний ефект в стилі Chrome
    // - light: світлий ефект розмиття
    // - dark: темний ефект розмиття
    // - regular: стандартний ефект розмиття
    var style: UIBlurEffect.Style
    
    // Рівень прозорості від 0.0 (повністю прозорий) до 1.0 (повністю непрозорий)
    var opacity: Double = 0.8
    
    // Фоновий колір (за замовчуванням прозорий)
    var backgroundColor: UIColor? = nil
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let view = UIVisualEffectView(effect: blurEffect)
        view.alpha = opacity
        
        if let bgColor = backgroundColor {
            view.backgroundColor = bgColor.withAlphaComponent(0.1)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
        uiView.alpha = opacity
        
        if let bgColor = backgroundColor {
            uiView.backgroundColor = bgColor.withAlphaComponent(0.1)
        }
    }
}

// Модифікатор для логотипу як фону
extension View {
    func logoBackground() -> some View {
        self.background(
            VStack {
                Image("Logo")
                    .resizable()
                    .renderingMode(.original)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIScreen.main.bounds.width * 0.7)
                    .saturation(1.5)
                    .opacity(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity),
            alignment: .center
        )
    }
}
