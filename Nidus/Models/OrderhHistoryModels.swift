import Foundation

// MARK: - Order History Models

// Основна модель замовлення для історії
struct OrderHistory: Codable, Identifiable {
    let id: String
    let orderNumber: String
    let status: OrderStatus
    let totalAmount: Double
    let coffeeShopId: String
    let coffeeShopName: String?
    let coffeeShop: CoffeeShopInfo?
    let isPaid: Bool
    let createdAt: String
    let completedAt: String?
    let items: [OrderHistoryItem]
    let statusHistory: [OrderStatusHistoryItem]
    let payment: OrderPaymentInfo?
    
    // MARK: - Initializers
    
    // Звичайний ініціалізатор для програмного створення
    init(
        id: String,
        orderNumber: String,
        status: OrderStatus,
        totalAmount: Double,
        coffeeShopId: String,
        coffeeShopName: String?,
        coffeeShop: CoffeeShopInfo? = nil,
        isPaid: Bool,
        createdAt: String,
        completedAt: String?,
        items: [OrderHistoryItem],
        statusHistory: [OrderStatusHistoryItem],
        payment: OrderPaymentInfo?
    ) {
        self.id = id
        self.orderNumber = orderNumber
        self.status = status
        self.totalAmount = totalAmount
        self.coffeeShopId = coffeeShopId
        self.coffeeShopName = coffeeShopName
        self.coffeeShop = coffeeShop
        self.isPaid = isPaid
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.items = items
        self.statusHistory = statusHistory
        self.payment = payment
    }
    
    // MARK: - Custom Decoding
    enum CodingKeys: String, CodingKey {
        case id, orderNumber, status, totalAmount, coffeeShopId, coffeeShopName, coffeeShop, isPaid, createdAt, completedAt, items, statusHistory, payment
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        orderNumber = try container.decode(String.self, forKey: .orderNumber)
        status = try container.decode(OrderStatus.self, forKey: .status)
        coffeeShopId = try container.decode(String.self, forKey: .coffeeShopId)
        coffeeShopName = try container.decodeIfPresent(String.self, forKey: .coffeeShopName)
        coffeeShop = try container.decodeIfPresent(CoffeeShopInfo.self, forKey: .coffeeShop)
        isPaid = try container.decode(Bool.self, forKey: .isPaid)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        completedAt = try container.decodeIfPresent(String.self, forKey: .completedAt)
        items = try container.decode([OrderHistoryItem].self, forKey: .items)
        statusHistory = try container.decode([OrderStatusHistoryItem].self, forKey: .statusHistory)
        payment = try container.decodeIfPresent(OrderPaymentInfo.self, forKey: .payment)
        
        // Обробляємо totalAmount як рядок або число
        if let totalAmountString = try? container.decode(String.self, forKey: .totalAmount) {
            totalAmount = Double(totalAmountString) ?? 0.0
            print("🔧 OrderHistory: Декодовано totalAmount з рядка '\(totalAmountString)' -> \(totalAmount)")
        } else {
            totalAmount = try container.decode(Double.self, forKey: .totalAmount)
            print("🔧 OrderHistory: Декодовано totalAmount як число -> \(totalAmount)")
        }
    }
}

// MARK: - Extensions for OrderHistory

extension OrderHistory {
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "d MMMM yyyy, HH:mm"
        
        if let date = ISO8601DateFormatter().date(from: createdAt) {
            return formatter.string(from: date)
        }
        
        // Резервний варіант - спробуємо з іншими форматами
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Formatter.date(from: createdAt) {
            return formatter.string(from: date)
        }
        
        // Якщо не вдалося розпарсити, повертаємо оригінальний рядок
        return createdAt
    }
    
    var statusDisplayName: String {
        return status.displayName
    }
    
    var statusColor: String {
        return status.color
    }
    
    var displayCoffeeShopName: String {
        // Спочатку пробуємо отримати назву з об'єкта coffeeShop
        if let coffeeShop = coffeeShop {
            return coffeeShop.name
        }
        // Якщо немає, використовуємо coffeeShopName
        if let name = coffeeShopName {
            return name
        }
        // Якщо і це немає, пробуємо кеш безпечно
        do {
            if let cachedName = CoffeeShopCache.shared.getCoffeeShopName(for: coffeeShopId) {
                return cachedName
            }
        } catch {
            print("⚠️ OrderHistory: Помилка доступу до кешу кав'ярень: \(error)")
        }
        return "Невідома кав'ярня"
    }
}

