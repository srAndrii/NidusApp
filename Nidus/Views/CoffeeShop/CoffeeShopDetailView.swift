import SwiftUI
import Kingfisher

struct CoffeeShopDetailView: View {
    // MARK: - Властивості
    let coffeeShop: CoffeeShop
    @StateObject private var viewModel = CoffeeShopDetailViewModel(coffeeShopRepository: DIContainer.shared.coffeeShopRepository)
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCategory: String? = nil
    
    // MARK: - View
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Фон
            Color("backgroundColor")
                .edgesIgnoringSafeArea(.all)
            
            // Головний контент
            if #available(iOS 16.0, *) {
                // Для iOS 16+ з новою навігацією
                NavigationStack {
                    mainContentView
                        .navigationDestination(for: MenuItem.self) { item in
                            MenuItemDetailView(menuItem: item)
                        }
                }
                .navigationBarHidden(true)
            } else {
                // Для iOS 15 і раніше
                mainContentView
            }
            
            // Кнопка "Назад" - тепер з правильним вирівнюванням і кольором
            BackButtonView(color: Color("primary"), backgroundColor: Color.black.opacity(0.4))
                .padding(.top, getSafeAreaInsets().top + 10)
                .padding(.leading, 16)
                .zIndex(2) // Щоб кнопка була над всіма іншими елементами
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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Розтягувана шапка з зображенням і накладеною інформацією
                StretchableHeaderView(coffeeShop: coffeeShop)
                    .frame(height: 320)
                
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
                    VStack(spacing: 24) {
                        ForEach(viewModel.menuGroups) { group in
                            if selectedCategory == nil || selectedCategory == group.id {
                                MenuGroupView(group: group)
                                    .transition(.opacity)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .animation(.easeInOut(duration: 0.3), value: selectedCategory)
                }
            }
        }
        .edgesIgnoringSafeArea(.top)
        .background(Color("backgroundColor"))
    }
    
    // MARK: - Фільтр категорій
    private func categoryFilterView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
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
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
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
            .preferredColorScheme(.dark)
    }
}
