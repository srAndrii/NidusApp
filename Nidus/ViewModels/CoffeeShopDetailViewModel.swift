//
//  CoffeeShopDetailViewModel.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/6/25.
//

import Foundation
import Combine

class CoffeeShopDetailViewModel: ObservableObject {
    // MARK: - Опубліковані властивості
    
    @Published var menuGroups: [MenuGroup] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Залежності та властивості
    
    private let coffeeShopRepository: CoffeeShopRepositoryProtocol
    
    // MARK: - Ініціалізація
    
    init(coffeeShopRepository: CoffeeShopRepositoryProtocol = DIContainer.shared.coffeeShopRepository) {
        self.coffeeShopRepository = coffeeShopRepository
    }
    
    // MARK: - Методи для завантаження даних
    
    /// Завантаження груп меню для кав'ярні
    @MainActor
    func loadMenuGroups(coffeeShopId: String) {
        isLoading = true
        error = nil
        
        Task {
            do {
                // Отримуємо меню кав'ярні з репозиторію
                let menu = try await coffeeShopRepository.getCoffeeShopMenu(id: coffeeShopId)
                
                // Оновлюємо список груп меню
                menuGroups = menu
                
                // Сортуємо групи за порядком відображення
                menuGroups.sort(by: { $0.displayOrder < $1.displayOrder })
                
            } catch let apiError as APIError {
                handleError(apiError)
            } catch {
                self.error = error.localizedDescription
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Допоміжні методи
    
    /// Обробка помилок API
    private func handleError(_ apiError: APIError) {
        switch apiError {
        case .serverError(_, let message):
            self.error = message ?? "Невідома помилка сервера"
        case .unauthorized:
            self.error = "Необхідна авторизація для перегляду меню"
        default:
            self.error = apiError.localizedDescription
        }
    }
    
    /// Перевірка, чи пункт меню у вибраній категорії
    func isMenuItemInCategory(itemId: String, categoryId: String) -> Bool {
        if let category = menuGroups.first(where: { $0.id == categoryId }),
           let menuItems = category.menuItems {
            return menuItems.contains(where: { $0.id == itemId })
        }
        return false
    }
    
    /// Отримання пункту меню за ID
    func getMenuItem(itemId: String) -> MenuItem? {
        for group in menuGroups {
            if let items = group.menuItems,
               let item = items.first(where: { $0.id == itemId }) {
                return item
            }
        }
        return nil
    }
}
