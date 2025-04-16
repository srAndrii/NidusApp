//
//  MenuGroupsViewModel.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/2/25.
//

import Foundation

class MenuGroupsViewModel: ObservableObject {
    // MARK: - Опубліковані властивості
    
    @Published var menuGroups: [MenuGroup] = []
    @Published var menuItemCounts: [String: Int] = [:] // ID групи: кількість пунктів
    @Published var isLoading = false
    @Published var error: String?
    @Published var showSuccess = false
    @Published var successMessage = ""
    
    // MARK: - Залежності та властивості
    
    private let repository = DIContainer.shared.menuGroupRepository
    private let menuItemRepository = DIContainer.shared.menuItemRepository
    
    // MARK: - Користувацькі методи для роботи з групами меню
    
    /// Завантаження груп меню для кав'ярні
    @MainActor
    func loadMenuGroups(coffeeShopId: String) async {
        isLoading = true
        error = nil
        
        do {
            menuGroups = try await repository.getMenuGroups(coffeeShopId: coffeeShopId)
            // Сортування за порядком відображення
            menuGroups.sort { $0.displayOrder < $1.displayOrder }
            
            // Завантажуємо кількість пунктів для кожної групи
            for group in menuGroups {
                await loadMenuItemsCount(groupId: group.id)
            }
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
            print("Помилка завантаження груп меню: \(error)")
        }
        
        isLoading = false
    }
    
    /// Завантаження кількості пунктів меню для групи
    @MainActor
    func loadMenuItemsCount(groupId: String) async {
        do {
            let items = try await menuItemRepository.getMenuItems(groupId: groupId)
            menuItemCounts[groupId] = items.count
        } catch {
            print("Помилка завантаження кількості пунктів меню для групи \(groupId): \(error)")
            // Встановлюємо 0, щоб уникнути nil
            menuItemCounts[groupId] = 0
        }
    }
    
    /// Отримання кількості пунктів для групи
    func getMenuItemsCount(for groupId: String) -> Int {
        return menuItemCounts[groupId] ?? 0
    }
    
    // MARK: - Адміністративні методи для роботи з групами меню
    
    /// Створення нової групи меню
    @MainActor
    func createMenuGroup(coffeeShopId: String, name: String, description: String?, displayOrder: Int) async {
        isLoading = true
        error = nil
        
        do {
            // Використовуємо метод з репозиторію, що вже існує
            let newGroup = try await repository.createMenuGroup(
                coffeeShopId: coffeeShopId,
                name: name,
                description: description,
                displayOrder: displayOrder
            )
            
            // Додаємо нову групу до списку і сортуємо
            menuGroups.append(newGroup)
            menuGroups.sort { $0.displayOrder < $1.displayOrder }
            
            // Для нової групи кількість пунктів - 0
            menuItemCounts[newGroup.id] = 0
            
            showSuccessMessage("Групу меню \"\(name)\" успішно створено!")
        } catch let apiError as APIError {
            handleError(apiError)
            print("API помилка при створенні групи меню: \(apiError)")
        } catch {
            self.error = error.localizedDescription
            print("Помилка при створенні групи меню: \(error)")
        }
        
        isLoading = false
    }
    
    // Визначаємо структуру запиту для оновлення групи меню
    struct UpdateMenuGroupRequest: Codable {
        let name: String?
        let description: String?
        let displayOrder: Int?
    }

    @MainActor
    func updateMenuGroup(coffeeShopId: String, groupId: String, name: String?, description: String?, displayOrder: Int?) async {
        isLoading = true
        error = nil
        
        do {
            // Створюємо запит
            let updateRequest = UpdateMenuGroupRequest(
                name: name,
                description: description,
                displayOrder: displayOrder
            )
            
            // Замість прямого використання загального patch методу
            // Реалізуємо спеціальний підхід для обробки відповіді
            
            // 1. Створюємо URL-запит напряму
            let endpoint = "/coffee-shops/\(coffeeShopId)/menu-groups/\(groupId)"
            let jsonData = try JSONEncoder().encode(updateRequest)
            
            var urlRequest = try createRequest(for: endpoint, method: "PATCH")
            urlRequest.httpBody = jsonData
            
            // 2. Надсилаємо запит
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // 3. Перевіряємо статус-код відповіді
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
            
            // 4. Замість декодування повної відповіді, отримуємо тільки базові поля групи меню
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Створюємо об'єкт MenuGroup з необхідних полів, ігноруючи menuItems
                let updatedGroup = MenuGroup(
                    id: json["id"] as? String ?? groupId,
                    name: json["name"] as? String ?? name ?? "",
                    description: json["description"] as? String,
                    displayOrder: json["displayOrder"] as? Int ?? displayOrder ?? 0,
                    coffeeShopId: coffeeShopId,
                    menuItems: nil,  // Важливо встановити nil для menuItems
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                // Оновлюємо групу в списку
                if let index = menuGroups.firstIndex(where: { $0.id == groupId }) {
                    menuGroups[index] = updatedGroup
                }
                
                // Пересортовуємо список, якщо змінився порядок відображення
                menuGroups.sort { $0.displayOrder < $1.displayOrder }
                
                showSuccessMessage("Групу меню успішно оновлено!")
            } else {
                throw APIError.decodingFailed(NSError(domain: "MenuGroupsViewModel", code: 1, userInfo: nil))
            }
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }

    // Допоміжний метод для створення запиту
    private func createRequest(for endpoint: String, method: String) throws -> URLRequest {
        let baseURL = "https://nidus-845c224671ea.herokuapp.com/api" // або отримати з NetworkService
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw APIError.unauthorized
        }
        
        return request
    }
    
    /// Видалення групи меню
    @MainActor
    func deleteMenuGroup(coffeeShopId: String, groupId: String) async {
        isLoading = true
        error = nil
        
        do {
            try await repository.deleteMenuGroup(coffeeShopId: coffeeShopId, groupId: groupId)
            
            // Видаляємо групу зі списку
            menuGroups.removeAll { $0.id == groupId }
            
            // Видаляємо інформацію про кількість пунктів
            menuItemCounts.removeValue(forKey: groupId)
            
            showSuccessMessage("Групу меню успішно видалено!")
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Оновлення порядку відображення групи меню
    @MainActor
    func updateDisplayOrder(coffeeShopId: String, groupId: String, order: Int) async {
        do {
            let updatedGroup = try await repository.updateDisplayOrder(
                coffeeShopId: coffeeShopId,
                groupId: groupId,
                order: order
            )
            
            // Оновлюємо групу в списку
            if let index = menuGroups.firstIndex(where: { $0.id == groupId }) {
                menuGroups[index] = updatedGroup
            }
            
            // Пересортовуємо список
            menuGroups.sort { $0.displayOrder < $1.displayOrder }
            
            showSuccessMessage("Порядок відображення успішно оновлено!")
        } catch {
            print("Помилка при оновленні порядку відображення: \(error)")
            self.error = "Помилка оновлення порядку: \(error.localizedDescription)"
        }
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
        case .simpleServerError(message: let message):
            self.error = message
        case .unauthorized:
            self.error = "Необхідна авторизація для виконання цієї дії"
        case .decodingFailed(let decodingError):
            self.error = "Помилка обробки даних: \(decodingError.localizedDescription)"
            print("Деталі помилки декодування: \(decodingError)")
        default:
            self.error = apiError.localizedDescription
        }
    }
}
