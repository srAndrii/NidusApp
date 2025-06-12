import Foundation

// MARK: - Helper for backward compatibility

struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

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
    let cancelledBy: String?
    let cancellationActor: String?
    let cancellationReason: String?
    let comment: String?
    
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
        payment: OrderPaymentInfo?,
        cancelledBy: String? = nil,
        cancellationActor: String? = nil,
        cancellationReason: String? = nil,
        comment: String? = nil
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
        self.cancelledBy = cancelledBy
        self.cancellationActor = cancellationActor
        self.cancellationReason = cancellationReason
        self.comment = comment
    }
    
    // MARK: - Custom Decoding
    enum CodingKeys: String, CodingKey {
        case id, orderNumber, status, totalAmount, coffeeShopId, coffeeShopName, coffeeShop, isPaid, createdAt, completedAt, items, statusHistory, payment, cancelledBy, cancellationActor, cancellationReason, comment
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
        cancelledBy = try container.decodeIfPresent(String.self, forKey: .cancelledBy)
        cancellationActor = try container.decodeIfPresent(String.self, forKey: .cancellationActor)
        cancellationReason = try container.decodeIfPresent(String.self, forKey: .cancellationReason)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        
        // Обробляємо totalAmount як рядок або число
        if let totalAmountString = try? container.decode(String.self, forKey: .totalAmount) {
            totalAmount = Double(totalAmountString) ?? 0.0
        } else {
            totalAmount = try container.decode(Double.self, forKey: .totalAmount)
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
        if let cachedName = CoffeeShopCache.shared.getCoffeeShopName(for: coffeeShopId) {
            return cachedName
        }
        return "Невідома кав'ярня"
    }
    
    var cancellationDisplayText: String? {
        print("🔍 cancellationDisplayText викликано:")
        print("   status: \(status.rawValue)")
        print("   cancellationActor: \(cancellationActor ?? "nil")")
        
        guard status == .cancelled else { 
            print("   ❌ status не є cancelled")
            return nil 
        }
        
        if let actor = cancellationActor {
            print("   ✅ cancellationActor знайдено: \(actor)")
            switch actor {
            case "customer":
                let result = "Замовлення скасовано Клієнтом"
                print("   📝 Результат: \(result)")
                return result
            case "coffee_shop":
                let result = "Замовлення скасовано Закладом"
                print("   📝 Результат: \(result)")
                return result
            case "admin":
                let result = "Замовлення скасовано Адміністратором"
                print("   📝 Результат: \(result)")
                return result
            default:
                let result = "Замовлення скасовано"
                print("   📝 Результат (default): \(result)")
                return result
            }
        }
        
        print("   ❌ cancellationActor не знайдено")
        return nil
    }
    
    var cancellationComment: String? {
        print("🔍 cancellationComment викликано:")
        print("   status: \(status.rawValue)")
        print("   cancellationReason: \(cancellationReason ?? "nil")")
        print("   comment: \(comment ?? "nil")")
        
        guard status == .cancelled else { 
            print("   ❌ status не є cancelled")
            return nil 
        }
        
        // NEW: Пріоритет згідно з новою документацією бекенду
        // 1. ПРІОРИТЕТ: cancellationReason (якщо є)
        if let reason = cancellationReason, !reason.isEmpty {
            // Виключаємо стандартні системні повідомлення
            let standardMessages = [
                "Замовлення скасовано користувачем",
                "Замовлення скасовано кав'ярнею",
                "Замовлення скасовано клієнтом",
                "Замовлення скасовано закладом",
                "Замовлення скасовано адміністратором"
            ]
            
            if !standardMessages.contains(reason) {
                print("   ✅ ПРІОРИТЕТ: Знайдено користувацький cancellationReason: \(reason)")
                return reason
            } else {
                print("   ⚠️ cancellationReason є стандартним повідомленням: \(reason)")
            }
        }
        
        // 2. ЗАПАСНИЙ ВАРІАНТ: comment поле (для сумісності)
        if let webSocketComment = comment, !webSocketComment.isEmpty {
            // Виключаємо стандартні системні повідомлення
            let standardMessages = [
                "Замовлення скасовано користувачем",
                "Замовлення скасовано кав'ярнею",
                "Замовлення скасовано клієнтом",
                "Замовлення скасовано закладом",
                "Замовлення скасовано адміністратором"
            ]
            
            if !standardMessages.contains(webSocketComment) {
                print("   ✅ ЗАПАСНИЙ: Знайдено користувацький comment: \(webSocketComment)")
                return webSocketComment
            } else {
                print("   ⚠️ comment є стандартним повідомленням: \(webSocketComment)")
            }
        }
        
        // 3. ІСТОРІЯ СТАТУСІВ: Якщо не знайдено, шукаємо в останньому записі історії статусів
        if let lastCancelledItem = statusHistory.last(where: { $0.status == .cancelled }),
           let historyComment = lastCancelledItem.comment,
           !historyComment.isEmpty {
            // Також виключаємо стандартні повідомлення з історії
            let standardHistoryMessages = [
                "Замовлення скасовано клієнтом",
                "Замовлення скасовано кав'ярнею", 
                "Замовлення скасовано закладом",
                "Замовлення скасовано адміністратором"
            ]
            
            if !standardHistoryMessages.contains(historyComment) {
                print("   ✅ ІСТОРІЯ: Знайдено користувацький коментар в історії: \(historyComment)")
                return historyComment
            } else {
                print("   ⚠️ Коментар в історії є стандартним: \(historyComment)")
            }
        } else {
            print("   ⚠️ Не знайдено записів cancelled в statusHistory")
        }
        
        print("   ❌ cancellationComment повертає nil")
        return nil
    }
    
    // NEW: Helper функція для отримання коментаря скасування згідно з новою документацією
    func getCancellationMessage(from webSocketData: Any? = nil) -> String? {
        guard status == .cancelled else { return nil }
        
        // Якщо є дані з WebSocket orderCancelled події
        if let cancellationData = webSocketData as? OrderWebSocketManager.OrderCancellationData {
            // 1. Пріоритет: cancellationReason
            if let reason = cancellationData.cancellationReason, !reason.isEmpty {
                return reason
            }
            
            // 2. Запасний варіант: comment
            if let comment = cancellationData.comment, !comment.isEmpty {
                return comment
            }
        }
        
        // Якщо є дані з WebSocket orderStatusUpdated події
        if let statusData = webSocketData as? OrderWebSocketManager.OrderStatusUpdateData {
            // 1. Пріоритет: cancellationReason
            if let reason = statusData.cancellationReason, !reason.isEmpty {
                return reason
            }
            
            // 2. staffComment (тільки від персоналу)
            if let staffComment = statusData.staffComment, !staffComment.isEmpty {
                return staffComment
            }
            
            // 3. Загальний коментар
            if let comment = statusData.comment, !comment.isEmpty {
                return comment
            }
        }
        
        // Fallback до існуючої логіки
        return cancellationComment
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
            return size.additionalPrice
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
        // Спочатку пробуємо використати customizationDetails з точними цінами з API
        if let details = customizationDetails {
            print("🔍 OrderHistoryItem: Формуємо з item.customizationDetails (новий API)")
            return formatCustomizationDetailsToDisplayData(details)
        }
        
        // Резервний варіант - customizationSummary для старих замовлень
        if let summary = customizationSummary, !summary.isEmpty {
            print("🔍 OrderHistoryItem: Використовуємо item.customizationSummary (legacy): \(summary)")
            return formatCustomizationSummary(summary)
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
        
        print("🔍 formatCustomizationDetailsToDisplayData: Обробляємо деталі кастомізації")
        
        // Handle ingredients from new API format
        if let newIngredients = details.ingredients, !newIngredients.isEmpty {
            print("   - Знайдено \(newIngredients.count) інгредієнтів в новому форматі")
            for ingredient in newIngredients {
                let displayItem = IngredientDisplayItem(
                    name: ingredient.name,
                    quantity: ingredient.amount,
                    unit: ingredient.unit ?? "шт",
                    additionalPrice: ingredient.pricing?.totalPrice ?? 0.0
                )
                ingredients.append(displayItem)
                print("     - Інгредієнт: \(ingredient.name), кількість: \(ingredient.amount), ціна: \(ingredient.pricing?.totalPrice ?? 0.0)")
            }
        }
        
        if let options = details.options, !options.isEmpty {
            print("   - Знайдено \(options.count) опцій в деталях")
            
            for option in options {
                // Handle new API format with grouped options
                if let choices = option.choices, !choices.isEmpty {
                    let groupName = option.optionGroupName ?? "Додаткові опції"
                    print("     - Група опцій: \(groupName)")
                    
                    for choice in choices {
                        let optionItem = OptionDisplayItem(
                            name: choice.name,
                            quantity: choice.quantity ?? 1,
                            additionalPrice: choice.pricing?.totalPrice ?? 0.0
                        )
                        
                        print("       - Вибір: \(choice.name), кількість: \(choice.quantity ?? 1), ціна: \(choice.pricing?.totalPrice ?? 0.0)")
                        
                        if optionGroups[groupName] == nil {
                            optionGroups[groupName] = []
                        }
                        optionGroups[groupName]?.append(optionItem)
                    }
                } else if let optionName = option.name {
                    // Handle legacy API format
                    let optionItem = OptionDisplayItem(
                        name: optionName,
                        quantity: option.quantity ?? 1,
                        additionalPrice: option.totalPrice ?? 0.0
                    )
                    
                    print("     - Опція (legacy): \(optionName), кількість: \(option.quantity ?? 1), ціна: \(option.totalPrice ?? 0.0)")
                    
                    let groupName = determineOptionGroupName(for: optionName)
                    
                    if optionGroups[groupName] == nil {
                        optionGroups[groupName] = []
                    }
                    optionGroups[groupName]?.append(optionItem)
                    print("     - Додано до групи '\(groupName)'")
                }
            }
        }
        
        print("   ✅ Сформовано груп опцій: \(optionGroups.keys.joined(separator: ", "))")
        
        return CustomizationDisplayData(
            sizeInfo: nil, // НЕ включаємо розмір
            ingredients: ingredients,
            optionGroups: optionGroups
        )
    }
    
    private func determineOptionGroupName(for optionName: String) -> String {
        // ✅ Визначаємо групу опції за її назвою
        let lowercaseName = optionName.lowercased()
        
        if lowercaseName.contains("сироп") || lowercaseName.contains("syrup") ||
           lowercaseName.contains("карамел") || lowercaseName.contains("ваніл") ||
           lowercaseName.contains("мед") || lowercaseName.contains("шоколад") {
            return "Сироп"
        }
        
        if lowercaseName.contains("молок") || lowercaseName.contains("milk") ||
           lowercaseName.contains("соєв") || lowercaseName.contains("мигдал") ||
           lowercaseName.contains("вівся") || lowercaseName.contains("кокос") {
            return "Тип молока"
        }
        
        if lowercaseName.contains("топінг") || lowercaseName.contains("topping") {
            return "Топінги"
        }
        
        // За замовчуванням
        return "Додаткові опції"
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
                    // ✅ ВИПРАВЛЕННЯ: Обробляємо масив опцій замість однієї
                    if let (groupName, options) = parseOptionItem(item) {
                        if optionGroups[groupName] == nil {
                            optionGroups[groupName] = []
                        }
                        // ✅ Додаємо ВСІ опції з групи (множинні сиропи)
                        optionGroups[groupName]?.append(contentsOf: options)
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
    
    private func parseOptionItem(_ item: String) -> (String, [OptionDisplayItem])? {
        // ✅ ВИПРАВЛЕННЯ: Парсимо рядки з множинними опціями типу "Сироп: Карамель x6, Ванільний x2, Мед x1"
        let components = item.components(separatedBy: ": ")
        guard components.count >= 2 else { return nil }
        
        let groupName = components[0].trimmingCharacters(in: .whitespaces)
        let optionsInfo = components[1].trimmingCharacters(in: .whitespaces)
        
        print("🔍 parseOptionItem: Парсимо опцію '\(groupName)' з варіантами: '\(optionsInfo)'")
        
        // ✅ Розділяємо кілька опцій за комами: "Карамель x6, Ванільний x2"
        let optionItems = optionsInfo.components(separatedBy: ", ")
        var options: [OptionDisplayItem] = []
        
        for optionItem in optionItems {
            if let option = parseSingleOptionItem(optionItem.trimmingCharacters(in: .whitespaces), groupName: groupName) {
                options.append(option)
                print("   ✅ Додано опцію: \(option.name) x\(option.quantity) (+\(option.additionalPrice)₴)")
            }
        }
        
        return options.isEmpty ? nil : (groupName, options)
    }
    
    private func parseSingleOptionItem(_ optionItem: String, groupName: String) -> OptionDisplayItem? {
        // Парсимо одну опцію типу "Карамель x6" або "Ванільний"
        var optionName = optionItem
        var quantity = 1
        
        // Витягуємо кількість (x6, x3 тощо)
        let quantityPattern = "x(\\d+)"
        if let quantityMatch = optionItem.range(of: quantityPattern, options: .regularExpression) {
            let quantityString = String(optionItem[quantityMatch])
            let numberPattern = "\\d+"
            let numberMatch = quantityString.range(of: numberPattern, options: .regularExpression)
            if let numberRange = numberMatch {
                quantity = Int(String(quantityString[numberRange])) ?? 1
            }
            optionName = String(optionItem[..<quantityMatch.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        
        // Обчислюємо додаткову вартість на основі типу опції та кількості
        let additionalPrice = calculateOptionPrice(groupName: groupName, optionName: optionName, quantity: quantity)
        
        return OptionDisplayItem(
            name: optionName,
            quantity: quantity,
            additionalPrice: additionalPrice
        )
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
                if size.additionalPrice > 0 {
                    components.append("Розмір: \(size.name) (+\(String(format: "%.2f", size.additionalPrice)) ₴)")
                } else {
                    components.append("Розмір: \(size.name)")
                }
            }
            
            // Додаємо інформацію про опції
            if let options = details.options, !options.isEmpty {
                var optionStrings: [String] = []
                for option in options {
                    // Handle new API format with grouped options
                    if let choices = option.choices, !choices.isEmpty {
                        for choice in choices {
                            let quantity = choice.quantity ?? 1
                            let totalPrice = choice.pricing?.totalPrice ?? 0.0
                            if quantity > 1 {
                                optionStrings.append("\(choice.name) x\(quantity) (+\(String(format: "%.2f", totalPrice)) ₴)")
                            } else if totalPrice > 0 {
                                optionStrings.append("\(choice.name) (+\(String(format: "%.2f", totalPrice)) ₴)")
                            } else {
                                optionStrings.append(choice.name)
                            }
                        }
                    } else if let optionName = option.name {
                        // Handle legacy API format
                        let quantity = option.quantity ?? 1
                        let totalPrice = option.totalPrice ?? 0.0
                        let price = option.price ?? 0.0
                        
                        if quantity > 1 {
                            optionStrings.append("\(optionName) x\(quantity) (+\(String(format: "%.2f", totalPrice)) ₴)")
                        } else if price > 0 {
                            optionStrings.append("\(optionName) (+\(String(format: "%.2f", price)) ₴)")
                        } else {
                            optionStrings.append(optionName)
                        }
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
            for (_, choices) in options where !choices.isEmpty {
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
    let menuItem: CustomizationMenuItemDetail?
    let size: CustomizationSizeDetail?
    let options: [CustomizationOptionDetail]?
    let ingredients: [CustomizationIngredientDetail]?
    let priceSummary: CustomizationPriceSummaryDetail?
    
    // Regular initializer for programmatic creation
    init(
        menuItem: CustomizationMenuItemDetail? = nil,
        size: CustomizationSizeDetail? = nil,
        options: [CustomizationOptionDetail]? = nil,
        ingredients: [CustomizationIngredientDetail]? = nil,
        priceSummary: CustomizationPriceSummaryDetail? = nil
    ) {
        self.menuItem = menuItem
        self.size = size
        self.options = options
        self.ingredients = ingredients
        self.priceSummary = priceSummary
    }
    
    enum CodingKeys: String, CodingKey {
        case menuItem, size, options, ingredients, priceSummary
    }
}

struct CustomizationMenuItemDetail: Codable {
    let id: String
    let name: String
    let basePrice: Double
    
    enum CodingKeys: String, CodingKey {
        case id, name, basePrice
    }
}

struct CustomizationIngredientDetail: Codable {
    let id: String
    let name: String
    let amount: Int
    let unit: String?
    let pricing: IngredientPricingDetail?
    let constraints: IngredientConstraintsDetail?
    
    enum CodingKeys: String, CodingKey {
        case id, name, amount, unit, pricing, constraints
    }
}

struct IngredientPricingDetail: Codable {
    let pricePerUnit: Double?
    let freeAmount: Int?
    let chargedAmount: Int?
    let totalPrice: Double
    
    enum CodingKeys: String, CodingKey {
        case pricePerUnit, freeAmount, chargedAmount, totalPrice
    }
}

struct IngredientConstraintsDetail: Codable {
    let minAmount: Int?
    let maxAmount: Int?
    let isCustomizable: Bool?
    
    enum CodingKeys: String, CodingKey {
        case minAmount, maxAmount, isCustomizable
    }
}

struct CustomizationPriceSummaryDetail: Codable {
    let basePrice: Double
    let sizeAdjustment: Double?
    let optionsTotal: Double?
    let ingredientsTotal: Double?
    let finalPrice: Double
    
    enum CodingKeys: String, CodingKey {
        case basePrice, sizeAdjustment, optionsTotal, ingredientsTotal, finalPrice
    }
}

struct CustomizationSizeDetail: Codable {
    let id: String?
    let name: String
    let abbreviation: String?
    let additionalPrice: Double
    let isDefault: Bool?
    let order: Int?
    
    // For backward compatibility
    var price: Double {
        return additionalPrice
    }
    
    // Regular initializer for programmatic creation
    init(
        id: String? = nil,
        name: String,
        abbreviation: String? = nil,
        additionalPrice: Double,
        isDefault: Bool? = nil,
        order: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.abbreviation = abbreviation
        self.additionalPrice = additionalPrice
        self.isDefault = isDefault
        self.order = order
    }
    
    // Convenience initializer for backward compatibility with old "price" parameter
    init(name: String, price: Double) {
        self.id = nil
        self.name = name
        self.abbreviation = nil
        self.additionalPrice = price
        self.isDefault = nil
        self.order = nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, abbreviation, additionalPrice, isDefault, order
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        abbreviation = try container.decodeIfPresent(String.self, forKey: .abbreviation)
        isDefault = try container.decodeIfPresent(Bool.self, forKey: .isDefault)
        order = try container.decodeIfPresent(Int.self, forKey: .order)
        
        // Handle price field changes from old to new API format
        if let newPrice = try? container.decode(Double.self, forKey: .additionalPrice) {
            additionalPrice = newPrice
        } else {
            // Try to decode the old "price" field for backward compatibility
            let legacyContainer = try decoder.container(keyedBy: AnyCodingKey.self)
            if let oldPrice = try? legacyContainer.decode(Double.self, forKey: AnyCodingKey(stringValue: "price")) {
                additionalPrice = oldPrice
            } else {
                additionalPrice = 0.0
            }
        }
    }
}

struct CustomizationOptionDetail: Codable {
    let optionGroupId: String?
    let optionGroupName: String?
    let required: Bool?
    let choices: [CustomizationChoiceDetail]?
    
    // Legacy fields for backward compatibility
    let name: String?
    let price: Double?
    let totalPrice: Double?
    let quantity: Int?
    
    // Regular initializer for programmatic creation
    init(
        optionGroupId: String? = nil,
        optionGroupName: String? = nil,
        required: Bool? = nil,
        choices: [CustomizationChoiceDetail]? = nil,
        name: String? = nil,
        price: Double? = nil,
        totalPrice: Double? = nil,
        quantity: Int? = nil
    ) {
        self.optionGroupId = optionGroupId
        self.optionGroupName = optionGroupName
        self.required = required
        self.choices = choices
        self.name = name
        self.price = price
        self.totalPrice = totalPrice
        self.quantity = quantity
    }
    
    // Convenience initializer for backward compatibility
    init(name: String, price: Double, totalPrice: Double, quantity: Int? = nil) {
        self.optionGroupId = nil
        self.optionGroupName = nil
        self.required = nil
        self.choices = nil
        self.name = name
        self.price = price
        self.totalPrice = totalPrice
        self.quantity = quantity
    }
    
    enum CodingKeys: String, CodingKey {
        case optionGroupId, optionGroupName, required, choices
        case name, price, totalPrice, quantity
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // New API format
        optionGroupId = try container.decodeIfPresent(String.self, forKey: .optionGroupId)
        optionGroupName = try container.decodeIfPresent(String.self, forKey: .optionGroupName)
        required = try container.decodeIfPresent(Bool.self, forKey: .required)
        choices = try container.decodeIfPresent([CustomizationChoiceDetail].self, forKey: .choices)
        
        // Legacy format for backward compatibility
        name = try container.decodeIfPresent(String.self, forKey: .name)
        quantity = try container.decodeIfPresent(Int.self, forKey: .quantity)
        
        // Handle price fields for backward compatibility
        if let legacyPrice = try? container.decode(Double.self, forKey: .price) {
            price = legacyPrice
        } else {
            price = nil
        }
        
        if let legacyTotalPrice = try? container.decode(Double.self, forKey: .totalPrice) {
            totalPrice = legacyTotalPrice
        } else {
            totalPrice = nil
        }
    }
}

struct CustomizationChoiceDetail: Codable {
    let id: String
    let name: String
    let quantity: Int?
    let pricing: ChoicePricingDetail?
    let constraints: ChoiceConstraintsDetail?
    
    enum CodingKeys: String, CodingKey {
        case id, name, quantity, pricing, constraints
    }
}

struct ChoicePricingDetail: Codable {
    let basePrice: Double?
    let freeQuantity: Int?
    let pricePerAdditionalUnit: Double?
    let chargedQuantity: Int?
    let totalPrice: Double
    
    enum CodingKeys: String, CodingKey {
        case basePrice, freeQuantity, pricePerAdditionalUnit, chargedQuantity, totalPrice
    }
}

struct ChoiceConstraintsDetail: Codable {
    let minQuantity: Int?
    let maxQuantity: Int?
    let defaultQuantity: Int?
    
    enum CodingKeys: String, CodingKey {
        case minQuantity, maxQuantity, defaultQuantity
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