// MARK: - Order History Item

struct OrderHistoryItem: Codable, Identifiable {
    let id: String
    let name: String
    let price: Double
    let basePrice: Double
    let finalPrice: Double
    let quantity: Int
    let customization: OrderItemCustomization?
    let customizationSummary: String?
    let customizationDetails: CustomizationDetails?
    let sizeName: String?
    let sizeAdditionalPrice: Double?
    
    // MARK: - Initializers
    
    // Звичайний ініціалізатор для програмного створення
    init(
        id: String,
        name: String,
        price: Double,
        basePrice: Double,
        finalPrice: Double,
        quantity: Int,
        customization: OrderItemCustomization?,
        customizationSummary: String? = nil,
        customizationDetails: CustomizationDetails? = nil,
        sizeName: String?,
        sizeAdditionalPrice: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.basePrice = basePrice
        self.finalPrice = finalPrice
        self.quantity = quantity
        self.customization = customization
        self.customizationSummary = customizationSummary
        self.customizationDetails = customizationDetails
        self.sizeName = sizeName
        self.sizeAdditionalPrice = sizeAdditionalPrice
    }
    
    // MARK: - Custom Decoding
    enum CodingKeys: String, CodingKey {
        case id, name, price, basePrice, finalPrice, quantity, customization, customizationSummary, customizationDetails, sizeName, sizeAdditionalPrice
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        quantity = try container.decode(Int.self, forKey: .quantity)
        customization = try container.decodeIfPresent(OrderItemCustomization.self, forKey: .customization)
        customizationSummary = try container.decodeIfPresent(String.self, forKey: .customizationSummary)
        customizationDetails = try container.decodeIfPresent(CustomizationDetails.self, forKey: .customizationDetails)
        sizeName = try container.decodeIfPresent(String.self, forKey: .sizeName)
        
        // Обробляємо sizeAdditionalPrice як рядок або число
        if let sizeAdditionalPriceString = try? container.decode(String.self, forKey: .sizeAdditionalPrice) {
            sizeAdditionalPrice = Double(sizeAdditionalPriceString)
        } else {
            sizeAdditionalPrice = try container.decodeIfPresent(Double.self, forKey: .sizeAdditionalPrice)
        }
        
        // Обробляємо price як рядок або число
        if let priceString = try? container.decode(String.self, forKey: .price) {
            price = Double(priceString) ?? 0.0
        } else {
            price = try container.decode(Double.self, forKey: .price)
        }
        
        // Обробляємо basePrice як рядок або число
        if let basePriceString = try? container.decode(String.self, forKey: .basePrice) {
            basePrice = Double(basePriceString) ?? 0.0
        } else {
            basePrice = try container.decode(Double.self, forKey: .basePrice)
        }
        
        // Обробляємо finalPrice як рядок або число
        if let finalPriceString = try? container.decode(String.self, forKey: .finalPrice) {
            finalPrice = Double(finalPriceString) ?? 0.0
        } else {
            finalPrice = try container.decode(Double.self, forKey: .finalPrice)
        }
    }
}

// MARK: - Extensions for OrderHistoryItem

extension OrderHistoryItem {
    var totalPrice: String {
        return String(format: "%.2f ₴", finalPrice * Double(quantity))
    }
    
    var formattedPrice: String {
        return String(format: "%.2f ₴", finalPrice)
    }
    
    var effectiveSizeAdditionalPrice: Double? {
        // Спочатку пробуємо використати sizeAdditionalPrice з API
        if let apiPrice = sizeAdditionalPrice {
            return apiPrice
        }
        
        // Якщо немає, пробуємо витягти з customization
        if let customization = customization,
           let sizeData = customization.selectedSizeData {
            return sizeData.additionalPrice
        }
        
        // Якщо немає, пробуємо витягти з customizationDetails
        if let details = customizationDetails,
           let size = details.size {
            return size.price
        }
        
        return nil
    }
    
