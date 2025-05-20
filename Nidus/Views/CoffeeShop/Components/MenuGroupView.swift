//
//  MenuGroupView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/8/25.
//


import SwiftUI
import Kingfisher

/// Оновлений компонент для відображення групи меню з навігацією до деталей пунктів меню
struct MenuGroupView: View {
    // MARK: - Властивості
    let group: MenuGroup
    @State private var isExpanded = true
    let coffeeShopId: String
    let coffeeShopName: String
    
    init(group: MenuGroup, coffeeShopId: String, coffeeShopName: String) {
        self.group = group
        self.coffeeShopId = coffeeShopId
        self.coffeeShopName = coffeeShopName
    }
    
    // MARK: - View
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Заголовок групи з можливістю згортання
            HStack {
                Text(group.name)
                    .font(.headline)
                    .foregroundColor(Color("primaryText"))
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Color("primaryText"))
                        .font(.system(size: 14, weight: .medium))
                        .padding(8)
                        .background(Color("cardColor").opacity(0.3))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Елементи групи з анімацією згортання/розгортання
            if isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(group.menuItems ?? []) { item in
                            MenuItemCard(
                                item: item,
                                coffeeShopId: coffeeShopId,
                                coffeeShopName: coffeeShopName
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            print("📋 MenuGroupView.body з'явився для групи: \(group.id), назва: \(group.name)")
        }
    }
       
    
    
    // MARK: - Допоміжні компоненти
    
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
}

// MARK: - Preview
struct MenuGroupView_Previews: PreviewProvider {
    static var previews: some View {
        MenuGroupView(
            group: MockData.mockHotDrinksGroup,
            coffeeShopId: "test-coffee-shop-id",
            coffeeShopName: "Тестова кав'ярня"
        )
        .background(Color("backgroundColor"))
        .previewLayout(.sizeThatFits)
    }
}
