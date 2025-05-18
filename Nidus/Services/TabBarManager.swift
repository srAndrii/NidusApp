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
    
    // Метод для переключення на іншу вкладку
    func switchToTab(_ tab: TabSelection) {
        selectedTab = tab
    }
}
