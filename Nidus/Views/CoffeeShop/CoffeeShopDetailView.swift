import SwiftUI
import Kingfisher

struct CoffeeShopDetailView: View {
    // MARK: - Властивості
    let coffeeShop: CoffeeShop
    @StateObject private var viewModel = CoffeeShopDetailViewModel(coffeeShopRepository: DIContainer.shared.coffeeShopRepository)
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: String? = nil
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var tabBarManager: TabBarManager
    
    // MARK: - View
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Головний контент
            NavigationStack {
                ZStack(alignment: .topLeading) {
                    mainContentView
                    
                    // Кнопка "Назад" - оновлена для використання dismiss
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("primary"))
                            .padding(10)
                            .background(Circle().fill(Color.black.opacity(0.4)))
                            .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                    }
                    .padding(.top, 8)
                    .padding(.leading, 12)
                    .zIndex(2) // Щоб кнопка була над всіма іншими елементами
                }
                .navigationDestination(for: MenuItem.self) { item in
                    MenuItemDetailView(menuItem: item)
                        .environmentObject(tabBarManager)
                }
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarHidden(true)
        .onAppear {
            print("📱 CoffeeShopDetailView з'явився")
            viewModel.loadMenuGroups(coffeeShopId: coffeeShop.id)
        }
    }
    
    // MARK: - Основний контент
    private var mainContentView: some View {
        ZStack {
            // Базовий фон
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
            .navigationBarHidden(true)
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
            
            // Головний контент
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Розтягувана шапка з зображенням і накладеною інформацією
                    StretchableHeaderView(coffeeShop: coffeeShop)
                        .frame(height: 300)
                    
                    // Контент на основі стану завантаження
                    if viewModel.isLoading {
                        loadingView
                            .padding(.top, 20)
                    } else if viewModel.menuGroups.isEmpty {
                        emptyStateView
                            .padding(.top, 20)
                    } else {
                        // Фільтр категорій
                        categoryFilterView()
                        
                        // Меню кав'ярні - групи меню з фільтрацією
                        VStack(spacing: 16) {
                            ForEach(viewModel.menuGroups) { group in
                                if selectedCategory == nil || selectedCategory == group.id {
                                    MenuGroupView(
                                        group: group,
                                        coffeeShopId: coffeeShop.id,
                                        coffeeShopName: coffeeShop.name
                                    )
                                    .transition(.opacity)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                        .animation(.easeInOut(duration: 0.3), value: selectedCategory)
                    }
                }
            }
            .edgesIgnoringSafeArea(.top)
        }
    }
    
    // MARK: - Фільтр категорій
    private func categoryFilterView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Кнопка "Всі"
                CategoryButton(
                    title: "Всі",
                    isSelected: selectedCategory == nil,
                    action: {
                        withAnimation {
                            selectedCategory = nil
                        }
                    }
                )
                
                // Кнопки категорій для фільтрації
                ForEach(viewModel.menuGroups) { group in
                    CategoryButton(
                        title: group.name,
                        isSelected: selectedCategory == group.id,
                        action: {
                            withAnimation {
                                selectedCategory = group.id
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }
    
    /// Показує індикатор завантаження
    private var loadingView: some View {
        ProgressView("Завантаження меню...")
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 40)
            .foregroundColor(Color("primaryText"))
    }
    
    /// Показує стан, коли немає даних
    private var emptyStateView: some View {
        Text("Меню недоступне")
            .font(.headline)
            .foregroundColor(Color("secondaryText"))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 40)
    }
    
    // Функція для отримання відступів безпечної зони
    private func getSafeAreaInsets() -> EdgeInsets {
        // Виправлений доступ до windows для iOS 15+
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return EdgeInsets()
        }
        
        let safeAreaInsets = window.safeAreaInsets
        return EdgeInsets(
            top: safeAreaInsets.top,
            leading: safeAreaInsets.left,
            bottom: safeAreaInsets.bottom,
            trailing: safeAreaInsets.right
        )
    }
}

// MARK: - Preview
struct CoffeeShopDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CoffeeShopDetailView(coffeeShop: MockData.singleCoffeeShop)
            .environmentObject(AuthenticationManager())
    }
}
