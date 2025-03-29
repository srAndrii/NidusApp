//
//  CoffeeShop.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import Foundation
import CoreLocation

struct CoffeeShop: Identifiable, Codable {
    let id: String
    let name: String
    var address: String?
    var logoUrl: String?
    let ownerId: String?
    
    // Налаштування замовлень
    var allowScheduledOrders: Bool
    var minPreorderTimeMinutes: Int
    var maxPreorderTimeMinutes: Int
    
    // Робочі години (спрощена структура для Swift)
    var workingHours: [String: WorkingHoursPeriod]?
    var createdAt: Date
    var updatedAt: Date
    
    // Додаткові поля для відображення у додатку
    var distance: Double?
    var isOpen: Bool = true
    
    // Обчислювана властивість для отримання координат з метаданих
    var coordinate: CLLocationCoordinate2D? {
        guard let metadata = try? JSONDecoder().decode([String: MetadataValue].self, from: Data((metadataJSON ?? "{}").utf8)),
              case .double(let lat) = metadata["latitude"],
              case .double(let lng) = metadata["longitude"] else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    // Поле для зберігання JSON метаданих
    var metadataJSON: String?
    
    enum MetadataValue: Codable {
        case string(String)
        case double(Double)
        case bool(Bool)
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let stringValue = try? container.decode(String.self) {
                self = .string(stringValue)
            } else if let doubleValue = try? container.decode(Double.self) {
                self = .double(doubleValue)
            } else if let boolValue = try? container.decode(Bool.self) {
                self = .bool(boolValue)
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode metadata value")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let value):
                try container.encode(value)
            case .double(let value):
                try container.encode(value)
            case .bool(let value):
                try container.encode(value)
            }
        }
    }
}

struct WorkingHoursPeriod: Codable {
    var open: String
    var close: String
    var isClosed: Bool
}
