//
//  MenuGroupsListView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/2/25.
//

import SwiftUI

struct MenuGroupsListView: View {
    let coffeeShop: CoffeeShop
    @StateObject private var viewModel = MenuGroupsViewModel()
    @State private var showingCreateSheet = false
    @State private var selectedMenuGroup: MenuGroup?
    @State private var showingEditSheet = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ZStack {
            Color("backgroundColor")
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                if viewModel.isLoading {
                    ProgressView("Завантаження...")
                        .padding()
                } else if let error = viewModel.error {
                    VStack(spacing: 16) {
                        Text("Помилка")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Спробувати ще раз") {
                            Task {
                                await viewModel.loadMenuGroups(coffeeShopId: coffeeShop.id)
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color("primary"))
                        .cornerRadius(12)
                    }
                    .padding()
                } else if viewModel.menuGroups.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 60))
                            .foregroundColor(Color("secondaryText"))
                        
                        Text("Групи меню відсутні")
                            .font(.headline)
                            .foregroundColor(Color("primaryText"))
                        
                        Text("Створіть свою першу групу меню, натиснувши кнопку нижче")
                            .font(.subheadline)
                            .foregroundColor(Color("secondaryText"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(viewModel.menuGroups) { group in
                                MenuGroupRowView(
                                    menuGroup: group,
                                    itemsCount: viewModel.getMenuItemsCount(for: group.id),
                                    coffeeShopId: coffeeShop.id,
                                    onEdit: { menuGroup in
                                        selectedMenuGroup = menuGroup
                                        showingEditSheet = true
                                    },
                                    onDelete: { menuGroup in
                                        selectedMenuGroup = menuGroup
                                        showDeleteConfirmation = true
                                    }
                                )
                                .background(Color("cardColor"))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            
            // Кнопка додавання групи меню
            VStack {
                Spacer()
                
                Button(action: {
                    showingCreateSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.headline)
                        
                        Text("Додати групу меню")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(Color("primary"))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .padding(.bottom, 20)
            }
            
            // Тост із повідомленням
            if viewModel.showSuccess {
                Toast(message: viewModel.successMessage, isShowing: $viewModel.showSuccess)
            }
        }
        .navigationTitle("Меню \"\(coffeeShop.name)\"")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.loadMenuGroups(coffeeShopId: coffeeShop.id)
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateMenuGroupView(
                coffeeShopId: coffeeShop.id,
                viewModel: viewModel
            )
        }
        .sheet(isPresented: $showingEditSheet) {
            if let menuGroup = selectedMenuGroup {
                EditMenuGroupView(
                    coffeeShopId: coffeeShop.id,
                    menuGroup: menuGroup,
                    viewModel: viewModel
                )
            }
        }
        .alert("Видалення групи меню", isPresented: $showDeleteConfirmation) {
            Button("Скасувати", role: .cancel) {}
            Button("Видалити", role: .destructive) {
                if let menuGroup = selectedMenuGroup {
                    Task {
                        await viewModel.deleteMenuGroup(coffeeShopId: coffeeShop.id, groupId: menuGroup.id)
                    }
                }
            }
        } message: {
            if let menuGroup = selectedMenuGroup {
                Text("Ви впевнені, що хочете видалити групу меню '\(menuGroup.name)'? Ця дія незворотна.")
            } else {
                Text("Ви впевнені, що хочете видалити цю групу меню? Ця дія незворотна.")
            }
        }
    }
}


struct MenuGroupRowView: View {
    let menuGroup: MenuGroup
    let itemsCount: Int
    let coffeeShopId: String
    let onEdit: (MenuGroup) -> Void
    let onDelete: (MenuGroup) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(menuGroup.name)
                    .font(.headline)
                    .foregroundColor(Color("primaryText"))
                
                if let description = menuGroup.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(Color("secondaryText"))
                        .lineLimit(2)
                }
                
                HStack(spacing: 12) {
                    // Порядковий номер
                    HStack(spacing: 4) {
                        Image(systemName: "number")
                            .font(.caption)
                            .foregroundColor(Color("primary"))
                        
                        Text("Порядок: \(menuGroup.displayOrder)")
                            .font(.caption)
                            .foregroundColor(Color("secondaryText"))
                    }
                    
                    // Кількість пунктів меню
                    HStack(spacing: 4) {
                        Image(systemName: "square.stack")
                            .font(.caption)
                            .foregroundColor(Color("primary"))
                        
                        Text("\(itemsCount) \(menuItemText(itemsCount))")
                            .font(.caption)
                            .foregroundColor(Color("secondaryText"))
                    }
                }
            }
            
            Spacer()
            
            // Кнопка меню (три крапки)
            Menu {
                Button(action: {
                    onEdit(menuGroup)
                }) {
                    Label("Редагувати", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: {
                    onDelete(menuGroup)
                }) {
                    Label("Видалити", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundColor(Color("secondaryText"))
                    .padding(8)
                    .background(Color("inputField").opacity(0.5))
                    .clipShape(Circle())
            }
            .padding(.trailing, 8)
            
            // Навігація до пунктів меню
            NavigationLink(destination: MenuItemsListView(menuGroup: menuGroup)) {
                Image(systemName: "chevron.right")
                    .foregroundColor(Color("secondaryText"))
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.trailing, 4)
            }
        }
        .padding(16)
        .background(Color("cardColor"))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // Функція для правильної форми слова "пункт меню" залежно від кількості
    private func menuItemText(_ count: Int) -> String {
        let lastDigit = count % 10
        let lastTwoDigits = count % 100
        
        if lastTwoDigits >= 11 && lastTwoDigits <= 19 {
            return "пунктів меню"
        }
        
        switch lastDigit {
        case 1:
            return "пункт меню"
        case 2, 3, 4:
            return "пункти меню"
        default:
            return "пунктів меню"
        }
    }
}
