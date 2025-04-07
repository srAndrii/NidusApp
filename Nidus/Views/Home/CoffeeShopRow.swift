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
    
    var body: some View {
        NavigationLink(destination: CoffeeShopDetailView(coffeeShop: coffeeShop)) {
            VStack {
                HStack(alignment: .center, spacing: 12) {
                    // Логотип (зображення або заглушка)
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("inputField"))
                            .frame(width: 70, height: 70)
                        
                        if let logoUrl = coffeeShop.logoUrl, let url = URL(string: logoUrl) {
                            KFImage(url)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 70, height: 70)
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
                            
                            // Статус (відкрито/закрито) - тепер використовуємо обчислювану властивість
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
                    
                    // Стрілка "вперед"
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color("secondaryText"))
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.trailing, 4)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
            }
            .background(Color("cardColor"))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle()) // Щоб прибрати стандартне підсвічування NavigationLink
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
        .background(Color("backgroundColor"))
    }
}
