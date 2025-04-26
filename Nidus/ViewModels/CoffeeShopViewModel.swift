import Foundation
import Combine
import UIKit

class CoffeeShopViewModel: ObservableObject {
    // MARK: - Опубліковані властивості
    
    @Published var coffeeShops: [CoffeeShop] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var selectedCoffeeShop: CoffeeShop?
    
    // MARK: - Залежності та властивості
    
    private let coffeeShopRepository: CoffeeShopRepositoryProtocol
    
    // MARK: - Ініціалізація
    
    init(coffeeShopRepository: CoffeeShopRepositoryProtocol = DIContainer.shared.coffeeShopRepository) {
        self.coffeeShopRepository = coffeeShopRepository
    }
    
    // MARK: - Користувацькі методи завантаження даних
    
    /// Завантаження всіх кав'ярень для користувачів
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
    
    /// Пошук кав'ярень за адресою
    @MainActor
    func searchCoffeeShops(address: String) async {
        isLoading = true
        error = nil
        
        do {
            if address.isEmpty {
                // Якщо запит порожній, завантажуємо всі кав'ярні
                await loadCoffeeShops()
            } else {
                // Інакше виконуємо пошук за адресою
                coffeeShops = try await coffeeShopRepository.searchCoffeeShops(address: address)
            }
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Отримання деталей кав'ярні за ID
    @MainActor
    func getCoffeeShopDetails(id: String) async {
        isLoading = true
        error = nil
        
        do {
            let coffeeShop = try await coffeeShopRepository.getCoffeeShopById(id: id)
            selectedCoffeeShop = coffeeShop
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Допоміжні методи
    
    /// Обробка помилок API
    private func handleError(_ apiError: APIError) {
        switch apiError {
        case .serverError(_, let message):
            self.error = message ?? "Невідома помилка сервера"
        case .simpleServerError(message: let message):
            self.error = message
        case .unauthorized:
            self.error = "Необхідна авторизація для перегляду кав'ярень"
        default:
            self.error = apiError.localizedDescription
        }
    }
}
