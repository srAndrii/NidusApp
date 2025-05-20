//
//  TabBarManager.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 5/18/25.
//

import Foundation
import SwiftUI

// Перелік для представлення вкладок TabBar
enum TabSelection: Int {
    case coffeeShops = 0  // Кав'ярні
    case qrCode = 1       // Мій код
    case cart = 2         // Корзина
    case offers = 3       // Пропозиції
    case profile = 4      // Профіль
}

class TabBarManager: ObservableObject {
    // Публікована властивість для вибраної вкладки
    @Published var selectedTab: TabSelection = .coffeeShops
    
    // ID для навігації, змінюється коли потрібно скинути навігаційний стек
    @Published var navigationId = UUID()
    
    // Кількість товарів в корзині (для відображення бейджа)
    @Published var cartItemsCount: Int = 0
    
    // Метод для переключення на іншу вкладку
    func switchToTab(_ tab: TabSelection) {
        selectedTab = tab
    }
    
    // Скидає навігаційний стек поточної вкладки до кореневого екрану
    func resetNavigationToRoot() {
        navigationId = UUID()
    }
    
    // Обробка вибору вкладки
    func handleTabSelection(_ tab: TabSelection) {
        // Якщо користувач натискає на поточну вкладку, скидаємо навігацію до кореня
        if tab == selectedTab {
            resetNavigationToRoot()
        }
    }
    
    // Метод для оновлення кількості товарів у корзині
    func updateCartItemsCount(_ count: Int) {
        DispatchQueue.main.async {
            self.cartItemsCount = count
        }
    }
}
