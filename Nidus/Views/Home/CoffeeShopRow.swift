//
//  CoffeeShopRow.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import SwiftUI
import Kingfisher

struct CoffeeShopRow: View {
    let coffeeShop: CoffeeShop
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationLink(destination: CoffeeShopDetailView(coffeeShop: coffeeShop)) {
            // Наша власна карточка
            ZStack {
                // Скляний фон
                RoundedRectangle(cornerRadius: 17)
                    .fill(Color.clear)
                    .overlay(
                        BlurView(
                            style: colorScheme == .light ? .systemThinMaterialDark : .systemMaterialDark,
                            opacity: colorScheme == .light ? 0.7 : 0.95
                        )
                    )
                    .overlay(
                        Group {
                            if colorScheme == .light {
                                // Тонування для світлої теми
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
                            } else {
                                // Темна тема
                                Color.black.opacity(0.15)
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 17))
                    .overlay(
                        RoundedRectangle(cornerRadius: 17)
                            .stroke(
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
                                ),
                                lineWidth: 1
                            )
                    )
                
                // Контент картки
                HStack(alignment: .center, spacing: 12) {
                    // Логотип (зображення або заглушка)
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("inputField"))
                            .frame(width: 80, height: 80)
                        
                        if let logoUrl = coffeeShop.logoUrl, let url = URL(string: logoUrl) {
                            KFImage(url)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 28))
                                .foregroundColor(Color("primary"))
                        }
                    }
                    
                    // Інформація про кав'ярню
                    VStack(alignment: .leading, spacing: 4) {
                        Text(coffeeShop.name)
                            .font(.headline)
                            .foregroundColor(Color("primaryText"))
                        
                        if let address = coffeeShop.address {
                            Text(address)
                                .font(.subheadline)
                                .foregroundColor(Color("secondaryText"))
                                .lineLimit(1)
                        }
                        
                        HStack(spacing: 12) {
                            // Відстань
                            if let distance = coffeeShop.distance {
                                HStack(spacing: 2) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("primary"))
                                    
                                    Text(formatDistance(distance))
                                        .font(.caption)
                                        .foregroundColor(Color("secondaryText"))
                                }
                            }
                            
                            // Робочі години
                            HStack(spacing: 2) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color("primary"))
                                
                                Text(getWorkingHours())
                                    .font(.caption)
                                    .foregroundColor(Color("secondaryText"))
                            }
                            
                            // Статус (відкрито/закрито)
                            HStack(spacing: 2) {
                                Circle()
                                    .fill(coffeeShop.isOpen ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                
                                Text(coffeeShop.isOpen ? "Відкрито" : "Закрито")
                                    .font(.caption)
                                    .foregroundColor(Color("secondaryText"))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Наша власна стрілка всередині карточки
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color("secondaryText"))
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.trailing, 8)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
            }
        }
        // Важливо: прибрати всі стилі кнопки та рядка, які можуть додавати зовнішню стрілку
        .buttonStyle(PlainButtonStyle())
        // Додаємо вертикальні відступи між карточками
        .padding(.vertical, 6)
        .frame(height: 100)
    }
    
    // Форматування відстані
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))м"
        } else {
            let kilometers = distance / 1000
            return String(format: "%.1f км", kilometers)
        }
    }
    
    // Отримання робочих годин
    private func getWorkingHours() -> String {
        if let workingHours = coffeeShop.workingHours,
           let todayPeriod = workingHours["1"] {  // Використовуємо "1" як заглушку для демо-даних
            return "\(todayPeriod.open) - \(todayPeriod.close)"
        }
        return "09:00 - 21:00"  // Значення за замовчуванням
    }
}

struct CoffeeShopRow_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color("backgroundColor")
                .edgesIgnoringSafeArea(.all)
                
            CoffeeShopRow(coffeeShop: CoffeeShop(
                id: "mock-1",
                name: "Кава на Подолі",
                address: "вул. Сагайдачного 15, Київ",
                logoUrl: nil,
                ownerId: nil,
                allowScheduledOrders: true,
                minPreorderTimeMinutes: 15,
                maxPreorderTimeMinutes: 120,
                workingHours: ["1": WorkingHoursPeriod(open: "08:00", close: "22:00", isClosed: false)],
                createdAt: Date(),
                updatedAt: Date(),
                distance: 350
            ))
            .previewLayout(.sizeThatFits)
            .padding()
        }
    }
}
