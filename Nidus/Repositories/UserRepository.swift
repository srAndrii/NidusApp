// UserRepository.swift
import Foundation

protocol UserRepositoryProtocol {
    func getProfile() async throws -> User
    func updateProfile(firstName: String?, lastName: String?, phone: String?) async throws -> User
    func searchUsers(email: String) async throws -> User
    func getUsers() async throws -> [User]
}

class UserRepository: UserRepositoryProtocol {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService.shared) {
        self.networkService = networkService
    }
    
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
    
    func searchUsers(email: String) async throws -> User {
        return try await networkService.fetch(endpoint: "/user/search?email=\(email)")
    }
    
    func getUsers() async throws -> [User] {
        return try await networkService.fetch(endpoint: "/user")
    }
}
