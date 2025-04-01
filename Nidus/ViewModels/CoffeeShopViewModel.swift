// ViewModels/CoffeeShopViewModel.swift
import Foundation
import Combine

class CoffeeShopViewModel: ObservableObject {
    @Published var coffeeShops: [CoffeeShop] = []
    @Published var myCoffeeShops: [CoffeeShop] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var selectedCoffeeShop: CoffeeShop?
    @Published var showSuccess: Bool = false
    @Published var successMessage: String = ""
    
    private let coffeeShopRepository: CoffeeShopRepositoryProtocol
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
