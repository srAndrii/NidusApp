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
    case offers = 2       // Пропозиції
    case orders = 3       // Мої замовлення
    case profile = 4      // Профіль
}

class TabBarManager: ObservableObject {
    // Публікована властивість для вибраної вкладки
    @Published var selectedTab: TabSelection = .coffeeShops
    
    // ID для навігації, змінюється коли потрібно скинути навігаційний стек
    @Published var navigationId = UUID()
    
    // Кількість товарів в корзині (для відображення бейджа)
    @Published var cartItemsCount: Int = 0
    
    // Властивість для керування відображенням корзини як sheet
    @Published var isCartSheetPresented: Bool = false
    
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
