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
            // Створюємо об'єкт для кастомізації, якщо вона є
            var customizationDto: OrderItemCustomizationDto? = nil
            
            if let customization = item.customization {
                customizationDto = OrderItemCustomizationDto()
                
                // Додаємо розмір, якщо він є
                if let selectedSize = item.selectedSize {
                    customizationDto?.selectedSize = selectedSize
                }
                
                // Додаємо вибрані інгредієнти, якщо вони є
                if let selectedIngredients = customization["selectedIngredients"] as? [String: Double] {
                    customizationDto?.selectedIngredients = selectedIngredients
                }
                
                // Додаємо вибрані опції
                if let selectedOptions = customization["selectedOptions"] as? [String: [[String: Any]]] {
                    var processedOptions: [String: [OptionChoiceDto]] = [:]
                    
                    for (optionId, choices) in selectedOptions {
                        var processedChoices: [OptionChoiceDto] = []
                        
                        for choice in choices {
                            if let choiceId = choice["choiceId"] as? String {
                                let quantity = choice["quantity"] as? Int ?? 1
                                processedChoices.append(OptionChoiceDto(choiceId: choiceId, quantity: quantity))
                            }
                        }
                        
                        processedOptions[optionId] = processedChoices
                    }
                    
                    customizationDto?.selectedOptions = processedOptions
                }
            }
            
            // Створюємо об'єкт для товару замовлення
            return CreateOrderItemDto(
                menuItemId: item.menuItemId,
                quantity: item.quantity,
                customization: customizationDto
            )
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
            scheduledFor: scheduledForString
        )
        
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
    
    struct OrderItemCustomizationDto: Codable {
        var selectedSize: String?
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
