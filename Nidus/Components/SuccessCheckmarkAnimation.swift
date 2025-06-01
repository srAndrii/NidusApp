//
//  SuccessCheckmarkAnimation.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 5/31/25.
//

import SwiftUI

struct SuccessCheckmarkAnimation: View {
    @Binding var isShowing: Bool
    @State private var animationPhase = 0
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if isShowing {
            ZStack {
                // Кругова анімація - зовнішнє кільце
                Circle()
                    .stroke(Color("primary"), lineWidth: 3)
                    .frame(width: 100, height: 100)
                    .scaleEffect(animationPhase >= 3 ? 1.5 : 1.0)
                    .opacity(animationPhase >= 3 ? 0 : 0.5)
                    .animation(.easeOut(duration: 0.8), value: animationPhase)
                
                // Заповнений круг
                Circle()
                    .fill(Color("primary"))
                    .frame(width: 80, height: 80)
                    .scaleEffect(animationPhase >= 1 ? 1.0 : 0.5)
                    .opacity(animationPhase >= 4 ? 0 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animationPhase)
                
                // Галочка
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(animationPhase >= 2 ? 1.0 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animationPhase)
            }
            .scaleEffect(animationPhase >= 4 ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.3), value: animationPhase)
            .onAppear {
                startAnimation()
            }
            .onDisappear {
                // Скидаємо стан при зникненні
                animationPhase = 0
            }
        }
    }
    
    private func startAnimation() {
        // Скидаємо анімацію на початок
        animationPhase = 0
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Послідовні фази анімації
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            animationPhase = 1 // Розширення основного круга
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            animationPhase = 2 // Поява галочки
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            animationPhase = 3 // Розширення зовнішнього кільця
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            animationPhase = 4 // Зменшення та зникнення
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isShowing = false
            // Даємо час на завершення анімації перед скиданням
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animationPhase = 0
            }
        }
    }
}