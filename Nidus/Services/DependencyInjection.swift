//
//  DependencyInjection.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/30/25.
//

import Foundation

class DIContainer {
    // Singleton для доступу
    static let shared = DIContainer()
    
    // Сервіси
    let networkService: NetworkService
    
    // Репозиторії
    let authRepository: AuthRepositoryProtocol
    let userRepository: UserRepositoryProtocol
    let coffeeShopRepository: CoffeeShopRepositoryProtocol
    let menuGroupRepository: MenuGroupRepositoryProtocol
    let menuItemRepository: MenuItemRepositoryProtocol
    let orderRepository: OrderRepositoryProtocol
    
    // Приватний конструктор для Singleton
    private init() {
        self.networkService = NetworkService.shared
        
        self.authRepository = AuthRepository(networkService: networkService)
        self.userRepository = UserRepository(networkService: networkService)
        self.coffeeShopRepository = CoffeeShopRepository(networkService: networkService)
        self.menuGroupRepository = MenuGroupRepository(networkService: networkService)
        self.menuItemRepository = MenuItemRepository(networkService: networkService)
        self.orderRepository = OrderRepository(networkService: networkService)
    }
    
    // Метод для отримання HomeViewModel
    func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel(coffeeShopRepository: coffeeShopRepository)
    }
    
    // Метод для отримання AdminViewModel
    func makeAdminViewModel() -> AdminViewModel {
        return AdminViewModel(userRepository: userRepository)
    }
}
