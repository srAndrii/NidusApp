import Foundation
import UIKit

protocol CoffeeShopRepositoryProtocol {
    func getAllCoffeeShops() async throws -> [CoffeeShop]
    func getCoffeeShopById(id: String) async throws -> CoffeeShop
    func getMyCoffeeShops() async throws -> [CoffeeShop]
    func getCoffeeShopMenu(id: String) async throws -> [MenuGroup]
    func createCoffeeShop(name: String, address: String?) async throws -> CoffeeShop
    func updateCoffeeShop(id: String, params: [String: Any]) async throws -> CoffeeShop
    func searchCoffeeShops(address: String) async throws -> [CoffeeShop]
    func deleteCoffeeShop(id: String) async throws
    func assignOwner(coffeeShopId: String, userId: String) async throws -> CoffeeShop
    
    // Нові методи для завантаження та скидання логотипу
    func uploadLogo(coffeeShopId: String, imageData: Data) async throws -> String
    func resetLogo(coffeeShopId: String) async throws -> String
}

class CoffeeShopRepository: CoffeeShopRepositoryProtocol {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService.shared) {
        self.networkService = networkService
    }
    
    func getAllCoffeeShops() async throws -> [CoffeeShop] {
        return try await networkService.fetch(endpoint: "/coffee-shops/find-all")
    }
    
    func getCoffeeShopById(id: String) async throws -> CoffeeShop {
        return try await networkService.fetch(endpoint: "/coffee-shops/\(id)")
    }
    
    func getMyCoffeeShops() async throws -> [CoffeeShop] {
        return try await networkService.fetch(endpoint: "/coffee-shops/my-shops")
    }
    
    func getCoffeeShopMenu(id: String) async throws -> [MenuGroup] {
        return try await networkService.fetch(endpoint: "/coffee-shops/\(id)/menu")
    }
    
    struct CreateCoffeeShopRequest: Codable {
        let name: String
        let address: String?
    }
    
    func createCoffeeShop(name: String, address: String?) async throws -> CoffeeShop {
        let createRequest = CreateCoffeeShopRequest(name: name, address: address)
        return try await networkService.post(endpoint: "/coffee-shops/create", body: createRequest)
    }
    
    func updateCoffeeShop(id: String, params: [String: Any]) async throws -> CoffeeShop {
        // Створюємо копію параметрів для серіалізації
        var serializableParams = [String: Any]()
        
        // Проходимо по всіх параметрах та підготовляємо їх для серіалізації
        for (key, value) in params {
            if key == "workingHours", let workingHours = value as? [String: WorkingHoursPeriod] {
                // Конвертуємо WorkingHoursPeriod в простий словник
                var workingHoursDict = [String: [String: Any]]()
                
                for (day, period) in workingHours {
                    workingHoursDict[day] = period.toDictionary()
                }
                
                serializableParams[key] = workingHoursDict
            } else {
                // Інші параметри додаємо без змін
                serializableParams[key] = value
            }
        }
        
        // Створюємо JSON дані з серіалізованих параметрів
        let jsonData = try JSONSerialization.data(withJSONObject: serializableParams)
        
        // Створюємо запит
        var urlRequest = try createRequest(for: "/coffee-shops/\(id)", method: "PATCH")
        urlRequest.httpBody = jsonData
        
        // Виконуємо запит
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Перевіряємо відповідь
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        // Декодуємо відповідь вручну, щоб правильно обробити дати
        do {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Створимо копію кав'ярні з існуючих даних
                let existingShop = try await getCoffeeShopById(id: id)
                
                // Витягуємо оновлені поля з відповіді
                let updatedShop = CoffeeShop(
                    id: id,
                    name: json["name"] as? String ?? existingShop.name,
                    address: json["address"] as? String ?? existingShop.address,
                    logoUrl: json["logoUrl"] as? String ?? existingShop.logoUrl,
                    ownerId: json["ownerId"] as? String ?? existingShop.ownerId,
                    owner: existingShop.owner,
                    allowScheduledOrders: json["allowScheduledOrders"] as? Bool ?? existingShop.allowScheduledOrders,
                    minPreorderTimeMinutes: json["minPreorderTimeMinutes"] as? Int ?? existingShop.minPreorderTimeMinutes,
                    maxPreorderTimeMinutes: json["maxPreorderTimeMinutes"] as? Int ?? existingShop.maxPreorderTimeMinutes,
                    workingHours: existingShop.workingHours, // Використовуємо існуючі або оновлені робочі години
                    metadata: json["metadata"] as? String ?? existingShop.metadata,
                    createdAt: existingShop.createdAt,
                    updatedAt: Date(), // Використовуємо поточну дату для updatedAt
                    menuGroups: existingShop.menuGroups,
                    distance: existingShop.distance
                )
                
                return updatedShop
            }
            
            // Якщо не вдалося розібрати JSON вручну, намагаємося використати стандартний декодер
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateStr = try container.decode(String.self)
                
                // Спробуємо кілька форматів дати
                let formatters = [
                    "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                    "yyyy-MM-dd'T'HH:mm:ssZ",
                    "yyyy-MM-dd'T'HH:mm:ss"
                ].map { format -> DateFormatter in
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    return formatter
                }
                
                for formatter in formatters {
                    if let date = formatter.date(from: dateStr) {
                        return date
                    }
                }
                
                // Якщо жоден формат не підійшов, повертаємо поточну дату замість помилки
                return Date()
            }
            
            return try decoder.decode(CoffeeShop.self, from: data)
        } catch {
            print("Помилка при декодуванні відповіді: \(error)")
            
            // Якщо декодування не вдалося, повертаємо існуючі дані кав'ярні з оновленими полями
            let existingShop = try await getCoffeeShopById(id: id)
            return existingShop
        }
    }
    
    private func createRequest(for endpoint: String, method: String) throws -> URLRequest {
        let baseURL = networkService.getBaseURL()
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let token = UserDefaults.standard.string(forKey: "accessToken") else {
            throw APIError.unauthorized
        }
        
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    func searchCoffeeShops(address: String) async throws -> [CoffeeShop] {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return try await networkService.fetch(endpoint: "/coffee-shops/search?address=\(encodedAddress)")
    }
    
    func deleteCoffeeShop(id: String) async throws {
        try await networkService.deleteWithoutResponse(endpoint: "/coffee-shops/\(id)")
    }
    
    func assignOwner(coffeeShopId: String, userId: String) async throws -> CoffeeShop {
        return try await networkService.patch(endpoint: "/coffee-shops/\(coffeeShopId)/assign-owner/\(userId)", body: EmptyBody())
    }
    
    // MARK: - Завантаження файлів
    
    // Метод для завантаження логотипу кав'ярні
    func uploadLogo(coffeeShopId: String, imageData: Data) async throws -> String {
        // Використовуємо multipart/form-data для завантаження файлу
        let endpoint = "/upload/coffee-shop/\(coffeeShopId)/logo"
        
        struct UploadResponse: Decodable {
            let success: Bool
            let url: String
        }
        
        let response: UploadResponse = try await uploadFileWithSimpleDecoding(
            endpoint: endpoint,
            data: imageData,
            fieldName: "file",
            fileName: "logo.jpg",
            mimeType: "image/jpeg"
        )
        
        if response.success {
            return response.url
        } else {
            throw APIError.serverError(statusCode: 500, message: "Не вдалося завантажити логотип")
        }
    }
    
    // Метод для скидання логотипу до дефолтного
    func resetLogo(coffeeShopId: String) async throws -> String {
        struct ResetLogoResponse: Decodable {
            let success: Bool
            let url: String
        }
        
        let response: ResetLogoResponse = try await deleteWithSimpleDecoding(endpoint: "/upload/coffee-shop/\(coffeeShopId)/logo")
        
        if response.success {
            return response.url
        } else {
            throw APIError.serverError(statusCode: 500, message: "Не вдалося скинути логотип")
        }
    }
    
    private func uploadFileWithSimpleDecoding<T: Decodable>(
        endpoint: String,
        data: Data,
        fieldName: String,
        fileName: String,
        mimeType: String
    ) async throws -> T {
        do {
            let (data, response) = try await networkService.createUploadRequest(
                endpoint: endpoint,
                data: data,
                fieldName: fieldName,
                fileName: fileName,
                mimeType: mimeType
            )
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            // ЗМІНА: Додано налаштування для правильного декодування дат
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateStr = try container.decode(String.self)
                
                // Спробуємо кілька форматів дати
                let formatters = [
                    "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                    "yyyy-MM-dd'T'HH:mm:ssZ",
                    "yyyy-MM-dd'T'HH:mm:ss"
                ].map { format -> DateFormatter in
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    return formatter
                }
                
                for formatter in formatters {
                    if let date = formatter.date(from: dateStr) {
                        return date
                    }
                }
                
                // Якщо жоден формат не підійшов, повертаємо поточну дату
                return Date()
            }
            
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Помилка при завантаженні файлу: \(error)")
            throw error
        }
    }

    private func deleteWithSimpleDecoding<T: Decodable>(endpoint: String) async throws -> T {
        do {
            let (data, response) = try await networkService.createDeleteRequest(endpoint: endpoint)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            // ЗМІНА: Додано налаштування для правильного декодування дат
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateStr = try container.decode(String.self)
                
                // Спробуємо кілька форматів дати
                let formatters = [
                    "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                    "yyyy-MM-dd'T'HH:mm:ssZ",
                    "yyyy-MM-dd'T'HH:mm:ss"
                ].map { format -> DateFormatter in
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    return formatter
                }
                
                for formatter in formatters {
                    if let date = formatter.date(from: dateStr) {
                        return date
                    }
                }
                
                // Якщо жоден формат не підійшов, повертаємо поточну дату
                return Date()
            }
            
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Помилка при видаленні логотипу: \(error)")
            throw error
        }
    }
    
    struct EmptyBody: Codable {}
}

// Розширення WorkingHoursPeriod для конвертації в словник
extension WorkingHoursPeriod {
    func toDictionary() -> [String: Any] {
        return [
            "open": open,
            "close": close,
            "isClosed": isClosed
        ]
    }
}