    var displayCustomization: String? {
        if let customizationData = customizationDisplayData {
            return formatCustomizationDisplayData(customizationData)
        }
        
        // Резервний варіант - використовуємо customization об'єкт
        if let customization = customization, customization.hasCustomizations {
            print("🔍 OrderHistoryItem: Використовуємо customization.displayText")
            return customization.displayText
        }
        
        return nil
    }
    
    var customizationDisplayData: CustomizationDisplayData? {
        // Спочатку пробуємо використати customizationSummary на рівні item
        if let summary = customizationSummary, !summary.isEmpty {
            print("🔍 OrderHistoryItem: Використовуємо item.customizationSummary: \(summary)")
            return formatCustomizationSummary(summary)
        }
        
        // Потім пробуємо customizationDetails на рівні item
        if let details = customizationDetails {
            print("🔍 OrderHistoryItem: Формуємо з item.customizationDetails")
            return formatCustomizationDetailsToDisplayData(details)
        }
        
        return nil
    }
    
    private func formatCustomizationDisplayData(_ data: CustomizationDisplayData) -> String {
        var components: [String] = []
        
        // НЕ додаємо розмір, оскільки він вже показаний вище
        
        if !data.ingredients.isEmpty {
            components.append("Інгредієнти: \(data.ingredients.map { $0.displayText }.joined(separator: ", "))")
        }
        
        if !data.optionGroups.isEmpty {
            var optionStrings: [String] = []
            for (groupName, options) in data.optionGroups {
                let optionTexts = options.map { $0.displayText }.joined(separator: ", ")
                optionStrings.append("\(groupName): \(optionTexts)")
            }
            components.append("Опції: \(optionStrings.joined(separator: "; "))")
        }
        
        return components.joined(separator: "\n")
    }
    
    private func formatCustomizationDetailsToDisplayData(_ details: CustomizationDetails) -> CustomizationDisplayData {
        var ingredients: [IngredientDisplayItem] = []
        var optionGroups: [String: [OptionDisplayItem]] = [:]
        
        // НЕ обробляємо розмір, оскільки він вже показаний вище
        
        if let options = details.options, !options.isEmpty {
            for option in options {
                let optionItem = OptionDisplayItem(
                    name: option.name,
                    quantity: option.quantity ?? 1,
                    additionalPrice: option.totalPrice
                )
                
                // Групуємо опції за типом (припускаємо, що це загальні опції)
                if optionGroups["Додаткові опції"] == nil {
                    optionGroups["Додаткові опції"] = []
                }
                optionGroups["Додаткові опції"]?.append(optionItem)
            }
        }
        
        return CustomizationDisplayData(
            sizeInfo: nil, // НЕ включаємо розмір
            ingredients: ingredients,
            optionGroups: optionGroups
        )
    }
    
    private func formatCustomizationSummary(_ summary: String) -> CustomizationDisplayData {
        // Розбираємо summary та форматуємо його краще
        let parts = summary.components(separatedBy: " | ")
        
        var ingredients: [IngredientDisplayItem] = []
        var optionGroups: [String: [OptionDisplayItem]] = [:]
        
        for part in parts {
            let trimmedPart = part.trimmingCharacters(in: .whitespaces)
            
            if trimmedPart.hasPrefix("Розмір:") {
                // Пропускаємо розмір, оскільки він вже показаний вище
                continue
            } else if trimmedPart.hasPrefix("Інгредієнти:") {
                let ingredientsPart = String(trimmedPart.dropFirst("Інгредієнти:".count)).trimmingCharacters(in: .whitespaces)
                let ingredientItems = ingredientsPart.components(separatedBy: ", ")
                
                for item in ingredientItems {
                    if let ingredient = parseIngredientItem(item) {
                        ingredients.append(ingredient)
                    }
                }
            } else if trimmedPart.hasPrefix("Опції:") {
                let optionsPart = String(trimmedPart.dropFirst("Опції:".count)).trimmingCharacters(in: .whitespaces)
                let optionItems = optionsPart.components(separatedBy: "; ")
                
                for item in optionItems {
                    if let (groupName, option) = parseOptionItem(item) {
                        if optionGroups[groupName] == nil {
                            optionGroups[groupName] = []
                        }
                        optionGroups[groupName]?.append(option)
                    }
                }
            }
        }
        
        return CustomizationDisplayData(
            sizeInfo: nil, // НЕ включаємо розмір
            ingredients: ingredients,
            optionGroups: optionGroups
        )
    }
    
