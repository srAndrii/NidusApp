// AuthRepository.swift
import Foundation

protocol AuthRepositoryProtocol {
    // MARK: - Користувацький інтерфейс
    func login(email: String, password: String) async throws -> (accessToken: String, refreshToken: String)
    func register(email: String, password: String) async throws -> User
    func logout() async throws
    func refreshToken(refreshToken: String) async throws -> (accessToken: String, refreshToken: String)
}

class AuthRepository: AuthRepositoryProtocol {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService.shared) {
        self.networkService = networkService
    }
    
    // MARK: - Користувацький інтерфейс
    
    struct LoginRequest: Codable {
        let email: String
        let password: String
    }
    
    struct LoginResponse: Codable {
        let access_token: String
        let refresh_token: String
    }
    
    func login(email: String, password: String) async throws -> (accessToken: String, refreshToken: String) {
        let loginRequest = LoginRequest(email: email, password: password)
        let response: LoginResponse = try await networkService.post(endpoint: "/auth/login", body: loginRequest, requiresAuth: false)
        
        networkService.saveTokens(accessToken: response.access_token, refreshToken: response.refresh_token)
        return (response.access_token, response.refresh_token)
    }
    
    struct RegisterRequest: Codable {
        let email: String
        let password: String
    }
    
    struct RegisterResponse: Codable {
        let user: User
        let token: String
    }
    
    func register(email: String, password: String) async throws -> User {
        let registerRequest = RegisterRequest(email: email, password: password)
        let response: RegisterResponse = try await networkService.post(endpoint: "/user/create", body: registerRequest, requiresAuth: false)
        
        // Зберігаємо токен автоматично
        networkService.saveTokens(accessToken: response.token, refreshToken: "")
        return response.user
    }
    
    
    func logout() async throws {
        // Структура для відповіді
        struct LogoutResponse: Codable {
            let message: String
        }
        
        // Викликаємо endpoint для виходу з системи
        let _: LogoutResponse = try await networkService.post(endpoint: "/auth/logout", body: EmptyBody(), requiresAuth: true)
        
        // Очищаємо токени
        networkService.clearTokens()
    }
    
    func refreshToken(refreshToken: String) async throws -> (accessToken: String, refreshToken: String) {
        let refreshRequest = RefreshTokenRequest(refreshToken: refreshToken)
        let response: RefreshTokenResponse = try await networkService.post(endpoint: "/auth/refresh", body: refreshRequest, requiresAuth: false)
        
        networkService.saveTokens(accessToken: response.access_token, refreshToken: response.refresh_token)
        return (response.access_token, response.refresh_token)
    }
    
    struct RefreshTokenRequest: Codable {
        let refreshToken: String
    }
    
    struct RefreshTokenResponse: Codable {
        let access_token: String
        let refresh_token: String
    }
    
    struct EmptyBody: Codable {}
}
