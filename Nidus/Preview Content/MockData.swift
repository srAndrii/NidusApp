//
//  Untitled.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/7/25.
//

import Foundation
import SwiftUI // Додано імпорт SwiftUI для Color

/// Тестові дані для використання в превью
struct MockData {
    // Одиночні кав'ярні для простих превью
    static let singleCoffeeShop = CoffeeShop(
        id: "mock-1",
        name: "Кав'ярня Власника",
        address: "вул. Хрещатик, 31",
        logoUrl: "https://res.cloudinary.com/dlbbjiuco/image/upload/v1741643259/nidus/defaults/coffee-shop-logo.png",
        ownerId: "owner-1",
        allowScheduledOrders: true,
        minPreorderTimeMinutes: 15,
        maxPreorderTimeMinutes: 120,
        workingHours: [
            "0": WorkingHoursPeriod(open: "09:00", close: "20:00", isClosed: true),
            "1": WorkingHoursPeriod(open: "09:00", close: "21:00", isClosed: false),
            "2": WorkingHoursPeriod(open: "09:00", close: "21:00", isClosed: false),
            "3": WorkingHoursPeriod(open: "09:00", close: "21:00", isClosed: false),
            "4": WorkingHoursPeriod(open: "09:00", close: "21:00", isClosed: false),
            "5": WorkingHoursPeriod(open: "09:00", close: "22:00", isClosed: false),
            "6": WorkingHoursPeriod(open: "10:00", close: "20:00", isClosed: false)
        ],
        createdAt: Date(),
        updatedAt: Date(),
        menuGroups: [mockHotDrinksGroup, mockColdDrinksGroup, mockDessertsGroup]
    )
    
    // Список кав'ярень для тестування списків
    static let coffeeShops: [CoffeeShop] = [
        singleCoffeeShop,
        CoffeeShop(
            id: "mock-2",
            name: "Coffee Bloom",
            address: "вул. Льва Толстого 9, Київ",
            logoUrl: nil,
            ownerId: nil,
            allowScheduledOrders: true,
            minPreorderTimeMinutes: 15,
            maxPreorderTimeMinutes: 120,
            workingHours: ["1": WorkingHoursPeriod(open: "09:00", close: "21:00", isClosed: false)],
            createdAt: Date(),
            updatedAt: Date(),
            distance: 750
        ),
        CoffeeShop(
            id: "mock-3",
            name: "Morning Brew",
            address: "вул. Саксаганського 22, Київ",
            logoUrl: nil,
            ownerId: nil,
            allowScheduledOrders: false,
            minPreorderTimeMinutes: 15,
            maxPreorderTimeMinutes: 120,
            workingHours: ["1": WorkingHoursPeriod(open: "07:30", close: "20:00", isClosed: false)],
            createdAt: Date(),
            updatedAt: Date(),
            distance: 1200
        )
    ]
    
    // Групи меню
    static let mockHotDrinksGroup = MenuGroup(
        id: "group-1",
        name: "Гарячі напої",
        description: "Різноманітні види кави та інші гарячі напої",
        displayOrder: 1,
        coffeeShopId: "mock-1",
        menuItems: [mockCappuccino, mockEspresso, mockLatte],
        createdAt: Date(),
        updatedAt: Date()
    )
    
    static let mockColdDrinksGroup = MenuGroup(
        id: "group-2",
        name: "Холодні напої",
        description: "Освіжаючі холодні кавові напої",
        displayOrder: 2,
        coffeeShopId: "mock-1",
        menuItems: [mockIceLatte, mockIcedAmericano],
        createdAt: Date(),
        updatedAt: Date()
    )
    
    static let mockDessertsGroup = MenuGroup(
        id: "group-3",
        name: "Десерти",
        description: "Смачні десерти до кави",
        displayOrder: 3,
        coffeeShopId: "mock-1",
        menuItems: [mockCheesecake, mockCroissant],
        createdAt: Date(),
        updatedAt: Date()
    )
    
    // Пункти меню
    static let mockCappuccino = MenuItem(
        id: "item-1",
        name: "Cappuccino",
        price: 99.0,
        description: "With Steamed Milk",
        imageUrl: "https://res.cloudinary.com/dlbbjiuco/image/upload/v1741643259/nidus/defaults/cappuccino.jpg",
        isAvailable: true,
        menuGroupId: "group-1",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    static let mockEspresso = MenuItem(
        id: "item-2",
        name: "Espresso",
        price: 51.0,
        description: "Double shot",
        imageUrl: "https://res.cloudinary.com/dlbbjiuco/image/upload/v1741643259/nidus/defaults/espresso.jpg",
        isAvailable: true,
        menuGroupId: "group-1",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    static let mockLatte = MenuItem(
        id: "item-3",
        name: "Latte",
        price: 110.0,
        description: "With Extra Milk",
        imageUrl: nil,
        isAvailable: true,
        menuGroupId: "group-1",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    static let mockIceLatte = MenuItem(
        id: "item-4",
        name: "Ice Latte",
        price: 120.0,
        description: "Cold and Refreshing",
        imageUrl: nil,
        isAvailable: true,
        menuGroupId: "group-2",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    static let mockIcedAmericano = MenuItem(
        id: "item-5",
        name: "Iced Americano",
        price: 90.0,
        description: "With ice cubes",
        imageUrl: nil,
        isAvailable: false,
        menuGroupId: "group-2",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    static let mockCheesecake = MenuItem(
        id: "item-6",
        name: "Cheesecake",
        price: 130.0,
        description: "Classic NY style",
        imageUrl: nil,
        isAvailable: true,
        menuGroupId: "group-3",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    static let mockCroissant = MenuItem(
        id: "item-7",
        name: "Croissant",
        price: 85.0,
        description: "Butter croissant",
        imageUrl: nil,
        isAvailable: true,
        menuGroupId: "group-3",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    // Користувачі
    static let owner = User(
        id: "owner-1",
        email: "owner@example.com",
        firstName: "Андрій",
        lastName: "Власник",
        phone: "+380991234567",
        avatarUrl: nil,
        roles: [
            Role(
                id: "role-1",
                name: "coffee_shop_owner",
                description: "Власник кав'ярні",
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    )
}