    private func parseIngredientItem(_ item: String) -> IngredientDisplayItem? {
        // Парсимо рядок типу "Еспресо : 5порція" 
        let components = item.components(separatedBy: " : ")
        guard components.count >= 2 else { return nil }
        
        let name = components[0].trimmingCharacters(in: .whitespaces)
        let quantityAndPrice = components[1].trimmingCharacters(in: .whitespaces)
        
        // Витягуємо кількість
        let quantityPattern = "\\d+"
        let quantityMatch = quantityAndPrice.range(of: quantityPattern, options: .regularExpression)
        guard let quantityRange = quantityMatch else { return nil }
        
        let quantityString = String(quantityAndPrice[quantityRange])
        guard let quantity = Int(quantityString) else { return nil }
        
        // Витягуємо одиницю виміру
        let unitStart = quantityAndPrice.index(quantityRange.upperBound, offsetBy: 0)
        let unit = String(quantityAndPrice[unitStart...]).trimmingCharacters(in: .whitespaces)
        
        // Обчислюємо додаткову вартість на основі кількості та правил
        let additionalPrice = calculateIngredientPrice(name: name, quantity: quantity)
        
        return IngredientDisplayItem(
            name: name,
            quantity: quantity,
            unit: unit,
            additionalPrice: additionalPrice
        )
    }
    
    private func calculateIngredientPrice(name: String, quantity: Int) -> Double {
        // Правила ціноутворення для різних інгредієнтів
        let freeQuantity = 2 // Перші 2 порції безкоштовні
        let paidQuantity = max(0, quantity - freeQuantity)
        
        // Ціна за одиницю для різних інгредієнтів
        let pricePerUnit: Double
        if name.lowercased().contains("еспресо") || name.lowercased().contains("espresso") {
            pricePerUnit = 3.0 // 3 ₴ за порцію еспресо
        } else if name.lowercased().contains("цукор") {
            pricePerUnit = 0.0 // Цукор безкоштовний
        } else {
            pricePerUnit = 1.0 // Інші інгредієнти по 1 ₴
        }
        
        return pricePerUnit * Double(paidQuantity)
    }
    
