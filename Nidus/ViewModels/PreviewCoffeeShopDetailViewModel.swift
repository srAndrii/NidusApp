//
//  PreviewCoffeeShopDetailViewModel.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/7/25.
//

import Foundation
import SwiftUI // Додано імпорт SwiftUI для типу View
import Combine

/// Спрощена версія ViewModel для превью
class PreviewCoffeeShopDetailViewModel: CoffeeShopDetailViewModel {
    override func loadMenuGroups(coffeeShopId: String) {
        // Підставляємо тестові дані замість запитів до API
        menuGroups = MockData.singleCoffeeShop.menuGroups ?? []
        isLoading = false
    }
}

/// Розширення для використання в превью
extension CoffeeShopDetailView {
    static var preview: some SwiftUI.View { // Явно вказуємо SwiftUI.View для уникнення конфліктів
        let previewViewModel = PreviewCoffeeShopDetailViewModel(coffeeShopRepository: DIContainer.shared.coffeeShopRepository)
        
        return CoffeeShopDetailView(coffeeShop: MockData.singleCoffeeShop)
            .environmentObject(AuthenticationManager())
    }
}
