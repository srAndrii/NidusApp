// Nidus/Views/MainView.swift
import SwiftUI

struct MainView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var tabBarManager = DIContainer.shared.tabBarManager
    
    var body: some View {
        ZStack {
            // Спочатку встановлюємо базовий колір фону
            Group {
                if colorScheme == .light {
                    // Для світлої теми використовуємо нові кольори: nidusCoolGray, nidusMistyBlue та nidusLightBlueGray
                    ZStack {
                        // Основний горизонтальний градієнт з більшим акцентом на сірі відтінки
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
            .edgesIgnoringSafeArea(.all)
            
            // Логотип як фон
            Image("Logo")
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
                .frame(width: UIScreen.main.bounds.width * 0.7)
                .saturation(1.5)
                .opacity(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // TabView - основний контент з оновленим порядком вкладок
            TabView(selection: $tabBarManager.selectedTab) {
                // 1. Вкладка "Кав'ярні"
                NavigationView {
                    HomeView()
                        .environmentObject(tabBarManager)
                }
                .tabItem {
                    Label("Кав'ярні", systemImage: "cup.and.saucer.fill")
                }
                .tag(TabSelection.coffeeShops)
                
                // 2. Вкладка "QR-код"
                NavigationView {
                    QRCodeView()
                }
                .tabItem {
                    Label("Мій код", systemImage: "qrcode")
                }
                .tag(TabSelection.qrCode)
                
                // 3. Вкладка "Корзина" (нова, центральна)
                NavigationView {
                    CartView()
                        .environmentObject(tabBarManager)
                }
                .tabItem {
                    Label("Корзина", systemImage: "cart.fill")
                }
                .tag(TabSelection.cart)
                
                // 4. Вкладка "Пропозиції" (нова)
                NavigationView {
                    OffersView()
                }
                .tabItem {
                    Label("Пропозиції", systemImage: "tag.fill")
                }
                .tag(TabSelection.offers)
                
                // 5. Вкладка "Профіль"
                NavigationView {
                    ProfileView()
                }
                .tabItem {
                    Label("Профіль", systemImage: "person.fill")
                }
                .tag(TabSelection.profile)
            }
            .accentColor(Color("primary")) // Оранжевий колір для активних елементів
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(AuthenticationManager())
    }
}
