import SwiftUI

struct MainView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var tabBarManager: TabBarManager
    
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
            
            // TabView - основний контент з оновленим порядком вкладок (без вкладки корзини)
            TabView(selection: $tabBarManager.selectedTab) {
                // 1. Вкладка "Кав'ярні"
                NavigationView {
                    // Використовуємо ID для ідентифікації навігації
                    // Коли значення navigationId змінюється, це призводить до відтворення навігаційного
                    // стеку спочатку, що призведе до скидання до кореневого екрану
                    HomeView()
                        .id(tabBarManager.navigationId)
                        .environmentObject(tabBarManager)
                }
                .tabItem {
                    Label("Кав'ярні", systemImage: "cup.and.saucer.fill")
                }
                .tag(TabSelection.coffeeShops)
                
                // 2.
                NavigationView {
                    OffersView()
                }
                .tabItem {
                    Label("Пропозиції", systemImage: "tag.fill")
                }
                .tag(TabSelection.offers)
                
                // 3.
                
                NavigationView {
                    QRCodeView()
                }
                .tabItem {
                    Label("Мій код", systemImage: "qrcode")
                }
                .tag(TabSelection.qrCode)
                
                // Вкладку корзини видаляємо, будемо використовувати окрему кнопку
                
                // 4. Мої замовлення (нова)
                NavigationView {
                         OrderHistoryView()
                }
                             .tabItem {
                    Label("Мої замовлення", systemImage: "list.clipboard")
                             }
                .tag(TabSelection.orders)
               
                
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
            .onChange(of: tabBarManager.selectedTab) { newTab in
                // Використовуємо модифікований метод для обробки вибору вкладки
                tabBarManager.handleTabSelection(newTab)
            }
            
            // Оверлей для кнопки корзини
            VStack {
                Spacer()
                
                // Кнопка корзини з бейджем (відображається над TabBar)
                if tabBarManager.cartItemsCount > 0 {
                    HStack {
                        Spacer() // Переміщуємо кнопку вправо
                        
                        ZStack(alignment: .topTrailing) {
                            Button(action: {
                                tabBarManager.isCartSheetPresented = true
                            }) {
                                ZStack {
                                    // Анімаційні кільця пульсації (як круги на воді)
                                    ForEach(0..<3, id: \.self) { index in
                                        Circle()
                                            .stroke(Color("primary"), lineWidth: 3)
                                            .frame(width: 60, height: 60)
                                            .scaleEffect(tabBarManager.shouldAnimateCart ? 2.0 + CGFloat(index) * 0.5 : 1.0)
                                            .opacity(tabBarManager.shouldAnimateCart ? 0.0 : 0.6)
                                            .animation(
                                                .easeOut(duration: 1.0)
                                                .delay(Double(index) * 0.15), 
                                                value: tabBarManager.shouldAnimateCart
                                            )
                                    }
                                    
                                    // Основна іконка кошика
                                    Image(systemName: "cart.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(Color("primary"))
                                        .frame(width: 60, height: 50)
                                        .background(
                                            Circle()
                                                .fill(Color.clear)
                                                .overlay(
                                                    BlurView(
                                                        style: colorScheme == .light ? .systemThinMaterial : .systemMaterialDark,
                                                        opacity: colorScheme == .light ? 0.95 : 0.95
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
                                                .clipShape(Circle())
                                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                        )
                                        .scaleEffect(tabBarManager.shouldAnimateCart ? 1.15 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: tabBarManager.shouldAnimateCart)
                                }
                            }
                            
                            // Бейдж для кількості товарів
                            Text("\(tabBarManager.cartItemsCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 18, height: 18)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 5, y: -5)
                        }
                        .padding(.trailing, 20) // Додаємо відступ справа
                    }
                    .padding(.bottom, 70) // Розташовуємо над TabBar
                }
            }
            
            // Sheet для корзини
            .sheet(isPresented: $tabBarManager.isCartSheetPresented) {
                NavigationView {
                    CartView()
                        .environmentObject(tabBarManager)
                }
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(AuthenticationManager())
            .environmentObject(DIContainer.shared.tabBarManager)
    }
}
