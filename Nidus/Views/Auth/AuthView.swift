//
//  AuthView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var isLoginMode = true // true для логіну, false для реєстрації
    
    var body: some View {
        VStack(spacing: 20) {
            // Логотип або заголовок
            Image(systemName: "cup.and.saucer.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(Color("primaryColor"))
                .padding(.top, 50)
            
            Text("Nidus")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color("primaryColor"))
            
            // Перемикач між логіном і реєстрацією
            Picker(selection: $isLoginMode, label: Text("Mode")) {
                Text("Увійти").tag(true)
                Text("Зареєструватися").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Форма входу/реєстрації
            VStack(spacing: 15) {
                TextField("Електронна пошта", text: $email)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Пароль", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                
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
                    Text(isLoginMode ? "Увійти" : "Зареєструватися")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("primaryColor"))
                        .cornerRadius(10)
                }
                .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
                
                // Індикатор завантаження
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color("primaryColor")))
                        .padding(.top, 10)
                }
                
                // Повідомлення про помилку
                if let error = authManager.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 10)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
    }
}
