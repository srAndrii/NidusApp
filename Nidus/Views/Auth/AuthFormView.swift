//
//  AuthFormView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import SwiftUI

struct AuthFormView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Binding var email: String
    @Binding var password: String
    @Binding var isLoginMode: Bool
    
    var body: some View {
        VStack(spacing: 18) {
            // Поле для email
            CustomTextField(
                iconName: "envelope",
                placeholder: "Електронна пошта",
                text: $email,
                keyboardType: .emailAddress
            )
            
            // Поле для пароля
            CustomTextField(
                iconName: "lock",
                placeholder: "Пароль",
                text: $password,
                isSecure: true
            )
            
            // Повідомлення про помилку
            if let error = authManager.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.top, 10)
                    .multilineTextAlignment(.center)
            }
            
            // Кнопка дії (вхід або реєстрація)
            Button(action: {
                Task {
                    if isLoginMode {
                        await authManager.signIn(email: email, password: password)
                    } else {
                        await authManager.signUp(email: email, password: password)
                    }
                }
            }) {
                HStack {
                    Text(isLoginMode ? "Увійти" : "Зареєструватися")
                        .font(.headline)
                        .foregroundColor(Color("primaryText"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .background(Color("primary"))
                .cornerRadius(12)
            }
            .padding(.top, 8)
            .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
            
            // Індикатор завантаження
            if authManager.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("primary")))
                    .padding(.top, 10)
            }
        }
        .padding(.horizontal, 25)
        .padding(.top, 10)
    }
}

struct AuthFormView_Previews: PreviewProvider {
    static var previews: some View {
        AuthFormView(
            email: .constant("user@example.com"),
            password: .constant("password"),
            isLoginMode: .constant(true)
        )
        .environmentObject(AuthenticationManager())
        .background(Color("backgroundColor"))
    }
}
