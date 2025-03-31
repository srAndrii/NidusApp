//
//  Role.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/30/25.
//

import Foundation

struct Role: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String?
    let createdAt: Date
    let updatedAt: Date
    
    // Додаємо явний ініціалізатор з параметрами
    init(id: String, name: String, description: String?, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Role, rhs: Role) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Зберігаємо декодер для JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        
        // Спробуємо різні формати дати
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            createdAt = Self.parseDate(dateString) ?? Date()
        } else {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }
        
        if let dateString = try? container.decode(String.self, forKey: .updatedAt) {
            updatedAt = Self.parseDate(dateString) ?? Date()
        } else {
            updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        }
    }
    
    // Допоміжний метод для парсингу різних форматів дати
    private static func parseDate(_ dateString: String) -> Date? {
        let dateFormatters: [DateFormatter] = [
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                return formatter
            }()
        ]
        
        for formatter in dateFormatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
}
