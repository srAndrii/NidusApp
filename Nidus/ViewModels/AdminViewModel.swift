//
//  AdminViewModel.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/30/25.
//

import Foundation
import Combine

class AdminViewModel: ObservableObject {
    // MARK: - Опубліковані властивості
    
    @Published var users: [User] = []
    @Published var searchedUser: User?
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var showSuccess: Bool = false
    @Published var successMessage: String = ""
    
    // MARK: - Залежності та властивості
    
    private let userRepository: UserRepositoryProtocol
    private let networkService: NetworkService
    
    // MARK: - Ініціалізація
    
    init(
        userRepository: UserRepositoryProtocol = DIContainer.shared.userRepository,
        networkService: NetworkService = NetworkService.shared
    ) {
        self.userRepository = userRepository
        self.networkService = networkService
    }
    
    // MARK: - Методи для роботи з користувачами
    
    /// Отримання списку всіх користувачів
    @MainActor
    func getAllUsers() async {
        isLoading = true
        error = nil
        
        do {
            users = try await userRepository.getUsers()
            
            // Завантажуємо ролі для кожного користувача
            for i in 0..<users.count {
                let userRoles = await getUserRoles(userId: users[i].id)
                users[i].roles = userRoles
            }
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Пошук користувача за email
    @MainActor
    func searchUserByEmail(email: String) async {
        isLoading = true
        error = nil
        searchedUser = nil
        
        do {
            print("Пошук користувача за email: \(email)")
            searchedUser = try await userRepository.searchUsers(email: email)
            
            if let user = searchedUser {
                print("Знайдено користувача: \(user.email)")
                print("Ролі користувача: \(user.roles?.map { $0.name } ?? ["Не призначено"])")
            } else {
                print("Користувача не знайдено")
            }
        } catch let apiError as APIError {
            handleError(apiError)
            print("API Error: \(apiError)")
        } catch {
            self.error = error.localizedDescription
            print("Unknown error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Методи управління користувачами
    
    /// Оновлення ролей користувача
    @MainActor
    func updateUserRoles(userId: String, roles: [String]) async {
        isLoading = true
        error = nil
        
        // Створюємо структуру запиту для оновлення ролей
        struct UpdateRolesRequest: Codable {
            let roles: [String]
        }
        
        print("Оновлення ролей для користувача \(userId): \(roles)")
        
        do {
            // Оновлюємо ролі через API
            let updateRequest = UpdateRolesRequest(roles: roles)
            let endpoint = "/user/\(userId)/role"
            
            // Виводимо запит для відладки
            let encoder = JSONEncoder()
            if let requestData = try? encoder.encode(updateRequest),
               let requestString = String(data: requestData, encoding: .utf8) {
                print("Запит на оновлення ролей: \(requestString)")
            }
            
            // Запит повертає оновленого користувача
            let updated: User = try await networkService.patch(endpoint: endpoint, body: updateRequest)
            
            // Виводимо відповідь для відладки
            print("Оновлено користувача: \(updated.email)")
            print("Нові ролі: \(updated.roles?.map { $0.name } ?? ["Не призначено"])")
            
            // Оновлюємо знайденого користувача
            searchedUser = updated
            
            // Оновлюємо користувача в загальному списку, якщо він там є
            if let index = users.firstIndex(where: { $0.id == userId }) {
                users[index] = updated
            }
            
            showSuccessMessage("Ролі користувача успішно оновлено!")
        } catch let apiError as APIError {
            handleError(apiError)
            print("API Error при оновленні ролей: \(apiError)")
        } catch {
            self.error = error.localizedDescription
            print("Unknown error при оновленні ролей: \(error)")
        }
        
        isLoading = false
    }
    
    /// Отримання ролей користувача
    func getUserRoles(userId: String) async -> [Role]? {
        do {
            // Структура для отримання відповіді з API
            struct UserWithRolesResponse: Codable {
                let id: String
                let email: String
                let roles: [Role]
            }
            
            // Виконуємо запит до API для отримання ролей
            let endpoint = "/user/\(userId)/role"
            let userWithRoles: UserWithRolesResponse = try await networkService.fetch(endpoint: endpoint)
            
            return userWithRoles.roles
        } catch {
            print("Error fetching user roles: \(error)")
            return nil
        }
    }
    
    /// Оновлення профілю користувача
    @MainActor
    func updateUserProfile(userId: String, firstName: String?, lastName: String?, phone: String?) async {
        isLoading = true
        error = nil
        
        // Додаємо відладку
        print("Оновлення профілю користувача \(userId)")
        print("firstName: \(firstName ?? "nil"), lastName: \(lastName ?? "nil"), phone: \(phone ?? "nil")")
        
        // Створюємо структуру запиту для оновлення профілю
        struct UpdateProfileRequest: Codable {
            let firstName: String?
            let lastName: String?
            let phone: String?
        }
        
        do {
            // На основі файлів серверу, правильний ендпоінт - "/user/profile"
            // Це оновлює профіль поточного автентифікованого користувача
            let updateRequest = UpdateProfileRequest(firstName: firstName, lastName: lastName, phone: phone)
            let endpoint = "/user/profile"  // Змінений ендпоінт!
            
            // Виводимо запит для відладки
            let encoder = JSONEncoder()
            if let requestData = try? encoder.encode(updateRequest),
               let requestString = String(data: requestData, encoding: .utf8) {
                print("Запит на оновлення профілю: \(requestString)")
            }
            
            // Викликаємо метод patch
            let updated: User = try await networkService.patch(endpoint: endpoint, body: updateRequest)
            
            // Виводимо відповідь для відладки
            print("Успішно оновлено користувача: \(updated.email)")
            print("Нові дані: firstName: \(updated.firstName ?? "nil"), lastName: \(updated.lastName ?? "nil"), phone: \(updated.phone ?? "nil")")
            
            // Оновлюємо знайденого користувача
            searchedUser = updated
            
            // Оновлюємо користувача в загальному списку, якщо він там є
            if let index = users.firstIndex(where: { $0.id == userId }) {
                users[index] = updated
            }
            
            showSuccessMessage("Профіль користувача успішно оновлено!")
        } catch let apiError as APIError {
            handleError(apiError)
            print("API Error при оновленні профілю: \(apiError)")
        } catch {
            self.error = error.localizedDescription
            print("Unknown error при оновленні профілю: \(error)")
        }
        
        isLoading = false
    }
    
    /// Альтернативний метод оновлення профілю користувача за допомогою низькорівневого API
    @MainActor
    func updateUserProfileManually(userId: String, firstName: String?, lastName: String?, phone: String?) async {
        isLoading = true
        error = nil
        
        // Додаємо відладку
        print("Ручне оновлення профілю користувача \(userId)")
        print("firstName: \(firstName ?? "nil"), lastName: \(lastName ?? "nil"), phone: \(phone ?? "nil")")
        
        do {
            // Створюємо структуру запиту
            struct UpdateProfileRequest: Codable {
                let firstName: String?
                let lastName: String?
                let phone: String?
            }
            
            let updateRequest = UpdateProfileRequest(firstName: firstName, lastName: lastName, phone: phone)
            
            // Створюємо URL запиту
            let endpoint = "/user/\(userId)/profile"
            guard let url = URL(string: networkService.getBaseURL() + endpoint) else {
                throw APIError.invalidURL
            }
            
            // Створюємо запит
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"  // або "PUT", залежно від API
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Додаємо токен авторизації
            if let token = UserDefaults.standard.string(forKey: "accessToken") {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                throw APIError.unauthorized
            }
            
            // Кодуємо тіло запиту
            let encoder = JSONEncoder()
            let requestData = try encoder.encode(updateRequest)
            request.httpBody = requestData
            
            // Виводимо тіло запиту для відладки
            if let requestString = String(data: requestData, encoding: .utf8) {
                print("Тіло запиту: \(requestString)")
            }
            
            // Виконуємо запит
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Виводимо відповідь для відладки
            if let responseString = String(data: data, encoding: .utf8) {
                print("Відповідь сервера: \(responseString)")
            }
            
            // Перевіряємо код відповіді
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("Код відповіді: \(httpResponse.statusCode)")
            
            if (200...299).contains(httpResponse.statusCode) {
                // Успішне оновлення
                // Декодуємо відповідь
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                do {
                    let updatedUser = try decoder.decode(User.self, from: data)
                    
                    // Оновлюємо знайденого користувача
                    searchedUser = updatedUser
                    
                    // Оновлюємо користувача в загальному списку, якщо він там є
                    if let index = users.firstIndex(where: { $0.id == userId }) {
                        users[index] = updatedUser
                    }
                    
                    showSuccessMessage("Профіль користувача успішно оновлено!")
                } catch {
                    print("Помилка декодування відповіді: \(error)")
                    
                    // Якщо не вдалося декодувати відповідь, спробуємо оновити користувача через повторний пошук
                    await searchUserByEmail(email: searchedUser?.email ?? "")
                    
                    showSuccessMessage("Профіль оновлено, але не вдалося отримати оновлені дані.")
                }
            } else {
                // Обробка помилки
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorData["message"] as? String {
                    throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
                } else {
                    throw APIError.serverError(statusCode: httpResponse.statusCode, message: "Помилка оновлення профілю")
                }
            }
        } catch let apiError as APIError {
            handleError(apiError)
            print("API Error при оновленні профілю: \(apiError)")
        } catch {
            self.error = error.localizedDescription
            print("Unknown error при оновленні профілю: \(error)")
        }
        
        isLoading = false
    }
    
    /// Видалення користувача
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
            
            showSuccessMessage("Користувача успішно видалено!")
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Допоміжні методи
    
    /// Показ повідомлення про успіх
    func showSuccessMessage(_ message: String) {
        self.successMessage = message
        self.showSuccess = true
    }
    
    /// Обробка помилок API
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
