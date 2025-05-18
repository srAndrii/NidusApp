//
//  OffersView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 5/18/25.
//


import SwiftUI

struct OffersView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Фоновий градієнт
            Group {
                if colorScheme == .light {
                    ZStack {
                        // Основний горизонтальний градієнт
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("nidusCoolGray").opacity(0.9),
                                Color("nidusLightBlueGray").opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        
                        // Додатковий вертикальний градієнт для текстури
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("nidusCoolGray").opacity(0.15),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        // Тонкий шар кольору для затінення в кутах
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color("nidusCoolGray").opacity(0.2)
                            ]),
                            center: .bottomTrailing,
                            startRadius: UIScreen.main.bounds.width * 0.2,
                            endRadius: UIScreen.main.bounds.width
                        )
                    }
                } else {
                    // Для темного режиму використовуємо існуючий колір
                    Color("backgroundColor")
                }
            }
            .ignoresSafeArea()
            
            // Логотип як фон
            Image("Logo")
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
                .frame(width: UIScreen.main.bounds.width * 0.7)
                .saturation(1.5)
                .opacity(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Основний контент - заглушка
            VStack(spacing: 20) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 70))
                    .foregroundColor(Color("primary").opacity(0.8))
                
                Text("Спеціальні пропозиції")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color("primaryText"))
                
                Text("Незабаром тут з'являться спеціальні пропозиції та акції від кав'ярень!")
                    .font(.body)
                    .foregroundColor(Color("secondaryText"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                comingSoonView
            }
            .padding()
        }
        .navigationTitle("Пропозиції")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Компонент "Скоро з'явиться"
    private var comingSoonView: some View {
        VStack(spacing: 16) {
            Text("Скоро в Nidus!")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(
                    Capsule()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color("primary").opacity(0.8), Color("primary")]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                )
            
            // Іконки майбутніх можливостей
            HStack(spacing: 30) {
                VStack {
                    Image(systemName: "percent")
                        .font(.system(size: 28))
                        .foregroundColor(Color("primary"))
                    
                    Text("Знижки")
                        .font(.caption)
                        .foregroundColor(Color("secondaryText"))
                }
                
                VStack {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color("primary"))
                    
                    Text("Бонуси")
                        .font(.caption)
                        .foregroundColor(Color("secondaryText"))
                }
                
                VStack {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color("primary"))
                    
                    Text("Сповіщення")
                        .font(.caption)
                        .foregroundColor(Color("secondaryText"))
                }
            }
            .padding(.top, 12)
        }
        .padding(24)
        .background(
            ZStack {
                // Скляний фон
                BlurView(
                    style: colorScheme == .light ? .systemThinMaterial : .systemMaterialDark,
                    opacity: colorScheme == .light ? 0.95 : 0.95
                )
                // Додатково тонуємо під кольори застосунку
                Group {
                    if colorScheme == .light {
                        // Тонування для світлої теми з новими кольорами
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("nidusMistyBlue").opacity(0.25),
                                Color("nidusCoolGray").opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .opacity(0.4)
                        
                        // Додаткове тонування для ефекту глибини
                        Color("nidusLightBlueGray").opacity(0.12)
                    } else {
                        // Додатковий шар для глибини у темному режимі
                        Color.black.opacity(0.15)
                    }
                }
            }
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
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
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.top, 20)
    }
}

struct OffersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OffersView()
        }
    }
}