    private func parseOptionItem(_ item: String) -> (String, OptionDisplayItem)? {
        // Парсимо рядок типу "Тип молока: Соєве" або "Сироп: Карамель x6"
        let components = item.components(separatedBy: ": ")
        guard components.count >= 2 else { return nil }
        
        let groupName = components[0].trimmingCharacters(in: .whitespaces)
        let optionInfo = components[1].trimmingCharacters(in: .whitespaces)
        
        // Парсимо назву опції та кількість
        var optionName = optionInfo
        var quantity = 1
        
        // Витягуємо кількість (x6, x3 тощо)
        let quantityPattern = "x(\\d+)"
        if let quantityMatch = optionInfo.range(of: quantityPattern, options: .regularExpression) {
            let quantityString = String(optionInfo[quantityMatch])
            let numberPattern = "\\d+"
            let numberMatch = quantityString.range(of: numberPattern, options: .regularExpression)
            if let numberRange = numberMatch {
                quantity = Int(String(quantityString[numberRange])) ?? 1
            }
            optionName = String(optionInfo[..<quantityMatch.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        
        // Обчислюємо додаткову вартість на основі типу опції та кількості
        let additionalPrice = calculateOptionPrice(groupName: groupName, optionName: optionName, quantity: quantity)
        
        let option = OptionDisplayItem(
            name: optionName,
            quantity: quantity,
            additionalPrice: additionalPrice
        )
        
        return (groupName, option)
    }
    
    private func calculateOptionPrice(groupName: String, optionName: String, quantity: Int) -> Double {
        // Правила ціноутворення для різних типів опцій
        
        if groupName.lowercased().contains("тип молока") {
            // Альтернативне молоко коштує додатково
            if optionName.lowercased().contains("соєве") || 
               optionName.lowercased().contains("мигдальне") || 
               optionName.lowercased().contains("вівсяне") {
                return 3.0 // +3 ₴ за альтернативне молоко
            }
            return 0.0 // Звичайне молоко безкоштовне
        }
        
        if groupName.lowercased().contains("сироп") {
            // Для сиропів: перші 2 безкоштовні, решта по 1 ₴
            let freeQuantity = 2
            let paidQuantity = max(0, quantity - freeQuantity)
            return 1.0 * Double(paidQuantity) // 1 ₴ за кожну додаткову порцію сиропу
        }
        
        // Інші опції
        return 0.0
    }
    

    
    var hasCustomizations: Bool {
        return displayCustomization != nil
    }
}

// MARK: - Order Item Customization

struct OrderItemCustomization: Codable {
    let selectedIngredients: [String: Int]?
    let selectedOptions: [String: [OrderCustomizationChoice]]?
    let selectedSizeData: SelectedSizeData?
    let customizationDetails: CustomizationDetails?
    let customizationSummary: String?
    
    // Звичайний ініціалізатор для програмного створення
    init(
        selectedIngredients: [String: Int]? = nil,
        selectedOptions: [String: [OrderCustomizationChoice]]? = nil,
        selectedSizeData: SelectedSizeData? = nil,
        customizationDetails: CustomizationDetails? = nil,
        customizationSummary: String? = nil
    ) {
        self.selectedIngredients = selectedIngredients
        self.selectedOptions = selectedOptions
        self.selectedSizeData = selectedSizeData
        self.customizationDetails = customizationDetails
        self.customizationSummary = customizationSummary
    }
    
    // Кастомний декодер для гнучкої обробки різних форматів API
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        selectedIngredients = try container.decodeIfPresent([String: Int].self, forKey: .selectedIngredients)
        selectedOptions = try container.decodeIfPresent([String: [OrderCustomizationChoice]].self, forKey: .selectedOptions)
        selectedSizeData = try container.decodeIfPresent(SelectedSizeData.self, forKey: .selectedSizeData)
        customizationDetails = try container.decodeIfPresent(CustomizationDetails.self, forKey: .customizationDetails)
        customizationSummary = try container.decodeIfPresent(String.self, forKey: .customizationSummary)
    }
    
    enum CodingKeys: String, CodingKey {
        case selectedIngredients, selectedOptions, selectedSizeData, customizationDetails, customizationSummary
    }
}

// MARK: - Supporting Types

struct SelectedSizeData: Codable {
    let id: String
    let name: String?  // Зробимо опціональним
    let additionalPrice: Double
    
    // Кастомний декодер для обробки різних варіантів відповіді
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        
        // Обробляємо additionalPrice як рядок або число
        if let priceString = try? container.decode(String.self, forKey: .additionalPrice) {
            additionalPrice = Double(priceString) ?? 0.0
        } else {
            additionalPrice = try container.decode(Double.self, forKey: .additionalPrice)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, additionalPrice
    }
}

struct OrderCustomizationChoice: Codable {
    let id: String
    let name: String?
    let additionalPrice: Double?
    let quantity: Int?
    
    // Звичайний ініціалізатор для програмного створення
    init(id: String, name: String?, additionalPrice: Double?, quantity: Int? = nil) {
        self.id = id
        self.name = name
        self.additionalPrice = additionalPrice
        self.quantity = quantity
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "choiceId"
        case name
        case additionalPrice
        case quantity
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Пробуємо декодувати id з різних можливих ключів
        if let choiceId = try? container.decode(String.self, forKey: .id) {
            id = choiceId
        } else if let container = try? decoder.singleValueContainer(),
                  let directId = try? container.decode(String.self) {
            id = directId
        } else {
            throw DecodingError.keyNotFound(CodingKeys.id, DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Unable to find id or choiceId"
            ))
        }
        
        name = try container.decodeIfPresent(String.self, forKey: .name)
        quantity = try container.decodeIfPresent(Int.self, forKey: .quantity)
        
        // Обробляємо additionalPrice як рядок або число
        if let priceString = try? container.decode(String.self, forKey: .additionalPrice) {
            additionalPrice = Double(priceString)
        } else {
            additionalPrice = try container.decodeIfPresent(Double.self, forKey: .additionalPrice)
        }
    }
}

// MARK: - Extensions for OrderItemCustomization

extension OrderItemCustomization {
    var hasCustomizations: Bool {
        let hasIngredients = selectedIngredients?.values.contains { $0 > 0 } == true
        let hasOptions = selectedOptions?.values.contains { !$0.isEmpty } == true
        let hasDetails = customizationDetails?.options?.isEmpty == false || customizationDetails?.size != nil
        return hasIngredients || hasOptions || hasDetails
    }
    
