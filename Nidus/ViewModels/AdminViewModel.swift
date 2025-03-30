//
//  AdminViewModel.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/30/25.
//

import Foundation
import Combine

class AdminViewModel: ObservableObject {
    // Властивості для роботи з користувачами
    @Published var users: [User] = []
    @Published var searchedUser: User?
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    // Репозиторії
    private let userRepository: UserRepositoryProtocol
    private let networkService: NetworkService
    
    init(
        userRepository: UserRepositoryProtocol = DIContainer.shared.userRepository,
        networkService: NetworkService = NetworkService.shared
    ) {
        self.userRepository = userRepository
        self.networkService = networkService
    }
    
    // MARK: - Методи для роботи з користувачами
    
    @MainActor
    func getAllUsers() async {
        isLoading = true
        error = nil
        
        do {
            users = try await userRepository.getUsers()
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func searchUserByEmail(email: String) async {
        isLoading = true
        error = nil
        searchedUser = nil
        
        do {
            searchedUser = try await userRepository.searchUsers(email: email)
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func updateUserProfile(userId: String, firstName: String?, lastName: String?, phone: String?) async throws {
        isLoading = true
        error = nil
        
        // Створюємо структуру запиту для оновлення профілю
        struct UpdateProfileRequest: Codable {
            let firstName: String?
            let lastName: String?
            let phone: String?
        }
        
        do {
            // Оскільки метод оновлення профілю через userRepository працює тільки
            // для поточного користувача, створюємо прямий запит до API
            let updateRequest = UpdateProfileRequest(firstName: firstName, lastName: lastName, phone: phone)
            let endpoint = "/user/\(userId)/profile"
            
            // Виконуємо запит
            let updated: User = try await networkService.patch(endpoint: endpoint, body: updateRequest)
            
            // Оновлюємо знайденого користувача
            searchedUser = updated
            
            // Оновлюємо користувача в загальному списку, якщо він там є
            if let index = users.firstIndex(where: { $0.id == userId }) {
                users[index] = updated
            }
        } catch let apiError as APIError {
            handleError(apiError)
            throw apiError
        } catch {
            self.error = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    @MainActor
    func updateUserRoles(userId: String, roles: [String]) async {
        isLoading = true
        error = nil
        
        // Створюємо структуру запиту для оновлення ролей
        struct UpdateRolesRequest: Codable {
            let roles: [String]
        }
        
        do {
            // Оновлюємо ролі через API
            let updateRequest = UpdateRolesRequest(roles: roles)
            let endpoint = "/user/\(userId)/role"
            
            // Запит повертає оновленого користувача
            let updated: User = try await networkService.patch(endpoint: endpoint, body: updateRequest)
            
            // Оновлюємо знайденого користувача
            searchedUser = updated
            
            // Оновлюємо користувача в загальному списку, якщо він там є
            if let index = users.firstIndex(where: { $0.id == userId }) {
                users[index] = updated
            }
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func deleteUser(userId: String) async {
        isLoading = true
        error = nil
        
        do {
            // Структура для отримання відповіді
            struct DeleteResponse: Codable {
                let message: String
            }
            
            // Викликаємо API для видалення користувача
            let endpoint = "/user/\(userId)"
            let _: DeleteResponse = try await networkService.delete(endpoint: endpoint)
            
            // Видаляємо користувача з локального списку, якщо він там є
            users.removeAll { $0.id == userId }
            
            // Очищаємо знайденого користувача, якщо це він
            if searchedUser?.id == userId {
                searchedUser = nil
            }
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Обробка помилок
    
    private func handleError(_ apiError: APIError) {
        switch apiError {
        case .serverError(_, let message):
            self.error = message ?? "Невідома помилка сервера"
        case .unauthorized:
            self.error = "Необхідна авторизація для виконання цієї дії"
        default:
            self.error = apiError.localizedDescription
        }
        print("API Error: \(apiError)")
    }
}
