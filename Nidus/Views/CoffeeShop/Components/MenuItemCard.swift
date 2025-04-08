//
//  MenuItemCard.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/8/25.
//

import SwiftUI
import Kingfisher

/// Компонент для відображення картки пункту меню
struct MenuItemCard: View {
    // MARK: - Властивості
    let item: MenuItem
    
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
        Button(action: {
            // Дія для переходу до детального перегляду товару
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Зображення товару
                imageView
                
                // Інформація про товар
                infoView
                
                Spacer()
                
                // Ціна та кнопка додавання
                priceAndAddButtonView
            }
            // Стилі всієї картки
            .padding(5)
            .frame(width: 135, height: 245)
            .background(cardGradient)
            .cornerRadius(25)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            .opacity(item.isAvailable ? 1.0 : 0.5)
            // Показуємо "Недоступно" для недоступних товарів
            .overlay(unavailableOverlay, alignment: .center)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Допоміжні компоненти
    
    /// Зображення товару
    private var imageView: some View {
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
        }
    }
    
    /// Заглушка для зображення
    private var defaultImageView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("cardColor").opacity(0.7))
                .frame(width: 150, height: 150)
            
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 40))
                .foregroundColor(Color("primary"))
        }
    }
    
    /// Інформація про товар (назва та опис)
    private var infoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Назва товару
            Text(item.name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color.white)
            
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
    }
    
    /// Ціна та кнопка додавання
    private var priceAndAddButtonView: some View {
        HStack {
            // Ціна
            Text("₴ \(formatPrice(item.price))")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color("primary"))
            
            Spacer()
            
            // Кнопка додавання
            addButtonView
        }
        .padding(.bottom, 6)
    }
    
    /// Кнопка додавання в кошик
    private var addButtonView: some View {
        Button(action: {
            // Дія для додавання в кошик
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(addButtonGradient)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// Накладення "Недоступно" для недоступних товарів
    private var unavailableOverlay: some View {
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
    }
    
    // MARK: - Допоміжні методи
    
    /// Форматування ціни без копійок
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        return formatter.string(from: NSDecimalNumber(decimal: price)) ?? "\(price)"
    }
}

// MARK: - Preview
struct MenuItemCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Доступний товар
            MenuItemCard(item: MockData.mockCappuccino)
                .previewDisplayName("Available Item")
            
            // Недоступний товар
            MenuItemCard(item: MockData.mockIcedAmericano)
                .previewDisplayName("Unavailable Item")
        }
        .padding()
        .background(Color("backgroundColor"))
        .previewLayout(.sizeThatFits)
    }
}
