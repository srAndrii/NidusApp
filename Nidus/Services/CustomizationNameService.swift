import Foundation

// Сервіс для отримання назв інгредієнтів та опцій
class CustomizationNameService {
    static let shared = CustomizationNameService()
    
    private var ingredientNames: [String: String] = [:]
    private var optionNames: [String: String] = [:]
    private let networkService = NetworkService.shared
    private let queue = DispatchQueue(label: "com.nidus.customization.names", attributes: .concurrent)
    
    private init() {}
    
    // MARK: - Public Methods
    
    func getIngredientName(for id: String) -> String? {
        return queue.sync {
            return ingredientNames[id]
        }
    }
    
    func getOptionName(for id: String) -> String? {
        return queue.sync {
            return optionNames[id]
        }
    }
    
    // Завантажуємо назви з кав'ярні (виправлений метод)
    func loadNamesFromCoffeeShop(_ coffeeShopId: String) async {
        do {
            // Логування завантаження видалено для production
            
            // API повертає масив категорій з повною інформацією про товари
            struct MenuCategory: Codable {
                let id: String
                let name: String
                let menuItems: [MenuItemDetail]
            }
            
            struct MenuItemDetail: Codable {
                let id: String
                let name: String
                let price: String
                let description: String?
                let imageUrl: String?
                let isAvailable: Bool
                let ingredients: [IngredientInfo]?
                let customizationOptions: [CustomizationOptionGroup]?
                let sizes: [SizeInfo]?
                let hasMultipleSizes: Bool
            }
            
            struct IngredientInfo: Codable {
                let id: String
                let name: String
                let amount: Int
                let minAmount: Int
                let maxAmount: Int
                let unit: String
                let pricePerUnit: Double
                let freeAmount: Int
                let isCustomizable: Bool
            }
            
            struct CustomizationOptionGroup: Codable {
                let id: String
                let name: String
                let required: Bool
                let allowMultipleChoices: Bool
                let choices: [CustomizationChoice]
            }
            
            struct CustomizationChoice: Codable {
                let id: String
                let name: String
                let price: Double?
                let minQuantity: Int
                let maxQuantity: Int
                let defaultQuantity: Int
                let allowQuantity: Bool
                let pricePerAdditionalUnit: Double?
            }
            
            struct SizeInfo: Codable {
                let id: String
                let name: String
                let additionalPrice: Double
                let abbreviation: String
                let isDefault: Bool
                let order: Int
            }
            
            let categories: [MenuCategory] = try await networkService.fetch(endpoint: "/coffee-shops/\(coffeeShopId)/menu")
            
            // Логування успішного завантаження видалено для production
            
            // Обробляємо всі товари з усіх категорій
            queue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                
                var ingredientCount = 0
                var optionCount = 0
                
                for category in categories {
                    // Логування обробки категорій видалено для production
                    
                    for item in category.menuItems {
                        // Зберігаємо назви інгредієнтів
                        if let ingredients = item.ingredients {
                            for ingredient in ingredients {
                                self.ingredientNames[ingredient.id] = ingredient.name
                                ingredientCount += 1
                                // Логування збереження видалено для production
                            }
                        }
                        
                        // Зберігаємо назви опцій
                        if let optionGroups = item.customizationOptions {
                            for group in optionGroups {
                                for choice in group.choices {
                                    self.optionNames[choice.id] = choice.name
                                    optionCount += 1
                                    // Логування збереження видалено для production
                                }
                            }
                        }
                        
                        // Зберігаємо назви розмірів як опції
                        if let sizes = item.sizes {
                            for size in sizes {
                                self.optionNames[size.id] = size.name
                                optionCount += 1
                                // Логування збереження видалено для production
                            }
                        }
                    }
                }
                
                // Логування підсумку видалено для production
            }
            
        } catch {
            print("❌ CustomizationNameService: Помилка завантаження меню кав'ярні \(coffeeShopId): \(error)")
        }
    }
    
    // Очищуємо кеш
    func clearCache() {
        queue.async(flags: .barrier) { [weak self] in
            self?.ingredientNames.removeAll()
            self?.optionNames.removeAll()
        }
    }
    
    // Додаємо назви з існуючих даних замовлення
    func extractNamesFromOrder(_ order: OrderHistory) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            var extractedIngredients = 0
            var extractedOptions = 0
            
            for item in order.items {
                if let customization = item.customization {
                    // Витягуємо назви з selectedOptions
                    if let options = customization.selectedOptions {
                        for (_, choices) in options {
                            for choice in choices {
                                if let name = choice.name {
                                    self.optionNames[choice.id] = name
                                    extractedOptions += 1
                                    // Логування видалено для production
                                }
                            }
                        }
                    }
                    
                    // Витягуємо назви з customizationDetails
                    if let details = customization.customizationDetails {
                        if let size = details.size {
                            // Розмір зберігаємо як опцію
                            // Логування видалено для production
                        }
                        
                        if let options = details.options {
                            for option in options {
                                // Логування видалено для production
                            }
                        }
                    }
                }
                
                // Витягуємо назви з item.customizationDetails
                if let details = item.customizationDetails {
                    if let size = details.size {
                        // Логування видалено для production
                    }
                    
                    if let options = details.options {
                        for option in options {
                            // Логування видалено для production
                        }
                    }
                }
            }
            
            // Логування витягнутих даних видалено для production
        }
    }
} 