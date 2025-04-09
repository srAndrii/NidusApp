import SwiftUI
import Kingfisher

struct CoffeeShopDetailView: View {
    // MARK: - Властивості
    let coffeeShop: CoffeeShop
    @StateObject private var viewModel = CoffeeShopDetailViewModel(coffeeShopRepository: DIContainer.shared.coffeeShopRepository)
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCategory: String? = nil
    
    // MARK: - Константи
    private let backgroundColor = Color("backgroundColor")
    
    // MARK: - View
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Фон
            backgroundColor
                .ignoresSafeArea()
            
            // Головний контент
            if #available(iOS 16.0, *) {
                // Використовуємо новий підхід до навігації для iOS 16+
                NavigationStack {
                    contentView
                        .navigationDestination(for: MenuItem.self) { item in
                            MenuItemDetailView(menuItem: item)
                        }
                }
                .navigationBarHidden(true)
            } else {
                // Використовуємо старий підхід для iOS 15 і раніше
                contentView
            }
            
            // Кнопка "Назад"
            BackButtonView()
                .padding(.top, 50)
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadMenuGroups(coffeeShopId: coffeeShop.id)
        }
    }
    
    // MARK: - Головний контент
    private var contentView: some View {
        ScrollViewReader { proxy in // Додаємо ScrollViewReader
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Розтягувана шапка з зображенням і накладеною інформацією
                    StretchableHeaderView(coffeeShop: coffeeShop)
                        .frame(height: 320)
                        .id("top") // Ідентифікатор для прокрутки до верху
                    
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
                                .id(group.id) // Важливо: додаємо ідентифікатор для прокрутки
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Допоміжні компоненти
    
    // Мофікований фільтр категорій із прокруткою
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
        .background(Color("backgroundColor"))
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
}
