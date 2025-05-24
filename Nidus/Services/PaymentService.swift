//
//  PaymentService.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 5/18/25.
//

import Foundation
import UIKit
import WebKit

class PaymentService {
    // Синглтон для доступу до сервісу
    static let shared = PaymentService()
    
    // Сервіс мережі
    private let networkService: NetworkService
    
    // Базовий URL для перенаправлення
    private let deepLinkScheme = "nidus://"
    
    // Повний URL для перенаправлення після оплати
    private var redirectUrl: String {
        return "\(deepLinkScheme)payment-callback"
    }
    
    private init(networkService: NetworkService = NetworkService.shared) {
        self.networkService = networkService
    }
    
    // MARK: - Публічні методи для здійснення оплати
    
    // Створення замовлення з оплатою
    func createOrderWithPayment(
        coffeeShopId: String,
        items: [CartItem],
        comment: String? = nil,
        scheduledFor: Date? = nil
    ) async throws -> CreateOrderWithPaymentResultDto {
        // Підготовка списку товарів для запиту
        let orderItems = items.map { item -> CreateOrderItemDto in
            print("📝 PaymentService: Обробка товару \(item.name)")
            print("   - Дані кастомізації: \(String(describing: item.customization))")
            
            // Створюємо об'єкт для кастомізації, якщо вона є
            var customizationDto: OrderItemCustomizationDto? = nil
            
            if let customization = item.customization {
                customizationDto = OrderItemCustomizationDto()
                
                // Додаємо дані про розмір, включаючи ID та додаткову ціну
                if let sizeData = customization["size"] as? [String: Any] {
                    if let sizeId = sizeData["id"] as? String {
                        customizationDto?.selectedSize = sizeId
                        print("   - Розмір: \(sizeData["abbreviation"] as? String ?? "невідомо") (ID: \(sizeId))")
                        
                        // Додаємо інформацію про додаткову ціну
                        if let additionalPrice = sizeData["additionalPrice"] as? Decimal {
                            customizationDto?.selectedSizeData = SizeDataDto(id: sizeId, additionalPrice: additionalPrice)
                            print("   - Додаткова ціна за розмір: +\(additionalPrice)")
                        }
                    }
                }
                
                // Обробляємо інгредієнти з формату збереження в корзині
                if let ingredients = customization["ingredients"] as? [[String: Any]] {
                    var selectedIngredients: [String: Double] = [:]
                    
                    for ingredient in ingredients {
                        if let id = ingredient["id"] as? String,
                           let amount = ingredient["amount"] as? Double {
                            selectedIngredients[id] = amount
                        }
                    }
                    
                    if !selectedIngredients.isEmpty {
                        customizationDto?.selectedIngredients = selectedIngredients
                        print("   - Інгредієнти: \(selectedIngredients)")
                    }
                }
                
                // Обробляємо опції кастомізації з формату збереження в корзині
                if let options = customization["options"] as? [[String: Any]] {
                    var selectedOptions: [String: [OptionChoiceDto]] = [:]
                    
                    for option in options {
                        if let optionId = option["id"] as? String,
                           let choices = option["choices"] as? [[String: Any]] {
                            
                            var processedChoices: [OptionChoiceDto] = []
                            
                            for choice in choices {
                                if let choiceId = choice["id"] as? String {
                                    let quantity = choice["quantity"] as? Int ?? 1
                                    processedChoices.append(OptionChoiceDto(choiceId: choiceId, quantity: quantity))
                                }
                            }
                            
                            if !processedChoices.isEmpty {
                                selectedOptions[optionId] = processedChoices
                            }
                        }
                    }
                    
                    if !selectedOptions.isEmpty {
                        customizationDto?.selectedOptions = selectedOptions
                        print("   - Опції: \(selectedOptions)")
                    }
                }
            }
            
            // Створюємо об'єкт для товару замовлення
            let orderItem = CreateOrderItemDto(
                menuItemId: item.menuItemId,
                quantity: item.quantity,
                customization: customizationDto
            )
            
            print("   - Створено OrderItemDto: menuItemId=\(item.menuItemId), quantity=\(item.quantity)")
            return orderItem
        }
        
        // Форматуємо дату, якщо вона є
        var scheduledForString: String?
        if let scheduledFor = scheduledFor {
            let formatter = ISO8601DateFormatter()
            scheduledForString = formatter.string(from: scheduledFor)
        }
        
        // Створюємо запит на створення замовлення
        let createOrderDto = CreateOrderDto(
            coffeeShopId: coffeeShopId,
            items: orderItems,
            comment: comment,
            scheduledFor: scheduledForString,
            redirectUrl: redirectUrl
        )
        
        print("📝 PaymentService: Відправляємо запит на створення замовлення:")
        print("   - Coffee Shop ID: \(coffeeShopId)")
        print("   - Кількість товарів: \(orderItems.count)")
        print("   - Коментар: \(comment ?? "немає")")
        print("   - Redirect URL: \(redirectUrl)")
        
        // Відправляємо запит на сервер
        return try await networkService.post(
            endpoint: "/orders/create-with-payment",
            body: createOrderDto
        )
    }
    
    // Отримання інформації про статус оплати
    func getOrderPaymentStatus(orderId: String) async throws -> OrderPaymentStatusDto {
        return try await networkService.fetch(
            endpoint: "/orders/\(orderId)/payment-status"
        )
    }
    
    // Повторний запит на оплату для існуючого замовлення
    func retryPayment(orderId: String) async throws -> CreateOrderWithPaymentResultDto {
        return try await networkService.post(
            endpoint: "/orders/\(orderId)/retry-payment",
            body: EmptyObject()
        )
    }
    
    // Скасування замовлення
    func cancelOrder(orderId: String) async throws -> Order {
        return try await networkService.patch(
            endpoint: "/orders/\(orderId)/cancel",
            body: EmptyObject()
        )
    }
    
    // MARK: - Структури для запитів/відповідей
    
    struct EmptyObject: Codable {}
    
    struct SizeDataDto: Codable {
        let id: String
        let additionalPrice: Decimal
    }
    
    struct OrderItemCustomizationDto: Codable {
        var selectedSize: String?
        var selectedSizeData: SizeDataDto?
        var selectedIngredients: [String: Double]?
        var selectedOptions: [String: [OptionChoiceDto]]?
    }
    
    struct OptionChoiceDto: Codable {
        let choiceId: String
        let quantity: Int?
    }
    
    struct CreateOrderItemDto: Codable {
        let menuItemId: String
        let quantity: Int
        let customization: OrderItemCustomizationDto?
    }
    
    struct CreateOrderDto: Codable {
        let coffeeShopId: String
        let items: [CreateOrderItemDto]
        let comment: String?
        let scheduledFor: String?
        let redirectUrl: String
    }
}

// MARK: - Структури для відповідей API
struct CreateOrderWithPaymentResultDto: Codable {
    let orderId: String
    let orderNumber: String
    let status: String
    let totalAmount: Decimal
    let paymentUrl: String
    let paymentId: String
    let expiresAt: String?
}

struct OrderPaymentStatusDto: Codable {
    let orderId: String
    let paymentId: String?
    let status: String
    let paidAmount: Decimal
    let isPaid: Bool
    let paymentUrl: String?
}
