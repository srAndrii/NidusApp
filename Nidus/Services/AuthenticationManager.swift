// Services/AuthenticationManager.swift
import Foundation
import Combine

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let authRepository: AuthRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    
    init(authRepository: AuthRepositoryProtocol = DIContainer.shared.authRepository,
         userRepository: UserRepositoryProtocol = DIContainer.shared.userRepository) {
        self.authRepository = authRepository
        self.userRepository = userRepository
        
        // Перевірити наявність токену при запуску
        checkAuthentication()
    }
    
    private func checkAuthentication() {
        // Перевірка токена в UserDefaults
        if UserDefaults.standard.string(forKey: "accessToken") != nil {
            isAuthenticated = true
            // Завантажуємо дані користувача
            Task {
                await loadCurrentUser()
                // Підключаємо WebSocket з userId після завантаження користувача
                if let userId = currentUser?.id {
                    OrderWebSocketManager.shared.connect(userId: userId)
                }
            }
        }
    }
    
    @MainActor
    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            // Виконуємо запит авторизації
            let (accessToken, _) = try await authRepository.login(email: email, password: password)
            
            // Перевіряємо, чи отримано токен
            if !accessToken.isEmpty {
                isAuthenticated = true
                // Завантажуємо дані користувача
                await loadCurrentUser()
                // Підключаємо WebSocket з userId
                if let userId = currentUser?.id {
                    OrderWebSocketManager.shared.connect(userId: userId)
                }
            } else {
                error = "Не вдалося авторизуватися. Спробуйте ще раз."
            }
        } catch let apiError as APIError {
            switch apiError {
            case .serverError(_, let message):
                print("Server error message: \(message ?? "none")") 
                self.error = message ?? "Невідома помилка"
            default:
                self.error = apiError.localizedDescription
            }
            print("Login error: \(apiError)")
        } catch {
            self.error = error.localizedDescription
            print("Login error: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func signUp(email: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            // Виконуємо запит реєстрації
            let user = try await authRepository.register(email: email, password: password)
            
            // Якщо реєстрація успішна, встановлюємо поточного користувача
            currentUser = user
            isAuthenticated = true
            
            // Підключаємо WebSocket з userId нового користувача
            print("🔗 AuthManager: Connecting WebSocket for new user: \(user.id)")
            OrderWebSocketManager.shared.connect(userId: user.id)
        } catch let apiError as APIError {
            switch apiError {
            case .serverError(_, let message):
                print("Server error message: \(message ?? "none")")
                self.error = message ?? "Невідома помилка"
            default:
                self.error = apiError.localizedDescription
            }
            print("Login error: \(apiError)")
        } catch {
            self.error = error.localizedDescription
            print("Login error: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func signOut() async {
        isLoading = true
        
        do {
            // Виконуємо запит виходу з системи
            try await authRepository.logout()
        } catch {
            print("Logout error: \(error)")
            // Навіть якщо є помилка, очищаємо локальні дані
        }
        
        // Очищаємо дані користувача в будь-якому випадку
        currentUser = nil
        isAuthenticated = false
        isLoading = false
        
        // Відключаємо WebSocket
        OrderWebSocketManager.shared.disconnect()
    }
    
    @MainActor
    private func loadCurrentUser() async {
        do {
            currentUser = try await userRepository.getProfile()
        } catch {
            print("Failed to load user profile: \(error)")
            // Це не критична помилка, тому не змінюємо isAuthenticated
        }
    }
    
    func refreshTokenIfNeeded() async -> Bool {
        // Перевіряємо, чи є refresh token
        guard let refreshToken = UserDefaults.standard.string(forKey: "refreshToken") else {
            return false
        }
        
        do {
            // Пробуємо оновити токени
            let (_, _) = try await authRepository.refreshToken(refreshToken: refreshToken)
            // Переконектимо WebSocket з userId (якщо є поточний користувач)
            if let userId = currentUser?.id {
                OrderWebSocketManager.shared.connect(userId: userId)
            }
            return true
        } catch {
            print("Token refresh failed: \(error)")
            // Якщо оновлення не вдалось, виходимо з системи
            await signOut()
            return false
        }
    }
}