    var displayText: String {
        print("🔍 OrderItemCustomization.displayText:")
        print("   - customizationSummary: \(customizationSummary ?? "nil")")
        print("   - customizationDetails: \(customizationDetails != nil ? "є" : "nil")")
        print("   - selectedIngredients: \(selectedIngredients ?? [:])")
        print("   - selectedOptions: \(selectedOptions?.keys.joined(separator: ", ") ?? "nil")")
        
        // Спочатку пробуємо використати готовий summary з API
        if let summary = customizationSummary, !summary.isEmpty {
            print("   ✅ Використовуємо customizationSummary: \(summary)")
            return summary
        }
        
        // Якщо є детальна інформація, формуємо текст з неї
        if let details = customizationDetails {
            print("   🔧 Формуємо текст з customizationDetails")
            var components: [String] = []
            
            // Додаємо інформацію про розмір
            if let size = details.size {
                if size.price > 0 {
                    components.append("Розмір: \(size.name) (+\(String(format: "%.2f", size.price)) ₴)")
                } else {
                    components.append("Розмір: \(size.name)")
                }
            }
            
            // Додаємо інформацію про опції
            if let options = details.options, !options.isEmpty {
                var optionStrings: [String] = []
                for option in options {
                    if let quantity = option.quantity, quantity > 1 {
                        optionStrings.append("\(option.name) x\(quantity) (+\(String(format: "%.2f", option.totalPrice)) ₴)")
                    } else if option.price > 0 {
                        optionStrings.append("\(option.name) (+\(String(format: "%.2f", option.price)) ₴)")
                    } else {
                        optionStrings.append(option.name)
                    }
                }
                if !optionStrings.isEmpty {
                    components.append("Опції: \(optionStrings.joined(separator: "; "))")
                }
            }
            
            if !components.isEmpty {
                let result = components.joined(separator: "\n")
                print("   ✅ Сформований текст з details: \(result)")
                return result
            }
        }
        
        print("   ⚠️ Використовуємо резервний варіант")
        // Резервний варіант - намагаємося знайти назви в існуючих даних
        var components: [String] = []
        
        // Спочатку додаємо інформацію про розмір, якщо є
        if let sizeData = selectedSizeData {
            if let sizeName = sizeData.name {
                if sizeData.additionalPrice > 0 {
                    components.append("Розмір: \(sizeName) (+\(String(format: "%.2f", sizeData.additionalPrice)) ₴)")
                } else {
                    components.append("Розмір: \(sizeName)")
                }
            }
        }
        
        // Обробляємо інгредієнти
        if let ingredients = selectedIngredients, !ingredients.isEmpty {
            for (ingredientId, quantity) in ingredients where quantity > 0 {
                // Намагаємося знайти назву інгредієнта в опціях
                var ingredientName: String?
                
                if let options = selectedOptions {
                    for (_, choices) in options {
                        for choice in choices {
                            if choice.id == ingredientId, let name = choice.name {
                                ingredientName = name
                                break
                            }
                        }
                        if ingredientName != nil { break }
                    }
                }
                
                                 if let name = ingredientName {
                     if quantity > 1 {
                         components.append("\(name) x\(quantity)")
                     } else {
                         components.append(name)
                     }
                 } else {
                     // Пробуємо знайти назву в сервісі
                     if let serviceName = CustomizationNameService.shared.getIngredientName(for: ingredientId) {
                         if quantity > 1 {
                             components.append("\(serviceName) x\(quantity)")
                         } else {
                             components.append(serviceName)
                         }
                     } else {
                         // Показуємо скорочений ID замість повного
                         let shortId = String(ingredientId.prefix(8))
                         components.append("Інгредієнт (\(shortId)...): +\(quantity)")
                     }
                 }
            }
        }
        
        // Обробляємо опції
        if let options = selectedOptions, !options.isEmpty {
            for (optionId, choices) in options where !choices.isEmpty {
                for choice in choices {
                    if let name = choice.name {
                        if let quantity = choice.quantity, quantity > 1 {
                            if let price = choice.additionalPrice, price > 0 {
                                components.append("\(name) x\(quantity) (+\(String(format: "%.2f", price * Double(quantity))) ₴)")
                            } else {
                                components.append("\(name) x\(quantity)")
                            }
                        } else {
                            if let price = choice.additionalPrice, price > 0 {
                                components.append("\(name) (+\(String(format: "%.2f", price)) ₴)")
                            } else {
                                components.append(name)
                            }
                        }
                    } else {
                        // Пробуємо знайти назву в сервісі
                        if let serviceName = CustomizationNameService.shared.getOptionName(for: choice.id) {
                            if let quantity = choice.quantity, quantity > 1 {
                                if let price = choice.additionalPrice, price > 0 {
                                    components.append("\(serviceName) x\(quantity) (+\(String(format: "%.2f", price * Double(quantity))) ₴)")
                                } else {
                                    components.append("\(serviceName) x\(quantity)")
                                }
                            } else {
                                if let price = choice.additionalPrice, price > 0 {
                                    components.append("\(serviceName) (+\(String(format: "%.2f", price)) ₴)")
                                } else {
                                    components.append(serviceName)
                                }
                            }
                        } else {
                            // Показуємо скорочений ID замість повного
                            let shortId = String(choice.id.prefix(8))
                            components.append("Опція (\(shortId)...)")
                        }
                    }
                }
            }
        }
        
        if components.isEmpty {
            let result = "Без кастомізацій"
            print("   📝 Резервний результат: \(result)")
            return result
        }
        
        // Групуємо компоненти за типами
        var sizeComponents: [String] = []
        var ingredientComponents: [String] = []
        var optionComponents: [String] = []
        
        for component in components {
            if component.hasPrefix("Розмір:") {
                sizeComponents.append(component)
            } else if component.contains("Інгредієнт") || component.contains("x") {
                ingredientComponents.append(component)
            } else {
                optionComponents.append(component)
            }
        }
        
        var formattedComponents: [String] = []
        
        if !sizeComponents.isEmpty {
            formattedComponents.append(contentsOf: sizeComponents)
        }
        
        if !ingredientComponents.isEmpty {
            formattedComponents.append("Інгредієнти: \(ingredientComponents.joined(separator: ", "))")
        }
        
        if !optionComponents.isEmpty {
            formattedComponents.append("Опції: \(optionComponents.joined(separator: "; "))")
        }
        
        let result = formattedComponents.joined(separator: "\n")
        print("   📝 Резервний результат: \(result)")
        return result
    }
}

// MARK: - Order Status History Item

struct OrderStatusHistoryItem: Codable, Identifiable {
    let id: String
    let status: OrderStatus
    let comment: String?
    let createdAt: String
    let createdBy: String?
}

// MARK: - Extensions for OrderStatusHistoryItem

extension OrderStatusHistoryItem {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "d MMM HH:mm"
        
