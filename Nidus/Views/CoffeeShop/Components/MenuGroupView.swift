//
//  MenuGroupView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/8/25.
//


import SwiftUI

/// Оновлений компонент для відображення групи меню з навігацією до деталей пунктів меню
struct MenuGroupView: View {
    // MARK: - Властивості
    let group: MenuGroup
    
    // MARK: - View
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Заголовок групи
            headerView
            
            // Опис групи (якщо є)
            descriptionView
            
            // Горизонтальний скрол з пунктами меню
            menuItemsScrollView
        }
        .onAppear {
            print("📋 MenuGroupView.body з'явився для групи: \(group.id), назва: \(group.name)")
        }
    }
       
    
    
    // MARK: - Допоміжні компоненти
    
    /// Заголовок групи меню
    private var headerView: some View {
        HStack {
            Text(group.name)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color("primaryText"))
            
            Spacer()
            
            // Кнопка "Показати всі"
            Button(action: {
                // Дія для переходу до всіх пунктів категорії
            }) {
                Text("Всі")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("primary"))
            }
        }
        .padding(.horizontal, 10)
    }
    
    /// Опис групи (якщо є)
    private var descriptionView: some View {
        Group {
            if let description = group.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Color("secondaryText"))
                    .padding(.horizontal, 10)
                    .padding(.top, -6)
            }
        }
    }
    
    /// Горизонтальний список пунктів меню
    private var menuItemsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let menuItems = group.menuItems, !menuItems.isEmpty {
                    ForEach(menuItems) { item in
                        // Використовуємо виправлену картку з навігацією
                        if #available(iOS 16.0, *) {
                            MenuItemCard(item: item)
                                .buttonStyle(PlainButtonStyle())
                        } else {
                            MenuItemCardWithNavigation(item: item)
                        }
                    }
                } else {
                    emptyStateView
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 6)
        }
        .padding(.bottom, 6)
    }
    
    /// Пустий стан, коли немає пунктів меню
    private var emptyStateView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 23)
                .fill(Color("cardColor"))
                .frame(width: 170, height: 250)
            
            VStack(spacing: 12) {
                Image(systemName: "cup.and.saucer")
                    .font(.system(size: 40))
                    .foregroundColor(Color("secondaryText"))
                
                Text("Немає доступних пунктів")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("secondaryText"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Preview
struct MenuGroupView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Група з товарами
            MenuGroupView(group: MockData.mockHotDrinksGroup)
                .previewDisplayName("With Items")
            
            // Порожня група
            MenuGroupView(group: MenuGroup(
                id: "empty-group",
                name: "Порожня група",
                description: "Група без пунктів меню",
                displayOrder: 1,
                coffeeShopId: "coffee-1",
                menuItems: [],
                createdAt: Date(),
                updatedAt: Date()
            ))
            .previewDisplayName("Empty Group")
        }
        .padding(.vertical)
        .background(Color("backgroundColor"))
        .previewLayout(.sizeThatFits)
    }
}
