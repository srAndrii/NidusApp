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
                // Використовуємо NavigationStack для iOS 16+
                NavigationStack {
                    scrollContentView
                        .navigationDestination(for: MenuItem.self) { item in
                            MenuItemDetailView(menuItem: item)
                        }
                }
                .navigationBarHidden(true)
            } else {
                // Для iOS 15 і раніше
                scrollContentView
            }
            
            // Кнопка "Назад"
            BackButtonView()
                .padding(.top, getSafeAreaInsets().top + 10)
                .padding(.leading, 16)
                .zIndex(2) // Щоб кнопка була над всіма іншими елементами
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadMenuGroups(coffeeShopId: coffeeShop.id)
        }
    }
    
    // MARK: - Головний скролабельний контент
    private var scrollContentView: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Розтягувана шапка з зображенням і накладеною інформацією
                    StretchableHeaderView(coffeeShop: coffeeShop)
                        .frame(height: 320)
                        .id("top") // Ідентифікатор для прокрутки до верху
                        .registerGroupOffset(id: "top") // Додано для ScrollingManager
                    
                    // Контент на основі стану завантаження
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.menuGroups.isEmpty {
                        emptyStateView
                    } else {
                        // Фільтр категорій - тепер із прокруткою
                        categoryFilterView(proxy: proxy)
                        
                        // Меню кав'ярні - групи меню з ідентифікаторами
                        ForEach(viewModel.menuGroups) { group in
                            MenuGroupView(group: group)
                                .id(group.id) // Для стандартного scrollTo
                                .registerGroupOffset(id: group.id) // Додано для ScrollingManager
                        }
                    }
                }
            }
            .findScrollView() // Додано для знаходження UIScrollView
        }
    }
    
    // MARK: - Фільтр категорій
    private func categoryFilterView(proxy: ScrollViewProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Кнопка "Всі"
                CategoryButton(
                    title: "Всі",
                    isSelected: selectedCategory == nil,
                    action: {
                        withAnimation {
                            selectedCategory = nil
                            
                            // Використовуємо обидва підходи для надійності
                            proxy.scrollTo("top", anchor: .top)
                            ScrollingManager.shared.scrollToGroup(id: "top")
                        }
                    }
                )
                
                // Кнопки категорій з функцією прокрутки
                ForEach(viewModel.menuGroups) { group in
                    CategoryButton(
                        title: group.name,
                        isSelected: selectedCategory == group.id,
                        action: {
                            withAnimation(.spring()) {
                                selectedCategory = group.id
                                
                                // Використовуємо обидва підходи для надійності
                                proxy.scrollTo(group.id, anchor: .top)
                                
                                // Використовуємо затримку для ScrollingManager
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    ScrollingManager.shared.scrollToGroup(id: group.id)
                                }
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
