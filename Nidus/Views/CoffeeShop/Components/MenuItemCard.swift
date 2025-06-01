//
//  MenuItemCard.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/8/25.
//

import SwiftUI
import Kingfisher

/// Оновлена картка пункту меню з навігацією до деталей
struct MenuItemCard: View {
    // MARK: - Властивості
    let item: MenuItem
    let coffeeShopId: String
    let coffeeShopName: String
    @State private var navigateToDetails = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var showCheckmarkAnimation = false
    
    // MARK: - View
    var body: some View {
        navigationLinkView
            .overlay(
                // Checkmark анімація по центру картки
                SuccessCheckmarkAnimation(
                    isShowing: $showCheckmarkAnimation
                )
            )
    }
    
    @ViewBuilder
    private var navigationLinkView: some View {
        if #available(iOS 16.0, *) {
            // Новий стиль для iOS 16+
            NavigationLink(value: item) {
                cardContent
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            // Старий стиль для iOS 15 і раніше
            NavigationLink(
                destination: MenuItemDetailView(menuItem: item, coffeeShopId: coffeeShopId)
            ) {
                cardContent
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var cardContent: some View {
        CardContentView(
            item: item,
            addAction: {
                // Додавання товару до корзини при натисканні на кнопку +
                addToCart()
            }
        )
    }
    
    
    // MARK: - Функція додавання товару до корзини
    private func addToCart() {
        if !item.isAvailable {
            return
        }
        
        // Додаємо товар в корзину з базовими налаштуваннями
        let cartItem = CartItem(
            from: item,
            coffeeShopId: coffeeShopId,
            quantity: 1,
            selectedSize: nil,
            customization: nil
        )
        
        let success = CartService.shared.addItem(cartItem)
        
        if success {
            // Показуємо checkmark анімацію
            showCheckmarkAnimation = true
        } else {
            // Якщо додавання не успішне (конфлікт кав'ярень), перенаправляємо на детальний екран
            navigateToDetails = true
        }
    }
    
    // MARK: - Форматування ціни
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        return formatter.string(from: NSDecimalNumber(decimal: price)) ?? "\(price)"
    }
}

// Додаємо аліас для зворотної сумісності
typealias MenuItemCardWithNavigation = MenuItemCard

// Винесений контент картки в окремий компонент
struct CardContentView: View {
    let item: MenuItem
    var addAction: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Зображення товару
            ZStack(alignment: .topTrailing) {
                if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 125, height: 125)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                } else {
                    defaultImageView
                }
                
                // Індикатори для кастомізації та статусу
                HStack(spacing: 4) {
                    // Індикатор кастомізації
                    if hasCustomizationOptions {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Circle().fill(Color("primary")))
                    }
                }
                .padding(8)
            }
            
            // Інформація про товар (назва та опис)
            VStack(alignment: .leading, spacing: 4) {
                // Назва товару
                Text(item.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("primaryText"))
                    .lineLimit(1)
                
                // Опис (якщо є)
                if let description = item.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .fontWeight(.regular)
                        .foregroundColor(Color("secondaryText"))
                        .lineLimit(1)
                        .truncationMode(.tail)
                } else {
                    // Пустий текст для збереження висоти
                    Text("")
                        .font(.caption)
                        .foregroundColor(.clear)
                }
            }
            .frame(height: 45)
            .padding(.top, 5)
            .padding(.leading, 4)
            
            Spacer()
                .frame(height: 8) // Фіксована висота замість автоматичного розтягування
            
            // Ціна та кнопка додавання
            HStack {
                // Ціна
                Text("₴ \(formatPrice(item.price))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color("primary"))
                
                Spacer()
                
                // Кнопка додавання / деталей
                Button(action: addAction) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color("primary").opacity(0.8), Color("primary")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 35, height: 35)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 6)
            .padding(.horizontal, 6)
        }
        // Стилі всієї картки - оновлений зі скляним ефектом
        .padding(4)
        .frame(width: 135, height: 232)
        .background(cardBackground)
        .cornerRadius(25)
        .overlay(cardBorder)
        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
        .opacity(item.isAvailable ? 1.0 : 0.5)
        .overlay(unavailableOverlay)
    }
    
    /// Заглушка для зображення
    private var defaultImageView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("cardColor").opacity(0.7))
                .frame(width: 125, height: 125)
            
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 40))
                .foregroundColor(Color("primary"))
        }
    }
    
    /// Перевірка наявності опцій кастомізації
    private var hasCustomizationOptions: Bool {
        return (item.ingredients != nil && !item.ingredients!.isEmpty) ||
               (item.customizationOptions != nil && !item.customizationOptions!.isEmpty)
    }
    
    /// Форматування ціни без копійок
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        return formatter.string(from: NSDecimalNumber(decimal: price)) ?? "\(price)"
    }
    
    /// Фонове оформлення картки
    private var cardBackground: some View {
        ZStack {
            // Скляний фон
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.clear)
                .overlay(blurEffectView)
                .overlay(colorTintOverlay)
                .clipShape(RoundedRectangle(cornerRadius: 25))
        }
    }
    
    /// Ефект розмиття
    private var blurEffectView: some View {
        BlurView(
            style: colorScheme == .light ? .systemThinMaterial : .systemMaterialDark,
            opacity: 0.95
        )
    }
    
    /// Кольорове тонування
    @ViewBuilder
    private var colorTintOverlay: some View {
        if colorScheme == .light {
            // Тонування для світлої теми
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("nidusMistyBlue").opacity(0.25),
                        Color("nidusCoolGray").opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.4)
                
                Color("nidusLightBlueGray").opacity(0.12)
            }
        } else {
            // Темна тема
            Color.black.opacity(0.15)
        }
    }
    
    /// Обводка картки
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 25)
            .stroke(borderGradient, lineWidth: 1)
    }
    
    /// Градієнт для обводки
    private var borderGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .light 
                    ? Color("nidusCoolGray").opacity(0.4)
                    : Color.black.opacity(0.35),
                colorScheme == .light
                    ? Color("nidusLightBlueGray").opacity(0.25)
                    : Color.black.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Оверлей для недоступних товарів
    @ViewBuilder
    private var unavailableOverlay: some View {
        if !item.isAvailable {
            Text("Недоступно")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.7))
                .cornerRadius(4)
        }
    }
}



