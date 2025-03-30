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
                // Логотип і заголовок
                AuthHeaderView()
                
                // Перемикач між режимами логіну та реєстрації
                AuthSwitchView(isLoginMode: $isLoginMode)
                
                // Форма введення даних
                AuthFormView(
                    email: $email,
                    password: $password,
                    isLoginMode: $isLoginMode
                )
                
                Spacer()
            }
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(AuthenticationManager())
    }
}
