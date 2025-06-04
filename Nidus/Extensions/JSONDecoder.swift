//
//  JSONDecoder.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/30/25.
//


import Foundation

extension JSONDecoder {
    static func decode<T: Decodable>(data: Data, type: T.Type, keyPath: String? = nil) -> Result<T, Error> {
        let decoder = JSONDecoder()
        
        // Налаштування декодера
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            // Спробуємо спочатку ISO8601DateFormatter для стандартних форматів
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = iso8601Formatter.date(from: dateStr) {
                return date
            }
            
            // Якщо ISO8601 не спрацював, спробуємо без мілісекунд
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            
            if let date = iso8601Formatter.date(from: dateStr) {
                return date
            }
            
            // Випробовуємо інші формати дати
            let formatters = [
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss'Z'",
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
                if let date = formatter.date(from: dateStr) {
                    return date
                }
            }
            
            // Якщо ніщо не спрацювало, повернемо поточну дату
            return Date()
        }
        
        // Якщо вказано keyPath, спробуємо зчитати з нього
        if let keyPath = keyPath {
            do {
                // Спочатку перетворюємо дані в словник
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    return .failure(NSError(domain: "JSONDecoding", code: 1, userInfo: [NSLocalizedDescriptionKey: "Не вдалося перетворити JSON у словник"]))
                }
                
                // Розділяємо keyPath на частини
                let keys = keyPath.split(separator: ".").map(String.init)
                
                // Поступово перебираємо keyPath
                var currentDict = json
                for (index, key) in keys.enumerated() {
                    if index == keys.count - 1 {
                        // Останній ключ - це наш цільовий об'єкт
                        if let targetJSON = currentDict[key] {
                            // Перетворюємо назад у Data
                            let targetData = try JSONSerialization.data(withJSONObject: targetJSON)
                            // Декодуємо потрібний тип
                            let decodedObject = try decoder.decode(type, from: targetData)
                            return .success(decodedObject)
                        } else {
                            return .failure(NSError(domain: "JSONDecoding", code: 2, userInfo: [NSLocalizedDescriptionKey: "Не знайдено ключ \(key) у JSON"]))
                        }
                    } else {
                        // Проміжний ключ - продовжуємо занурення
                        guard let nextDict = currentDict[key] as? [String: Any] else {
                            return .failure(NSError(domain: "JSONDecoding", code: 3, userInfo: [NSLocalizedDescriptionKey: "Не знайдено проміжний ключ \(key) у JSON"]))
                        }
                        currentDict = nextDict
                    }
                }
                
                return .failure(NSError(domain: "JSONDecoding", code: 4, userInfo: [NSLocalizedDescriptionKey: "Не вдалося знайти об'єкт за keyPath \(keyPath)"]))
            } catch {
                return .failure(error)
            }
        } else {
            // Просто декодуємо все дані як є
            do {
                let decodedObject = try decoder.decode(type, from: data)
                return .success(decodedObject)
            } catch {
                return .failure(error)
            }
        }
    }
}

// Рoзширення для примусового декодування User
extension User {
    static func fromJSON(_ json: [String: Any]) -> User? {
        guard let id = json["id"] as? String,
              let email = json["email"] as? String else {
            return nil
        }
        
        var roles: [Role] = []
        if let rolesJSON = json["roles"] as? [[String: Any]] {
            for roleJSON in rolesJSON {
                if let roleId = roleJSON["id"] as? String,
                   let roleName = roleJSON["name"] as? String {
                    let roleDescription = roleJSON["description"] as? String
                    let role = Role(
                        id: roleId,
                        name: roleName,
                        description: roleDescription,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    roles.append(role)
                }
            }
        }
        
        return User(
            id: id,
            email: email,
            firstName: json["firstName"] as? String,
            lastName: json["lastName"] as? String,
            phone: json["phone"] as? String,
            avatarUrl: json["avatarUrl"] as? String,
            roles: roles.isEmpty ? nil : roles
        )
    }
}
