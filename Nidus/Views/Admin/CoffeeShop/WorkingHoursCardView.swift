//
//  WorkingHoursCardView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/31/25.
//

import SwiftUI

struct WorkingHoursCardView: View {
    let coffeeShop: CoffeeShop
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Заголовок секції
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(Color("primary"))
                    .font(.system(size: 18))
                
                Text("Години роботи")
                    .font(.headline)
                    .foregroundColor(Color("primaryText"))
                
                Spacer()
                
                // Статус відкрито/закрито
                HStack(spacing: 4) {
                    Circle()
                        .fill(coffeeShop.isOpenBasedOnHours ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(coffeeShop.isOpenBasedOnHours ? "Відкрито" : "Закрито")
                        .font(.subheadline)
                        .foregroundColor(coffeeShop.isOpenBasedOnHours ? Color.green : Color.red)
                }
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(Color("secondaryText"))
                    .font(.system(size: 14))
                    .padding(.leading, 8)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            
            // Детальна інформація про години роботи
            if isExpanded {
                if let workingHours = coffeeShop.workingHours, !workingHours.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        // Перебираємо дні тижня
                        ForEach(0...6, id: \.self) { day in
                            if let dayKey = String(day), let period = workingHours[dayKey] {
                                HStack {
                                    Text(coffeeShop.getDayName(for: day))
                                        .font(.subheadline)
                                        .foregroundColor(Color("primaryText"))
                                        .frame(width: 120, alignment: .leading)
                                    
                                    if period.isClosed {
                                        Text("Зачинено")
                                            .font(.subheadline)
                                            .foregroundColor(Color.red)
                                    } else {
                                        Text("\(period.open) - \(period.close)")
                                            .font(.subheadline)
                                            .foregroundColor(Color("primaryText"))
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(.top, 4)
                } else {
                    Text("Інформація про години роботи відсутня")
                        .font(.subheadline)
                        .foregroundColor(Color("secondaryText"))
                        .padding(.top, 4)
                }
            } else {
                // Скорочена інформація про години роботи на сьогодні
                HStack {
                    Text("Сьогодні:")
                        .font(.subheadline)
                        .foregroundColor(Color("secondaryText"))
                    
                    Text(coffeeShop.getWorkingHoursForToday())
                        .font(.subheadline)
                        .foregroundColor(Color("primaryText"))
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color("cardColor"))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

// Допоміжний компонент для відображення на екрані детальної інформації про кав'ярню
struct CoffeeShopHoursSection: View {
    let coffeeShop: CoffeeShop
    @State private var isExpanded: Bool = false
    
    var body: some View {
        WorkingHoursCardView(
            coffeeShop: coffeeShop,
            isExpanded: isExpanded,
            onTap: { isExpanded.toggle() }
        )
        .padding(.horizontal)
    }
}
