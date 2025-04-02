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
            menuItems = try await repository.getMenuItems(groupId: groupId)
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
