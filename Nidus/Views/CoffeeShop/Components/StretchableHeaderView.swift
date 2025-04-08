//
//  Untitled.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/8/25.
//

import SwiftUI
import Kingfisher

/// Компонент для відображення розтягуваної шапки з зображенням та інформацією
struct StretchableHeaderView: View {
    // MARK: - Властивості
    let coffeeShop: CoffeeShop
    
    // MARK: - Константи
    private let minHeaderHeight: CGFloat = 300
    
    // MARK: - View
    var body: some View {
        GeometryReader { geometry in
            let scrollY = geometry.frame(in: .global).minY
            let scrollYOffset = max(0, scrollY)
            let headerHeight = minHeaderHeight + scrollYOffset
            
            ZStack(alignment: .bottom) {
                // Зображення або заглушка з ефектом розтягування
                imageView(width: geometry.size.width, height: headerHeight, offset: scrollYOffset)
                
                // Напівпрозорий блок з інформацією
                informationOverlay
            }
            .frame(width: geometry.size.width, height: max(minHeaderHeight, headerHeight))
        }
    }
    
    // MARK: - Допоміжні компоненти
    
    /// Відображає зображення кав'ярні або заглушку
    private func imageView(width: CGFloat, height: CGFloat, offset: CGFloat) -> some View {
        Group {
            if let logoUrl = coffeeShop.logoUrl, let url = URL(string: logoUrl) {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .offset(y: -offset/2) // Ефект паралаксу
                    .clipped()
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color("cardColor").opacity(0.7))
                        .frame(width: width, height: height)
                        .offset(y: -offset/2)
                    
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color("primary"))
                }
            }
        }
    }
    
    /// Блок з інформацією про кав'ярню
    private var informationOverlay: some View {
        VStack(spacing: 0) {
            // Інформаційний блок із заокругленими верхніми кутами
            ZStack {
                // Фон
                CustomCornerShape(radius: 20, corners: [.topLeft, .topRight])
                    .fill(Color.black.opacity(0.5))
                    .frame(height: 160)
                
                // Контент
                VStack(alignment: .leading, spacing: 12) {
                    // Назва кав'ярні
                    Text(coffeeShop.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                    
                    // Адреса
                    if let address = coffeeShop.address {
                        Text(address)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color("secondaryText"))
                            .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                    }
                    
                    // Робочий статус і години
                    statusAndHoursView
                    
                    // Інформація про замовлення
                    orderingInfoView
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .padding(.bottom, 0)
        }
    }
    
    /// Інформація про статус і робочі години
    private var statusAndHoursView: some View {
        HStack(spacing: 12) {
            // Статус відкрито/закрито
            StatusBadge(
                isActive: coffeeShop.isOpen,
                activeText: "Відкрито",
                inactiveText: "Закрито",
                activeColor: .green,
                inactiveColor: .red
            )
            
            // Показуємо робочі години
            if let workingHours = coffeeShop.workingHours {
                let calendar = Calendar.current
                let weekday = calendar.component(.weekday, from: Date()) - 1
                let weekdayString = String(weekday)
                
                if let todayHours = workingHours[weekdayString] {
                    if !todayHours.isClosed {
                        Text("\(todayHours.open) - \(todayHours.close)")
                            .font(.callout)
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    } else {
                        Text("Сьогодні вихідний")
                            .font(.callout)
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    /// Інформація про можливість попереднього замовлення
    private var orderingInfoView: some View {
        Group {
            if coffeeShop.allowScheduledOrders {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    Text("Можливе попереднє замовлення")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Preview
struct StretchableHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        StretchableHeaderView(coffeeShop: MockData.singleCoffeeShop)
            .frame(height: 320)
            .previewLayout(.sizeThatFits)
            .background(Color("backgroundColor"))
    }
}
