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
    
    // MARK: - Допоміжні методи
    
    /// Показати повідомлення про успіх
    func showSuccessMessage(_ message: String) {
        successMessage = message
        showSuccess = true
    }
    
    /// Обробка помилок API
    private func handleError(_ apiError: APIError) {
        switch apiError {
        case .serverError(_, let message):
            self.error = message ?? "Невідома помилка сервера"
        case .simpleServerError(message: let message):
            self.error = message
        case .unauthorized:
            self.error = "Необхідна авторизація для перегляду меню"
        default:
            self.error = apiError.localizedDescription
        }
    }
}
