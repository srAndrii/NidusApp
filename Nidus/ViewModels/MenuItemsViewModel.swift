//
//  MenuItemsViewModel.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/2/25.
//

import Foundation

class MenuItemsViewModel: ObservableObject {
    @Published var menuItems: [MenuItem] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showSuccess = false
    @Published var successMessage = ""
    
    private let repository = DIContainer.shared.menuItemRepository
    
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
    
    @MainActor
    func createMenuItem(groupId: String, name: String, price: Decimal, description: String?, isAvailable: Bool) async {
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
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
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
    
    
    @MainActor
    func updateMenuItemAvailability(groupId: String, itemId: String, available: Bool) async {
        do {
            print("Оновлюємо доступність для \(itemId) на \(available)")
            
            // Спрощене оновлення через загальний метод
            let updates: [String: Any] = ["isAvailable": available]
            
            // Оновлюємо локальний стан для миттєвої реакції інтерфейсу
            if let index = menuItems.firstIndex(where: { $0.id == itemId }) {
                menuItems[index].isAvailable = available
            }
            
            // Очищаємо попередню помилку
            self.error = nil
            
            // Виконуємо запит
            let updatedItem = try await repository.updateMenuItem(groupId: groupId, itemId: itemId, updates: updates)
            
            // Ще раз оновлюємо локальний стан з даними з сервера
            if let index = menuItems.firstIndex(where: { $0.id == itemId }) {
                menuItems[index] = updatedItem
            }
            
            showSuccessMessage("Доступність пункту меню оновлено!")
        } catch {
            print("Помилка при оновленні доступності: \(error)")
            self.error = "Помилка оновлення: \(error.localizedDescription)"
            
            // Перезавантажуємо дані, щоб відновити правильний стан
            await loadMenuItems(groupId: groupId)
        }
    }
    
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
    
    func showSuccessMessage(_ message: String) {
        self.successMessage = message
        self.showSuccess = true
    }
}
