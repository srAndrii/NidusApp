import Foundation

// Сервіс для отримання назв інгредієнтів та опцій
class CustomizationNameService {
    static let shared = CustomizationNameService()
    
    private var ingredientNames: [String: String] = [:]
    private var optionNames: [String: String] = [:]
    private let networkService = NetworkService.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    func getIngredientName(for id: String) -> String? {
        return ingredientNames[id]
    }
    
    func getOptionName(for id: String) -> String? {
        return optionNames[id]
    }
    
    // Завантажуємо назви інгредієнтів для конкретного товару
    func loadIngredientNames(for menuItemId: String) async {
        do {
            print("🔍 CustomizationNameService: Завантажуємо інгредієнти для товару \(menuItemId)")
            
            // Спробуємо отримати інформацію про товар з меню
            struct MenuItemDetail: Codable {
                let id: String
                let name: String
                let ingredients: [IngredientInfo]?
                let customizationOptions: [CustomizationOptionGroup]?
            }
            
            struct IngredientInfo: Codable {
                let id: String
                let name: String
                let price: Double?
            }
            
            struct CustomizationOptionGroup: Codable {
                let id: String
                let name: String
                let choices: [CustomizationChoice]?
            }
            
            struct CustomizationChoice: Codable {
                let id: String
                let name: String
                let additionalPrice: Double?
            }
            
            let menuItem: MenuItemDetail = try await networkService.fetch(endpoint: "/menu/items/\(menuItemId)")
            
            // Зберігаємо назви інгредієнтів
            if let ingredients = menuItem.ingredients {
                for ingredient in ingredients {
                    ingredientNames[ingredient.id] = ingredient.name
                    print("📝 Збережено інгредієнт: \(ingredient.id) -> \(ingredient.name)")
                }
            }
            
            // Зберігаємо назви опцій
            if let optionGroups = menuItem.customizationOptions {
                for group in optionGroups {
                    if let choices = group.choices {
                        for choice in choices {
                            optionNames[choice.id] = choice.name
                            print("📝 Збережено опцію: \(choice.id) -> \(choice.name)")
                        }
                    }
                }
            }
            
        } catch {
            print("❌ CustomizationNameService: Помилка завантаження назв для \(menuItemId): \(error)")
        }
    }
    
    // Завантажуємо назви з кав'ярні
    func loadNamesFromCoffeeShop(_ coffeeShopId: String) async {
        do {
            print("🔍 CustomizationNameService: Завантажуємо меню кав'ярні \(coffeeShopId)")
            
            // API повертає масив категорій, а не об'єкт з items
            struct MenuCategory: Codable {
                let id: String
                let name: String
                let menuItems: [MenuItemSummary]
            }
            
            struct MenuItemSummary: Codable {
                let id: String
                let name: String
            }
            
            let categories: [MenuCategory] = try await networkService.fetch(endpoint: "/coffee-shops/\(coffeeShopId)/menu")
            
            // Завантажуємо деталі для кожного товару з усіх категорій
            for category in categories {
                for item in category.menuItems {
                    await loadIngredientNames(for: item.id)
                }
            }
            
        } catch {
            print("❌ CustomizationNameService: Помилка завантаження меню кав'ярні \(coffeeShopId): \(error)")
        }
    }
    
    // Очищуємо кеш
    func clearCache() {
        ingredientNames.removeAll()
        optionNames.removeAll()
    }
    
    // Додаємо назви з існуючих даних замовлення
    func extractNamesFromOrder(_ order: OrderHistory) {
        for item in order.items {
            if let customization = item.customization {
                // Витягуємо назви з selectedOptions
                if let options = customization.selectedOptions {
                    for (_, choices) in options {
                        for choice in choices {
                            if let name = choice.name {
                                optionNames[choice.id] = name
                                print("📝 Витягнуто назву опції з замовлення: \(choice.id) -> \(name)")
                            }
                        }
                    }
                }
            }
        }
    }
} 