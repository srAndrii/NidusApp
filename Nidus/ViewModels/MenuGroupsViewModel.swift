//
//  MenuGroupsViewModel.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/2/25.
//

iimport Foundation

class MenuGroupsViewModel: ObservableObject {
    @Published var menuGroups: [MenuGroup] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showSuccess = false
    @Published var successMessage = ""
    
    private let repository = DIContainer.shared.menuGroupRepository
    
    @MainActor
    func loadMenuGroups(coffeeShopId: String) async {
        isLoading = true
        error = nil
        
        do {
            menuGroups = try await repository.getMenuGroups(coffeeShopId: coffeeShopId)
            // Сортування за порядком відображення
            menuGroups.sort { $0.displayOrder < $1.displayOrder }
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
            print("Помилка завантаження груп меню: \(error)")
        }
        
        isLoading = false
    }
    
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
    
    private func handleError(_ apiError: APIError) {
        switch apiError {
        case .serverError(_, let message):
            self.error = message ?? "Невідома помилка сервера"
        case .unauthorized:
            self.error = "Необхідна авторизація для виконання цієї дії"
        case .decodingFailed(let decodingError):
            self.error = "Помилка обробки даних: \(decodingError.localizedDescription)"
            print("Деталі помилки декодування: \(decodingError)")
        default:
            self.error = apiError.localizedDescription
        }
    }
    
    func showSuccessMessage(_ message: String) {
        self.successMessage = message
        self.showSuccess = true
    }
}
