//
//  AdminCoffeeShopsMenuView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/31/25.
//

import SwiftUI

struct AdminCoffeeShopsMenuView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var viewModel = CoffeeShopViewModel(authManager: AuthenticationManager())
    @State private var isLoading = true
    @State private var hasOnlyOneCoffeeShop = false
    @State private var singleCoffeeShop: CoffeeShop?
    
    var body: some View {
        ZStack {
            Color("backgroundColor")
                .edgesIgnoringSafeArea(.all)
            
            if isLoading {
                ProgressView("Завантаження...")
            } else if hasOnlyOneCoffeeShop, let coffeeShop = singleCoffeeShop {
                // Відразу відображаємо єдину кав'ярню замість меню
                // Використовуємо спеціальний режим перегляду з `viewMode: .singleShop`
                AdminCoffeeShopsView(viewMode: .myShops, initialCoffeeShop: coffeeShop)
                    .navigationBarBackButtonHidden(false)
            } else {
                // Стандартне меню управління кав'ярнями
                ScrollView {
                    VStack(spacing: 0) {
                        Text("УПРАВЛІННЯ КАВ'ЯРНЯМИ")
                            .font(.caption)
                            .foregroundColor(Color("secondaryText"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        
                        // Картка з меню
                        VStack(spacing: 0) {
                            // Список кав'ярень
                            if isSuperAdmin() {
                                NavigationLink(destination: AdminCoffeeShopsView()) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "list.bullet")
                                            .font(.system(size: 20))
                                            .foregroundColor(Color("primary"))
                                            .frame(width: 28, height: 28)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Список кав'ярень")
                                                .font(.headline)
                                                .foregroundColor(Color("primaryText"))
                                            
                                            Text("Перегляд та управління всіма кав'ярнями")
                                                .font(.caption)
                                                .foregroundColor(Color("secondaryText"))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color("secondaryText"))
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 16)
                                }
                                
                                Divider()
                                    .background(Color("secondaryText").opacity(0.2))
                                    .padding(.leading, 60)
                            }
                            
                            // Створення кав'ярні
                            NavigationLink(destination: CreateCoffeeShopWrapperView()) {
                                HStack(spacing: 16) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color("primary"))
                                        .frame(width: 28, height: 28)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Створити кав'ярню")
                                            .font(.headline)
                                            .foregroundColor(Color("primaryText"))
                                        
                                        Text("Додати нову кав'ярню до системи")
                                            .font(.caption)
                                            .foregroundColor(Color("secondaryText"))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color("secondaryText"))
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                            }
                            
                            Divider()
                                .background(Color("secondaryText").opacity(0.2))
                                .padding(.leading, 60)
                            
                            // Мої кав'ярні (лише для власників)
                            if isCoffeeShopOwner() {
                                // Використовуємо точно такий же компонент, просто з іншим параметром
                                NavigationLink(destination: AdminCoffeeShopsView(viewMode: .myShops)) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "star")
                                            .font(.system(size: 20))
                                            .foregroundColor(Color("primary"))
                                            .frame(width: 28, height: 28)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Мої кав'ярні")
                                                .font(.headline)
                                                .foregroundColor(Color("primaryText"))
                                            
                                            Text("Перегляд та управління власними кав'ярнями")
                                                .font(.caption)
                                                .foregroundColor(Color("secondaryText"))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color("secondaryText"))
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .background(Color("cardColor"))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 16)
                }
            }
        }
        .navigationTitle("Управління кав'ярнями")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Перевіряємо кількість кав'ярень користувача при завантаженні
            checkCoffeeShops()
        }
    }
    
    // Метод для перевірки кількості кав'ярень
    // Замінити метод checkCoffeeShops
    private func checkCoffeeShops() {
        // Оновлюємо ViewModel щоб використати @EnvironmentObject
        viewModel.authManager = authManager
        
        Task {
            isLoading = true
            
            // Завантажуємо кав'ярні користувача
            if isCoffeeShopOwner() {
                await viewModel.loadMyCoffeeShops()
            }
            
            isLoading = false
        }
    }
    
    private func isSuperAdmin() -> Bool {
        return authManager.currentUser?.roles?.contains(where: { $0.name == "superadmin" }) ?? false
    }
    
    // Перевіряє, чи є користувач власником кав'ярні
    private func isCoffeeShopOwner() -> Bool {
        return authManager.currentUser?.roles?.contains(where: { $0.name == "coffee_shop_owner" }) ?? false
    }
}

// Допоміжний компонент для обгортки CreateCoffeeShopView
struct CreateCoffeeShopWrapperView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        let viewModel = CoffeeShopViewModel(authManager: authManager)
        CreateCoffeeShopView(viewModel: viewModel)
            .navigationBarHidden(true)
    }
}

struct AdminCoffeeShopsMenuView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AdminCoffeeShopsMenuView()
                .environmentObject(AuthenticationManager())
        }
        .preferredColorScheme(.dark)
    }
}
