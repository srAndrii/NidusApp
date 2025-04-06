import Foundation

class MenuItemsViewModel: ObservableObject {
    // MARK: - Опубліковані властивості
    
    @Published var menuItems: [MenuItem] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showSuccess = false
    @Published var successMessage = ""
    
    // MARK: - Залежності та властивості
    
    private let repository = DIContainer.shared.menuItemRepository
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService.shared) {
        self.networkService = networkService
    }
    
    // MARK: - Користувацькі методи для роботи з пунктами меню
    
    /// Завантаження всіх пунктів меню для групи
    @MainActor
    func loadMenuItems(groupId: String) async {
        isLoading = true
        error = nil
        
        do {
            print("Запит пунктів меню для групи: \(groupId)")
            menuItems = try await repository.getMenuItems(groupId: groupId)
            print("Отримано \(menuItems.count) пунктів меню")
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Адміністративні методи для роботи з пунктами меню
    
    /// Створення нового пункту меню
    @MainActor
    func createMenuItem(groupId: String, name: String, price: Decimal, description: String?, isAvailable: Bool) async throws -> MenuItem {
        isLoading = true
        error = nil
        
        do {
            // Створюємо запит з необхідними даними
            let createRequest = CreateMenuItemRequest(
                name: name,
                price: price,
                description: description,
                isAvailable: isAvailable,
                ingredients: nil,
                customizationOptions: nil,
                menuGroupId: groupId  // Встановлюємо groupId
            )
            
            // Створюємо пункт меню через репозиторій
            let newItem = try await repository.createMenuItem(groupId: groupId, item: createRequest)
            
            // Додаємо новий пункт до списку
            menuItems.append(newItem)
            
            // Показуємо повідомлення про успіх
            showSuccessMessage("Пункт меню \"\(name)\" успішно створено!")
            
            isLoading = false
            return newItem
        } catch let apiError as APIError {
            handleError(apiError)
            isLoading = false
            throw apiError
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            throw error
        }
    }
    
    /// Завантаження зображення для пункту меню
    @MainActor
    func uploadMenuItemImage(groupId: String, itemId: String, imageRequest: ImageUploadRequest) async throws {
        do {
            // Виправлений endpoint
            let endpoint = "/upload/menu-item/\(itemId)/image"
            let uploadResponse: UploadResponse = try await networkService.uploadFile(
                endpoint: endpoint,
                data: imageRequest.imageData,
                fieldName: "file",
                fileName: imageRequest.fileName,
                mimeType: imageRequest.mimeType
            )
            
            // Оновлюємо локальний список пунктів меню
            if let index = menuItems.firstIndex(where: { $0.id == itemId }) {
                menuItems[index].imageUrl = uploadResponse.url
            }
            
            // Показуємо повідомлення про успіх
            showSuccessMessage("Зображення успішно додано!")
        } catch {
            // Обробка помилки завантаження
            print("Помилка завантаження зображення: \(error)")
            self.error = "Не вдалося завантажити зображення: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// Видалення пункту меню
    @MainActor
    func deleteMenuItem(groupId: String, itemId: String) async {
        isLoading = true
        error = nil
        
        do {
            // Викликаємо репозиторій для видалення пункту меню
            try await repository.deleteMenuItem(groupId: groupId, itemId: itemId)
            
            // Видаляємо пункт меню з локального списку
            menuItems.removeAll { $0.id == itemId }
            
            showSuccessMessage("Пункт меню успішно видалено!")
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Оновлення доступності пункту меню
    @MainActor
    func updateMenuItemAvailability(groupId: String, itemId: String, available: Bool) async {
        do {
            print("Оновлюємо доступність для \(itemId) на \(available)")
            
            // Оновлюємо локальний стан для миттєвої реакції інтерфейсу
            if let index = menuItems.firstIndex(where: { $0.id == itemId }) {
                menuItems[index].isAvailable = available
            }
            
            // Очищаємо попередню помилку
            self.error = nil
            
            // Виконуємо запит
            let updatedItem = try await repository.updateMenuItem(
                groupId: groupId,
                itemId: itemId,
                updates: ["isAvailable": available]
            )
            
            // Оновлюємо локальний стан з даними з сервера
            if let index = menuItems.firstIndex(where: { $0.id == itemId }) {
                menuItems[index] = updatedItem
            }
            
            showSuccessMessage("Доступність пункту меню оновлено!")
        } catch {
            print("Помилка при оновленні доступності: \(error)")
            self.error = "Помилка оновлення: \(error.localizedDescription)"
            
            // Перезавантаження даних, щоб відновити правильний стан
            await loadMenuItems(groupId: groupId)
        }
    }
    
    // MARK: - Допоміжні методи
    
    /// Показ повідомлення про успіх
    func showSuccessMessage(_ message: String) {
        successMessage = message
        showSuccess = true
    }
    
    /// Обробка помилок API
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
