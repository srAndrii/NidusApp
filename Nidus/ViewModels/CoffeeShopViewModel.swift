import Foundation
import Combine
import UIKit

class CoffeeShopViewModel: ObservableObject {
    @Published var coffeeShops: [CoffeeShop] = []
    @Published var myCoffeeShops: [CoffeeShop] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var selectedCoffeeShop: CoffeeShop?
    @Published var showSuccess: Bool = false
    @Published var successMessage: String = ""
    
    
    private let coffeeShopRepository: CoffeeShopRepositoryProtocol
    private let networkService = NetworkService.shared // Додаємо посилання на NetworkService
    var authManager: AuthenticationManager
    
    // Константи для ролей
    private let ROLE_SUPER_ADMIN = "superadmin"
    private let ROLE_COFFEE_SHOP_OWNER = "coffee_shop_owner"
    
    init(coffeeShopRepository: CoffeeShopRepositoryProtocol = DIContainer.shared.coffeeShopRepository,
         authManager: AuthenticationManager) {
        self.coffeeShopRepository = coffeeShopRepository
        self.authManager = authManager
    }
    
    // MARK: - Перевірка ролей
    
    // Перевіряє, чи є користувач Super Admin
    func isSuperAdmin() -> Bool {
        return authManager.currentUser?.roles?.contains(where: { $0.name == ROLE_SUPER_ADMIN }) ?? false
    }
    
    // Перевіряє, чи є користувач Coffee Shop Owner
    func isCoffeeShopOwner() -> Bool {
        return authManager.currentUser?.roles?.contains(where: { $0.name == ROLE_COFFEE_SHOP_OWNER }) ?? false
    }
    
    // Перевіряє, чи має користувач доступ до управління кав'ярнями
    func canManageCoffeeShops() -> Bool {
        return isSuperAdmin() || isCoffeeShopOwner()
    }
    
    // Перевіряє, чи має користувач доступ до конкретної кав'ярні
    func canManageCoffeeShop(_ coffeeShop: CoffeeShop) -> Bool {
        if isSuperAdmin() {
            return true
        }
        
        if isCoffeeShopOwner() {
            // Перевіряємо, чи є користувач власником цієї кав'ярні
            if let userId = authManager.currentUser?.id,
               let ownerId = coffeeShop.ownerId {
                return userId == ownerId
            }
        }
        
        return false
    }
    
    // MARK: - Завантаження даних
    
    @MainActor
    func loadAllCoffeeShops() async {
        // Для Super Admin завантажуємо всі кав'ярні
        if isSuperAdmin() {
            await loadCoffeeShops()
        } else if isCoffeeShopOwner() {
            // Для Coffee Shop Owner завантажуємо тільки його кав'ярні
            await loadMyCoffeeShops()
        }
    }
    
