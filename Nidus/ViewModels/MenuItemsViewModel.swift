import Foundation

class MenuItemsViewModel: ObservableObject {
    // MARK: - Опубліковані властивості
    
    @Published var menuItems: [MenuItem] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Залежності та властивості
    
    private let repository = DIContainer.shared.menuItemRepository
    
    // MARK: - Клієнтські методи для роботи з пунктами меню
    
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
    
    /// Отримання деталей пункту меню
    @MainActor
    func loadMenuItemDetails(groupId: String, itemId: String) async {
        isLoading = true
        error = nil
        
        do {
            let item = try await repository.getMenuItem(groupId: groupId, itemId: itemId)
            
            // Оновлюємо пункт меню в списку, якщо він там є
            if let index = menuItems.firstIndex(where: { $0.id == itemId }) {
                menuItems[index] = item
            } else {
                // Додаємо до списку, якщо його там немає
                menuItems.append(item)
            }
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Фільтрація пунктів меню за ціною
    @MainActor
    func filterMenuItems(groupId: String, minPrice: Double?, maxPrice: Double?) async {
        isLoading = true
        error = nil
        
        do {
            menuItems = try await repository.getFilteredMenuItems(groupId: groupId, minPrice: minPrice, maxPrice: maxPrice)
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Допоміжні методи
    
    private func handleError(_ apiError: APIError) {
        switch apiError {
        case .serverError(_, let message):
            self.error = message ?? "Невідома помилка сервера"
        case .simpleServerError(message: let message):
            self.error = message
        case .unauthorized:
            self.error = "Необхідна авторизація для перегляду пунктів меню"
        default:
            self.error = apiError.localizedDescription
        }
    }
}
