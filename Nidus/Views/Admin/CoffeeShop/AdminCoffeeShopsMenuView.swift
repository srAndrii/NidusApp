//
//  AdminCoffeeShopsMenuView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/31/25.
//

import SwiftUI

struct AdminCoffeeShopsMenuView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        ZStack {
            Color("backgroundColor")
                .edgesIgnoringSafeArea(.all)
            
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
                            NavigationLink(destination: MyAdminCoffeeShopsView()) {
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
                    
                    // Секція з меню групами та пунктами меню (для подальшої реалізації)
                    Text("УПРАВЛІННЯ МЕНЮ")
                        .font(.caption)
                        .foregroundColor(Color("secondaryText"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    
                    VStack(spacing: 0) {
                        // Управління групами меню
                        NavigationLink(destination: Text("Тут буде управління групами меню")) {
                            HStack(spacing: 16) {
                                Image(systemName: "folder")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color("primary"))
                                    .frame(width: 28, height: 28)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Групи меню")
                                        .font(.headline)
                                        .foregroundColor(Color("primaryText"))
                                    
                                    Text("Категорії товарів у меню кав'ярень")
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
                        
                        // Управління пунктами меню
                        NavigationLink(destination: Text("Тут буде управління пунктами меню")) {
                            HStack(spacing: 16) {
                                Image(systemName: "list.dash")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color("primary"))
                                    .frame(width: 28, height: 28)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Пункти меню")
                                        .font(.headline)
                                        .foregroundColor(Color("primaryText"))
                                    
                                    Text("Товари (напої, десерти) у меню кав'ярень")
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
                    .background(Color("cardColor"))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Управління кав'ярнями")
        .navigationBarTitleDisplayMode(.inline)
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

// Допоміжний компонент для показу лише "моїх" кав'ярень
struct MyAdminCoffeeShopsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var viewModel: CoffeeShopViewModel
    
    init() {
        // Створюємо тимчасовий AuthManager для ініціалізації
        let authManager = AuthenticationManager()
        self._viewModel = StateObject(wrappedValue: CoffeeShopViewModel(authManager: authManager))
    }
    
    var body: some View {
        ZStack {
            Color("backgroundColor")
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                if viewModel.isLoading {
                    ProgressView("Завантаження...")
                        .padding()
                } else if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .multilineTextAlignment(.center)
                } else if viewModel.myCoffeeShops.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "cup.and.saucer")
                            .font(.system(size: 60))
                            .foregroundColor(Color("secondaryText"))
                        
                        Text("У вас немає кав'ярень")
                            .font(.headline)
                            .foregroundColor(Color("primaryText"))
                        
                        Text("Ви ще не створили жодної кав'ярні або адміністратор ще не призначив вас власником")
                            .font(.subheadline)
                            .foregroundColor(Color("secondaryText"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding()
                } else {
                    // Список кав'ярень
                    List {
                        ForEach(viewModel.myCoffeeShops) { shop in
                            CoffeeShopAdminRow(
                                coffeeShop: shop,
                                canManage: true,
                                isSuperAdmin: false,
                                onEdit: {
                                    viewModel.selectedCoffeeShop = shop
                                },
                                onDelete: {
                                    viewModel.selectedCoffeeShop = shop
                                },
                                onAssignOwner: {}
                            )
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .background(Color("backgroundColor"))
                }
            }
        }
        .onAppear {
            // Оновлюємо ViewModel щоб використати @EnvironmentObject
            viewModel.authManager = authManager
            
            // Завантажуємо дані
            Task {
                await viewModel.loadMyCoffeeShops()
            }
        }
        .navigationTitle("Мої кав'ярні")
        .navigationBarTitleDisplayMode(.inline)
    }
}
