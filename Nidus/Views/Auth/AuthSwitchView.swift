//
//  AuthSwitchView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import SwiftUI

struct AuthSwitchView: View {
    @Binding var isLoginMode: Bool
    
    var body: some View {
        ZStack {
            // Фоновий контейнер
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.inputField)
            
            // Рухомий селектор
            HStack {
                if isLoginMode {
                    Spacer()
                        .frame(width: 0)
                } else {
                    Spacer()
                }
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("primary"))
                    .frame(width: UIScreen.main.bounds.width / 2 - 30)
                
                if isLoginMode {
                    Spacer()
                } else {
                    Spacer()
                        .frame(width: 0)
                }
            }
            .padding(4)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLoginMode)
            
            // Кнопки
            HStack(spacing: 0) {
                Button(action: {
                    withAnimation {
                        isLoginMode = true
                    }
                }) {
                    Text("Увійти")
                        .font(.system(size: 16, weight: isLoginMode ? .semibold : .regular))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                
                Button(action: {
                    withAnimation {
                        isLoginMode = false
                    }
                }) {
                    Text("Зареєструватися")
                        .font(.system(size: 16, weight: !isLoginMode ? .semibold : .regular))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
        }
        .frame(height: 50)
        .padding(.horizontal, 25)
    }
}

struct AuthSwitchView_Previews: PreviewProvider {
    static var previews: some View {
        AuthSwitchView(isLoginMode: .constant(true))
            .background(Color("backgroundColor"))
            .previewLayout(.sizeThatFits)
    }
}
