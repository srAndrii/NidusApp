// UserRepository.swift
import Foundation

protocol UserRepositoryProtocol {
    // MARK: - Користувацький інтерфейс
    /// Отримання профілю поточного користувача
    func getProfile() async throws -> User
    
    /// Оновлення профілю поточного користувача
    func updateProfile(firstName: String?, lastName: String?, phone: String?) async throws -> User
}

class UserRepository: UserRepositoryProtocol {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService.shared) {
        self.networkService = networkService
    }
    
    // MARK: - Користувацький інтерфейс
    
    func getProfile() async throws -> User {
        return try await networkService.fetch(endpoint: "/user/profile")
    }
    
    struct UpdateProfileRequest: Codable {
        let firstName: String?
        let lastName: String?
        let phone: String?
    }
    
    func updateProfile(firstName: String?, lastName: String?, phone: String?) async throws -> User {
        let updateRequest = UpdateProfileRequest(firstName: firstName, lastName: lastName, phone: phone)
        return try await networkService.patch(endpoint: "/user/profile", body: updateRequest)
    }
}
