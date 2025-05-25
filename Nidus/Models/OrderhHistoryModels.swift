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
        self.isPaid = isPaid
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.items = items
        self.statusHistory = statusHistory
        self.payment = payment
    }
    
    // MARK: - Custom Decoding
    enum CodingKeys: String, CodingKey {
        case id, orderNumber, status, totalAmount, coffeeShopId, coffeeShopName, isPaid, createdAt, completedAt, items, statusHistory, payment
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        orderNumber = try container.decode(String.self, forKey: .orderNumber)
        status = try container.decode(OrderStatus.self, forKey: .status)
        coffeeShopId = try container.decode(String.self, forKey: .coffeeShopId)
        coffeeShopName = try container.decodeIfPresent(String.self, forKey: .coffeeShopName)
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
    let sizeName: String?
    
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
        sizeName: String?
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.basePrice = basePrice
        self.finalPrice = finalPrice
        self.quantity = quantity
        self.customization = customization
        self.sizeName = sizeName
    }
    
    // MARK: - Custom Decoding
    enum CodingKeys: String, CodingKey {
        case id, name, price, basePrice, finalPrice, quantity, customization, sizeName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        quantity = try container.decode(Int.self, forKey: .quantity)
        customization = try container.decodeIfPresent(OrderItemCustomization.self, forKey: .customization)
        sizeName = try container.decodeIfPresent(String.self, forKey: .sizeName)
        
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
}

// MARK: - Order Item Customization

struct OrderItemCustomization: Codable {
    let selectedIngredients: [String: Int]?
    let selectedOptions: [String: [OrderCustomizationChoice]]?
    let selectedSizeData: SelectedSizeData?
    
    // Кастомний декодер для гнучкої обробки різних форматів API
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        selectedIngredients = try container.decodeIfPresent([String: Int].self, forKey: .selectedIngredients)
        selectedOptions = try container.decodeIfPresent([String: [OrderCustomizationChoice]].self, forKey: .selectedOptions)
        selectedSizeData = try container.decodeIfPresent(SelectedSizeData.self, forKey: .selectedSizeData)
    }
    
    enum CodingKeys: String, CodingKey {
        case selectedIngredients, selectedOptions, selectedSizeData
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
        return hasIngredients || hasOptions
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