    @MainActor
    func loadCoffeeShops() async {
        isLoading = true
        error = nil
        
        do {
            coffeeShops = try await coffeeShopRepository.getAllCoffeeShops()
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func loadMyCoffeeShops() async {
        isLoading = true
        error = nil
        
        do {
            myCoffeeShops = try await coffeeShopRepository.getMyCoffeeShops()
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Управління кав'ярнями
    
    @MainActor
    func createCoffeeShop(name: String, address: String?) async {
        isLoading = true
        error = nil
        
        // Перевіряємо права доступу перед спробою створення
        if !canManageCoffeeShops() {
            error = "У вас немає прав для створення кав'ярень. Необхідна роль Coffee Shop Owner або Super Admin."
            print("Помилка авторизації: \(String(describing: error))")
            print("Поточні ролі користувача: \(String(describing: authManager.currentUser?.roles?.map { $0.name }))")
            isLoading = false
            return
        }
        
        do {
            print("Спроба створення кав'ярні з ім'ям: \"\(name)\"")
            print("Поточний користувач: \(String(describing: authManager.currentUser?.email))")
            print("Ролі користувача: \(String(describing: authManager.currentUser?.roles?.map { $0.name }))")
            
            let newCoffeeShop = try await coffeeShopRepository.createCoffeeShop(name: name, address: address)
            
            print("Кав'ярню успішно створено: \(newCoffeeShop.id)")
            
            // Оновлюємо список кав'ярень після створення
            if isSuperAdmin() {
                coffeeShops.append(newCoffeeShop)
                await loadCoffeeShops() // Перезавантажуємо всі кав'ярні
            }
            
            // Завжди оновлюємо список "моїх кав'ярень"
            await loadMyCoffeeShops()
            
            showSuccess = true
            successMessage = "Кав'ярню \"\(name)\" успішно створено!"
            
        } catch let apiError as APIError {
            handleError(apiError)
            print("API Error при створенні кав'ярні: \(apiError)")
            
            // Додаткова інформація про помилку авторизації
            if case .unauthorized = apiError {
                print("Помилка авторизації. Токен: \(UserDefaults.standard.string(forKey: "accessToken") ?? "відсутній")")
            } else if case .serverError(let code, let message) = apiError {
                print("Помилка сервера \(code): \(message ?? "немає повідомлення")")
            }
        } catch {
            self.error = error.localizedDescription
            print("Невідома помилка при створенні кав'ярні: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func updateCoffeeShop(id: String, params: [String: Any]) async {
        isLoading = true
        error = nil
        
        do {
            let updatedCoffeeShop = try await coffeeShopRepository.updateCoffeeShop(id: id, params: params)
            
            // Оновлюємо кав'ярню в списках
            if let index = coffeeShops.firstIndex(where: { $0.id == id }) {
                coffeeShops[index] = updatedCoffeeShop
            }
            
            if let index = myCoffeeShops.firstIndex(where: { $0.id == id }) {
                myCoffeeShops[index] = updatedCoffeeShop
            }
            
            // Оновлюємо вибрану кав'ярню, якщо вона відповідає оновленій
            if selectedCoffeeShop?.id == id {
                selectedCoffeeShop = updatedCoffeeShop
            }
            
            showSuccess = true
            successMessage = "Кав'ярню \"\(updatedCoffeeShop.name)\" успішно оновлено!"
            
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func deleteCoffeeShop(id: String) async {
        isLoading = true
        error = nil
        
        do {
            // Запам'ятаємо назву кав'ярні перед видаленням
            let coffeeShopName = coffeeShops.first(where: { $0.id == id })?.name ??
                               myCoffeeShops.first(where: { $0.id == id })?.name ??
                               "Кав'ярню"
            
            // Викликаємо API для видалення кав'ярні
            try await coffeeShopRepository.deleteCoffeeShop(id: id)
            
            // Видаляємо кав'ярню зі списків
            coffeeShops.removeAll { $0.id == id }
            myCoffeeShops.removeAll { $0.id == id }
            
            // Якщо видалена кав'ярня була вибрана, очищаємо вибір
            if selectedCoffeeShop?.id == id {
                selectedCoffeeShop = nil
            }
            
            showSuccess = true
            successMessage = "\(coffeeShopName) успішно видалено!"
            
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Завантаження логотипу
    

    @MainActor
    func uploadLogo(for coffeeShopId: String, image: UIImage) async throws -> String {
        isLoading = true
        error = nil
        
        do {
            // Валідація зображення
            let (isValid, errorMessage) = validateImage(image)
            if !isValid {
                error = errorMessage
                isLoading = false
                throw NSError(domain: "CoffeeShopViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage ?? "Невірний формат зображення"])
            }
            
            // Стиснемо зображення перед завантаженням
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                throw NSError(domain: "CoffeeShopViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Не вдалося підготувати зображення для завантаження"])
            }
            
            // Показуємо розмір зображення для відладки
            print("Розмір зображення для завантаження: \(imageData.count) байт")
            
            // Завантажуємо логотип напряму через NetworkService
            let endpoint = "/upload/coffee-shop/\(coffeeShopId)/logo"
            let responseData = try await networkService.createUploadRequest(
                endpoint: endpoint,
                data: imageData,
                fieldName: "file",
                fileName: "logo.jpg",
                mimeType: "image/jpeg"
            )
            
            // Обробка відповіді вручну
            if let responseString = String(data: responseData.0, encoding: .utf8) {
                print("Відповідь сервера при завантаженні файлу: \(responseString)")
                
                // Витягуємо URL напряму з JSON
                if let json = try? JSONSerialization.jsonObject(with: responseData.0) as? [String: Any],
                   let success = json["success"] as? Bool,
                   success == true,
                   let url = json["url"] as? String {
                    
                    // ОНОВЛЕННЯ ДАНИХ ЛОКАЛЬНО БЕЗ ЗАПИТУ ДО СЕРВЕРА
                    // Оновлюємо локальні дані кав'ярні без повторного запиту
                    if let index = coffeeShops.firstIndex(where: { $0.id == coffeeShopId }) {
                        coffeeShops[index].logoUrl = url
                    }
                    
                    if let index = myCoffeeShops.firstIndex(where: { $0.id == coffeeShopId }) {
                        myCoffeeShops[index].logoUrl = url
                    }
                    
                    if selectedCoffeeShop?.id == coffeeShopId {
                        selectedCoffeeShop?.logoUrl = url
                    }
                    
                    // Оновлюємо дані на сервері, але не чекаємо відповіді
                    Task {
                        let params: [String: Any] = ["logoUrl": url]
                        do {
                            _ = try await coffeeShopRepository.updateCoffeeShop(id: coffeeShopId, params: params)
                        } catch {
                            print("Некритична помилка при оновленні даних кав'ярні: \(error)")
                        }
                    }
                    
                    // Показуємо повідомлення про успіх
                    showSuccessMessage("Логотип успішно завантажено!")
                    isLoading = false
                    
                    // Не закриваємо екран після завантаження логотипу
                    return url
                }
            }
            
            throw NSError(domain: "CoffeeShopViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Не вдалося обробити відповідь сервера"])
        } catch let apiError as APIError {
            let errorMessage = "Помилка завантаження: \(apiError.localizedDescription)"
            print(errorMessage)
            handleError(apiError)
            isLoading = false
            throw apiError
        } catch {
            let errorMessage = "Невідома помилка: \(error.localizedDescription)"
            print(errorMessage)
            self.error = error.localizedDescription
            isLoading = false
            throw error
        }
    }

    @MainActor
    func resetLogo(for coffeeShopId: String) async throws -> String {
        isLoading = true
        error = nil
        
        do {
            // Видаляємо логотип напряму через NetworkService
            let endpoint = "/upload/coffee-shop/\(coffeeShopId)/logo"
            let responseData = try await networkService.createDeleteRequest(endpoint: endpoint)
            
            // Обробка відповіді вручну
            if let responseString = String(data: responseData.0, encoding: .utf8) {
                print("Відповідь сервера при видаленні логотипу: \(responseString)")
                
                // Витягуємо URL напряму з JSON
                if let json = try? JSONSerialization.jsonObject(with: responseData.0) as? [String: Any],
                   let success = json["success"] as? Bool,
                   success == true,
                   let url = json["url"] as? String {
                    
                    // ОНОВЛЕННЯ ДАНИХ ЛОКАЛЬНО БЕЗ ЗАПИТУ ДО СЕРВЕРА
                    // Оновлюємо локальні дані кав'ярні без повторного запиту
                    if let index = coffeeShops.firstIndex(where: { $0.id == coffeeShopId }) {
                        coffeeShops[index].logoUrl = url
                    }
                    
                    if let index = myCoffeeShops.firstIndex(where: { $0.id == coffeeShopId }) {
                        myCoffeeShops[index].logoUrl = url
                    }
                    
                    if selectedCoffeeShop?.id == coffeeShopId {
                        selectedCoffeeShop?.logoUrl = url
                    }
                    
                    // Оновлюємо дані на сервері, але не чекаємо відповіді
                    Task {
                        let params: [String: Any] = ["logoUrl": url]
                        do {
                            _ = try await coffeeShopRepository.updateCoffeeShop(id: coffeeShopId, params: params)
                        } catch {
                            print("Некритична помилка при оновленні даних кав'ярні: \(error)")
                        }
                    }
                    
                    // Показуємо повідомлення про успіх
                    showSuccessMessage("Логотип успішно скинуто!")
                    isLoading = false
                    
                    // Не закриваємо екран після видалення логотипу
                    return url
                }
            }
            
            throw NSError(domain: "CoffeeShopViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Не вдалося обробити відповідь сервера"])
        } catch let apiError as APIError {
            let errorMessage = "Помилка скидання логотипу: \(apiError.localizedDescription)"
            print(errorMessage)
            handleError(apiError)
            isLoading = false
            throw apiError
        } catch {
            let errorMessage = "Невідома помилка: \(error.localizedDescription)"
            print(errorMessage)
            self.error = error.localizedDescription
            isLoading = false
            throw error
        }
    }
    
  
    
    func validateImage(_ image: UIImage) -> (isValid: Bool, error: String?) {
        // Перевірка розміру зображення (не більше 5 МБ)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return (false, "Не вдалося обробити зображення")
        }
        
        // Перевірка розміру (5 МБ = 5 * 1024 * 1024 байт)
        let maxSize = 5 * 1024 * 1024
        if imageData.count > maxSize {
            return (false, "Розмір зображення не може перевищувати 5 МБ")
        }
        
        // Тут можна додати перевірку на формат, але JPEG/PNG вже забезпечується
        // використанням UIImage.jpegData або UIImage.pngData
        
        return (true, nil)
    }
    
    
    @MainActor
    func refreshCoffeeShopData(id: String) async {
        do {
            // Отримуємо оновлені дані кав'ярні
            let updatedCoffeeShop = try await coffeeShopRepository.getCoffeeShopById(id: id)
            
            // Оновлюємо кав'ярню в списках
            if let index = coffeeShops.firstIndex(where: { $0.id == id }) {
                coffeeShops[index] = updatedCoffeeShop
            }
            
            if let index = myCoffeeShops.firstIndex(where: { $0.id == id }) {
                myCoffeeShops[index] = updatedCoffeeShop
            }
            
            // Оновлюємо вибрану кав'ярню, якщо вона відповідає оновленій
            if selectedCoffeeShop?.id == id {
                selectedCoffeeShop = updatedCoffeeShop
            }
        } catch {
            print("Помилка оновлення даних кав'ярні: \(error)")
        }
    }
    
    // MARK: - Робочі години
    
    @MainActor
    func updateWorkingHours(coffeeShopId: String, workingHours: [String: WorkingHoursPeriod]) async {
        isLoading = true
        error = nil
        
        do {
            // Валідуємо години роботи перед відправкою
            let model = WorkingHoursModel(hours: workingHours)
            let (isValid, errorMessage) = model.validate()
            
            if !isValid {
                error = errorMessage ?? "Невірний формат робочих годин"
                isLoading = false
                return
            }
            
            // Оновлюємо робочі години кав'ярні
            let params: [String: Any] = ["workingHours": workingHours]
            await updateCoffeeShop(id: coffeeShopId, params: params)
            
            showSuccess = true
            successMessage = "Робочі години успішно оновлено!"
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // Допоміжний метод для швидкого копіювання робочих годин з іншої кав'ярні
    @MainActor
    func copyWorkingHours(from sourceCoffeeShopId: String, to targetCoffeeShopId: String) async {
        isLoading = true
        error = nil
        
        do {
            // Отримуємо вихідну кав'ярню
            let sourceCoffeeShop = try await coffeeShopRepository.getCoffeeShopById(id: sourceCoffeeShopId)
            
            // Перевіряємо, чи є робочі години у вихідної кав'ярні
            if let workingHours = sourceCoffeeShop.workingHours, !workingHours.isEmpty {
                // Оновлюємо цільову кав'ярню з робочими годинами вихідної
                let params: [String: Any] = ["workingHours": workingHours]
                await updateCoffeeShop(id: targetCoffeeShopId, params: params)
                
                showSuccess = true
                successMessage = "Робочі години успішно скопійовано!"
            } else {
                error = "У вихідній кав'ярні немає робочих годин для копіювання"
            }
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // Метод для призначення власника кав'ярні (тільки для Super Admin)
    @MainActor
    func assignOwner(coffeeShopId: String, userId: String) async {
        isLoading = true
        error = nil
        
        // Перевіряємо, чи є користувач Super Admin
        if !isSuperAdmin() {
            error = "Тільки адміністратори можуть призначати власників кав'ярень"
            isLoading = false
            return
        }
        
        do {
            // Викликаємо API для призначення власника
            let updatedCoffeeShop = try await coffeeShopRepository.assignOwner(coffeeShopId: coffeeShopId, userId: userId)
            
            // Оновлюємо кав'ярню в списках
            if let index = coffeeShops.firstIndex(where: { $0.id == coffeeShopId }) {
                coffeeShops[index] = updatedCoffeeShop
            }
            
            if let index = myCoffeeShops.firstIndex(where: { $0.id == coffeeShopId }) {
                myCoffeeShops[index] = updatedCoffeeShop
            }
            
            // Оновлюємо вибрану кав'ярню, якщо вона відповідає оновленій
            if selectedCoffeeShop?.id == coffeeShopId {
                selectedCoffeeShop = updatedCoffeeShop
            }
            
            showSuccess = true
            successMessage = "Власника кав'ярні \"\(updatedCoffeeShop.name)\" успішно призначено!"
            
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func showSuccessMessage(_ message: String) {
        self.successMessage = message
        self.showSuccess = true
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
    }
}
