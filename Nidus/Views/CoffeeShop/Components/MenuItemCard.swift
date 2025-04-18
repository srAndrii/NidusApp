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
    @State private var navigateToDetails = false
    
    // MARK: - Обчислювані властивості
    
    /// Градієнт фону картки
    private var cardGradient: LinearGradient {
        return LinearGradient(
            gradient: Gradient(colors: [Color("cardTop"), Color("cardBottom")]),
            startPoint: .top,
            endPoint: .bottomTrailing
        )
    }
    
    /// Градієнт для кнопки додавання
    private var addButtonGradient: LinearGradient {
        return LinearGradient(
            gradient: Gradient(colors: [
                Color("primary").opacity(0.8),
                Color("primary")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - View
    var body: some View {
        ZStack {
            if #available(iOS 16.0, *) {
                // Новий стиль для iOS 16+
                NavigationLink(value: item) {
                    CardContentView(item: item, addAction: { navigateToDetails = true })
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Старий стиль для iOS 15 і раніше
                NavigationLink(
                    destination: MenuItemDetailView(menuItem: item)
                ) {
                    CardContentView(item: item, addAction: { navigateToDetails = true })
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// Додаємо аліас для зворотної сумісності
typealias MenuItemCardWithNavigation = MenuItemCard

// Винесений контент картки в окремий компонент
struct CardContentView: View {
    let item: MenuItem
    var addAction: () -> Void
    
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
                    .foregroundColor(Color.white)
                    .lineLimit(1)
                
                // Опис (якщо є)
                if let description = item.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .fontWeight(.regular)
                        .foregroundColor(Color.gray)
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
            
            Spacer()
            
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
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 6)
        }
        // Стилі всієї картки
        .padding(5)
        .frame(width: 135, height: 245)
        .background(LinearGradient(
            gradient: Gradient(colors: [Color("cardTop"), Color("cardBottom")]),
            startPoint: .top,
            endPoint: .bottomTrailing
        ))
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .opacity(item.isAvailable ? 1.0 : 0.5)
        // Показуємо "Недоступно" для недоступних товарів
        .overlay(
            Group {
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
        )
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
}
