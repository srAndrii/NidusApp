//
//  User.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import Foundation

struct User: Identifiable, Codable {
    let id: String
    let email: String
    var firstName: String?
    var lastName: String?
    var phone: String?
    var avatarUrl: String?
    var roles: [Role]?
    
    // Додаємо явний ініціалізатор з параметрами
    init(id: String, email: String, firstName: String? = nil, lastName: String? = nil,
         phone: String? = nil, avatarUrl: String? = nil, roles: [Role]? = nil) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.avatarUrl = avatarUrl
        self.roles = roles
    }
    
    // Обчислювана властивість для відображення повного імені
    var fullName: String {
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName) \(lastName)"
        } else if let firstName = firstName {
            return firstName
        } else if let lastName = lastName {
            return lastName
        } else {
            return email
        }
    }
    
    // Обчислювана властивість для отримання рядка з назвами ролей
    var rolesString: String {
        if let roles = roles, !roles.isEmpty {
            return roles.map { $0.name }.joined(separator: ", ")
        } else {
            return "Не призначено"
        }
    }
    
    // Спеціальні ключі для декодування, якщо сервер використовує інші ключі
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName
        case lastName
        case phone
        case avatarUrl
        case roles
    }
    
    // Використовуємо init для забезпечення зворотної сумісності
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        
        // Обережно декодуємо roles, якщо вони є
        roles = try container.decodeIfPresent([Role].self, forKey: .roles)
    }
}
