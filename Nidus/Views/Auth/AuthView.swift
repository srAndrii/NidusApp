import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var isLoginMode = true // true для логіну, false для реєстрації
    
    var body: some View {
        ZStack {
            // Фон
            Color.backGround
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Логотип
                Image("Logo") // Замінено на твій логотип
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(.top, 40)
                

                
                
                
                
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
                
                
                
                
                
                
                
                
                // Форма входу/реєстрації
                VStack(spacing: 18) {
                    // Поле для email
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(Color("secondaryText"))
                            .padding(.leading, 15)
                        
                        TextField("", text: $email)
                            .placeholder(when: email.isEmpty) {
                                Text("Електронна пошта")
                                    .foregroundColor(Color("secondaryText"))
                            }
                            .foregroundColor(Color("primaryText"))
                            .padding(.vertical, 15)
                            .padding(.leading, 5)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                    }
                    .background(Color("inputField"))
                    .cornerRadius(12)
                    
                    // Поле для пароля
                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(Color("secondaryText"))
                            .padding(.leading, 15)
                        
                        SecureField("", text: $password)
                            .placeholder(when: password.isEmpty) {
                                Text("Пароль")
                                    .foregroundColor(Color("secondaryText"))
                            }
                            .foregroundColor(Color("primaryText"))
                            .padding(.vertical, 15)
                            .padding(.leading, 5)
                    }
                    .background(Color("inputField"))
                    .cornerRadius(12)
                    
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
                
                Spacer()
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

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

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(AuthenticationManager())
    }
}