        if let date = ISO8601DateFormatter().date(from: createdAt) {
            return formatter.string(from: date)
        }
        
        // Резервний варіант - спробуємо з іншими форматами
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Formatter.date(from: createdAt) {
            return formatter.string(from: date)
        }
        
        return createdAt
    }
}

// MARK: - Payment Models

struct OrderPaymentInfo: Codable, Identifiable {
    let id: String
    let status: PaymentStatus
    let amount: Double
    let method: String?
    let transactionId: String?
    let createdAt: String
    let completedAt: String?
    let paymentUrl: String?
}

// MARK: - Extensions for OrderPaymentInfo

extension OrderPaymentInfo {
    var formattedAmount: String {
        return String(format: "%.2f ₴", amount)
    }
    
    var statusDisplayName: String {
        switch status {
        case .pending:
            return "Очікує оплати"
        case .processing:
            return "Обробляється"
        case .completed:
            return "Оплачено"
        case .failed:
            return "Помилка оплати"
        case .cancelled:
            return "Скасовано"
        }
    }
    
    var statusColor: String {
        switch status {
        case .pending:
            return "orange"
        case .processing:
            return "primary"
        case .completed:
            return "green"
        case .failed:
            return "red"
        case .cancelled:
            return "nidusGrey"
        }
    }
}

