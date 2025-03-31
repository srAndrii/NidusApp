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
        do {
            let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let endpoint = "/user/search?email=\(encodedEmail)"
            
            guard let url = URL(string: networkService.getBaseURL() + endpoint) else {
                throw APIError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let token = UserDefaults.standard.string(forKey: "accessToken") {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                throw APIError.unauthorized
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Виводимо отримані дані для відладки
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Відповідь сервера (searchUsers): \(jsonString)")
            }
            
            // Спробуємо обробити JSON вручну для кращого контролю
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let id = json["id"] as? String,
                   let email = json["email"] as? String {
                    
                    // Отримуємо дані про ролі
                    var userRoles: [Role] = []
                    if let rolesArray = json["roles"] as? [[String: Any]] {
                        for roleDict in rolesArray {
                            guard let roleId = roleDict["id"] as? String,
                                  let roleName = roleDict["name"] as? String else {
                                continue
                            }
                            
                            let roleDescription = roleDict["description"] as? String
                            
                            // Для дат використовуємо поточну дату, якщо неможливо декодувати
                            var createdDate = Date()
                            var updatedDate = Date()
                            
                            if let createdDateString = roleDict["createdAt"] as? String {
                                createdDate = parseDate(createdDateString) ?? Date()
                            }
                            
                            if let updatedDateString = roleDict["updatedAt"] as? String {
                                updatedDate = parseDate(updatedDateString) ?? Date()
                            }
                            
                            let role = Role(
                                id: roleId,
                                name: roleName,
                                description: roleDescription,
                                createdAt: createdDate,
                                updatedAt: updatedDate
                            )
                            
                            userRoles.append(role)
                        }
                    }
                    
                    // Створюємо користувача вручну
                    let user = User(
                        id: id,
                        email: email,
                        firstName: json["firstName"] as? String,
                        lastName: json["lastName"] as? String,
                        phone: json["phone"] as? String,
                        avatarUrl: json["avatarUrl"] as? String,
                        roles: userRoles.isEmpty ? nil : userRoles
                    )
                    
                    print("Успішно створено користувача вручну: \(user.email)")
                    print("Ролі користувача: \(user.roles?.map { $0.name } ?? ["Не призначено"])")
                    
                    return user
                }
            }
            
            // Якщо ручне створення не спрацювало, спробуємо стандартний декодер
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(User.self, from: data)
        } catch {
            print("Помилка при пошуку користувача: \(error)")
            throw error
        }
    }

    // Допоміжна функція для парсингу дат
    private func parseDate(_ dateString: String) -> Date? {
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd"
        ].map { format -> DateFormatter in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return formatter
        }
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    
    func getUsers() async throws -> [User] {
        return try await networkService.fetch(endpoint: "/user")
    }
}
