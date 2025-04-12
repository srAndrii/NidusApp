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
        ZStack(alignment: .topLeading) { // Змінено alignment на .topLeading
            // Фон
            Color("backgroundColor")
                .edgesIgnoringSafeArea(.all)
            
            // Головний контент
            if #available(iOS 16.0, *) {
                // Для iOS 16+ з новою навігацією
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
            
            // Кнопка "Назад" - тепер з правильним вирівнюванням і кольором
            BackButtonView(color: Color("primary"), backgroundColor: Color.black.opacity(0.4))
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
                    
                    // Контент на основі стану завантаження
                    VStack(spacing: 0) {
                        if viewModel.isLoading {
                            loadingView
                                .padding(.top, 20)
                        } else if viewModel.menuGroups.isEmpty {
                            emptyStateView
                                .padding(.top, 20)
                        } else {
                            // Фільтр категорій із прокруткою
                            categoryFilterView(proxy: proxy)
                                .padding(.vertical, 8)
                                .background(Color("backgroundColor"))
                            
                            // Меню кав'ярні - групи меню з ідентифікаторами
                            VStack(spacing: 16) {
                                ForEach(viewModel.menuGroups) { group in
                                    MenuGroupView(group: group)
                                        .id(group.id) // Для прокрутки
                                }
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 16)
                            .background(Color("backgroundColor"))
                        }
                    }
                    .background(Color("backgroundColor"))
                }
            }
            .edgesIgnoringSafeArea(.top)
            .background(Color("backgroundColor"))
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
                            // Скролимо до початку
                            proxy.scrollTo("top", anchor: .top)
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
                                // Прокручуємо до відповідної групи
                                proxy.scrollTo(group.id, anchor: .top)
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
        guard let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            return EdgeInsets()
        }
        let safeAreaInsets = keyWindow.safeAreaInsets
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