// MARK: - Payment Status Enum

enum PaymentStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
}

// MARK: - Order History Filters

enum OrderHistoryFilter: String, CaseIterable {
    case all = "all"
    case pending = "pending"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .all:
            return "Всі"
        case .pending:
            return "В обробці"
        case .completed:
            return "Завершені"
        case .cancelled:
            return "Скасовані"
        }
    }
    
    var statuses: [OrderStatus]? {
        switch self {
        case .all:
            return nil
        case .pending:
            return [.created, .pending, .accepted, .preparing, .ready]
        case .completed:
            return [.completed]
        case .cancelled:
            return [.cancelled]
        }
    }
}

// MARK: - Customization Details

struct CustomizationDetails: Codable {
    let size: CustomizationSizeDetail?
    let options: [CustomizationOptionDetail]?
    
    enum CodingKeys: String, CodingKey {
        case size, options
    }
}

struct CustomizationSizeDetail: Codable {
    let name: String
    let price: Double
    
    enum CodingKeys: String, CodingKey {
        case name, price
    }
}

struct CustomizationOptionDetail: Codable {
    let name: String
    let price: Double
    let totalPrice: Double
    let quantity: Int?
    
    enum CodingKeys: String, CodingKey {
        case name, price, totalPrice, quantity
    }
}

// MARK: - Coffee Shop Info

struct CoffeeShopInfo: Codable {
    let id: String
    let name: String
    let address: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, address
    }
}

// MARK: - Customization Display Data

struct CustomizationDisplayData {
    let sizeInfo: String?
    let ingredients: [IngredientDisplayItem]
    let optionGroups: [String: [OptionDisplayItem]]
}

struct IngredientDisplayItem {
    let name: String
    let quantity: Int
    let unit: String
    let additionalPrice: Double
    
    var displayText: String {
        let quantityText = "\(quantity) \(unit)"
        if additionalPrice > 0 {
            return "\(name) \(quantityText) (+\(String(format: "%.0f", additionalPrice)) ₴)"
        } else {
            return "\(name) \(quantityText)"
        }
    }
    
    var detailedDisplayInfo: (main: String, detail: String, price: String?) {
        let main = name
        let detail = "\(quantity) \(unit)"
        let price = additionalPrice > 0 ? "+\(String(format: "%.0f", additionalPrice)) ₴" : nil
        return (main, detail, price)
    }
}

struct OptionDisplayItem {
    let name: String
    let quantity: Int
    let additionalPrice: Double
    
    var displayText: String {
        if quantity > 1 {
            if additionalPrice > 0 {
                return "\(name) x\(quantity) (+\(String(format: "%.0f", additionalPrice)) ₴)"
            } else {
                return "\(name) x\(quantity)"
            }
        } else {
            if additionalPrice > 0 {
                return "\(name) (+\(String(format: "%.0f", additionalPrice)) ₴)"
            } else {
                return name
            }
        }
    }
    
    var detailedDisplayInfo: (main: String, detail: String?, price: String?) {
        let main = name
        let detail = quantity > 1 ? "x\(quantity)" : nil
        let price = additionalPrice > 0 ? "+\(String(format: "%.0f", additionalPrice)) ₴" : nil
        return (main, detail, price)
    }
}


