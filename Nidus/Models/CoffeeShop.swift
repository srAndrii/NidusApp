import Foundation
import CoreLocation

struct CoffeeShop: Identifiable, Codable {
    let id: String
    let name: String
    var address: String?
    var logoUrl: String?
    var ownerId: String?
    var owner: User?
    var allowScheduledOrders: Bool
    var minPreorderTimeMinutes: Int
    var maxPreorderTimeMinutes: Int
    var workingHours: [String: WorkingHoursPeriod]?
    var metadata: String?
    var createdAt: Date
    var updatedAt: Date
    var menuGroups: [MenuGroup]?
    
    // Додаткові властивості, які не передаються з сервера
    var distance: Double?
    
    // Обчислюване властивість для відображення координат
    var coordinate: CLLocationCoordinate2D? {
        // Тут можна реалізувати геокодинг адреси,
        // або якщо координати приходять з сервера, зчитувати їх
        return nil
    }
    
    // Удосконалена властивість для перевірки поточного статусу закладу
    var isOpen: Bool {
        // Отримуємо поточний день тижня (0 - неділя, 1 - понеділок і т.д.)
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date()) - 1 // -1 щоб перейти до 0-based індексації
        let weekdayString = String(weekday)
        
        guard let workingHours = self.workingHours,
              let todayHours = workingHours[weekdayString] else {
            return false // Якщо немає інформації про години роботи, вважаємо закритим
        }
        
        if todayHours.isClosed {
            return false // Якщо сьогодні вихідний
        }
        
        // Перетворюємо рядки часів у дати для порівняння
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let openTime = formatter.date(from: todayHours.open),
              let closeTime = formatter.date(from: todayHours.close) else {
            return false // Якщо не можемо розпарсити час
        }
        
        // Отримуємо поточний час (години:хвилини)
        let now = Date()
        let nowString = formatter.string(from: now)
        guard let nowTime = formatter.date(from: nowString) else {
            return false
        }
        
        // Порівнюємо, чи поточний час знаходиться між часом відкриття і закриття
        return nowTime >= openTime && nowTime <= closeTime
    }
    
    // CodingKeys для Codable
    enum CodingKeys: String, CodingKey {
        case id, name, address, logoUrl, ownerId, owner
        case allowScheduledOrders, minPreorderTimeMinutes, maxPreorderTimeMinutes
        case workingHours, metadata, createdAt, updatedAt, menuGroups
    }
    
    // Ініціалізатор за замовчуванням
    init(id: String, name: String, address: String? = nil, logoUrl: String? = nil,
         ownerId: String? = nil, owner: User? = nil,
         allowScheduledOrders: Bool = false, minPreorderTimeMinutes: Int = 15,
         maxPreorderTimeMinutes: Int = 1440, workingHours: [String: WorkingHoursPeriod]? = nil,
         metadata: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date(),
         menuGroups: [MenuGroup]? = nil, distance: Double? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.logoUrl = logoUrl
        self.ownerId = ownerId
        self.owner = owner
        self.allowScheduledOrders = allowScheduledOrders
        self.minPreorderTimeMinutes = minPreorderTimeMinutes
        self.maxPreorderTimeMinutes = maxPreorderTimeMinutes
        self.workingHours = workingHours
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.menuGroups = menuGroups
        self.distance = distance
    }
    
    // Спеціальний ініціалізатор для декодування з JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        logoUrl = try container.decodeIfPresent(String.self, forKey: .logoUrl)
        ownerId = try container.decodeIfPresent(String.self, forKey: .ownerId)
        owner = try container.decodeIfPresent(User.self, forKey: .owner)
        
        allowScheduledOrders = try container.decodeIfPresent(Bool.self, forKey: .allowScheduledOrders) ?? false
        minPreorderTimeMinutes = try container.decodeIfPresent(Int.self, forKey: .minPreorderTimeMinutes) ?? 15
        maxPreorderTimeMinutes = try container.decodeIfPresent(Int.self, forKey: .maxPreorderTimeMinutes) ?? 1440
        
        // Покращене декодування workingHours
        do {
            // Спочатку спробуємо як звичайний словник WorkingHoursPeriod
            workingHours = try container.decodeIfPresent([String: WorkingHoursPeriod].self, forKey: .workingHours)
        } catch {
            // Якщо стандартне декодування не працює, спробуємо спеціальний підхід
            print("Стандартне декодування workingHours не вдалося, використовуємо альтернативний метод")
            
            // Отримуємо значення як [String: Any]
            if let workingHoursJSON = try? container.decodeIfPresent(String.self, forKey: .workingHours),
               let data = workingHoursJSON.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] {
                
                var periods = [String: WorkingHoursPeriod]()
                
                for (day, data) in json {
                    if let open = data["open"] as? String,
                       let close = data["close"] as? String,
                       let isClosed = data["isClosed"] as? Bool {
                        periods[day] = WorkingHoursPeriod(
                            open: open,
                            close: close,
                            isClosed: isClosed
                        )
                    }
                }
                
                self.workingHours = periods.isEmpty ? nil : periods
            } else {
                // Спробуйте отримати його як сирий словник
                let workingHoursContainer = try? container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .workingHours)
                
                if let container = workingHoursContainer {
                    var periods = [String: WorkingHoursPeriod]()
                    
                    // Ітеруємося по всіх ключах у контейнері
                    for key in container.allKeys {
                        if let dayContainer = try? container.nestedContainer(keyedBy: WorkingHoursCodingKeys.self, forKey: key) {
                            let open = try dayContainer.decodeIfPresent(String.self, forKey: .open) ?? "09:00"
                            let close = try dayContainer.decodeIfPresent(String.self, forKey: .close) ?? "21:00"
                            let isClosed = try dayContainer.decodeIfPresent(Bool.self, forKey: .isClosed) ?? false
                            
                            periods[key.stringValue] = WorkingHoursPeriod(
                                open: open,
                                close: close,
                                isClosed: isClosed
                            )
                        }
                    }
                    
                    self.workingHours = periods.isEmpty ? nil : periods
                } else {
                    self.workingHours = nil
                }
            }
        }
        
        // Спрощене декодування метаданих
        metadata = try container.decodeIfPresent(String.self, forKey: .metadata)
        
        // Декодування дат
        let dateFormatter = ISO8601DateFormatter()
        
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt),
           let date = dateFormatter.date(from: createdAtString) {
            createdAt = date
        } else {
            createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        }
        
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt),
           let date = dateFormatter.date(from: updatedAtString) {
            updatedAt = date
        } else {
            updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        }
        
        // Декодування menuGroups
        menuGroups = try container.decodeIfPresent([MenuGroup].self, forKey: .menuGroups)
        
        // Властивість, яка не передається з сервера
        distance = nil
    }
}

// Допоміжний тип для динамічних ключів
struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

// Ключі для структури робочих годин
enum WorkingHoursCodingKeys: String, CodingKey {
    case open, close, isClosed
}
