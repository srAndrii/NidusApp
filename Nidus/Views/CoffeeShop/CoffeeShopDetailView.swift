import SwiftUI
import Kingfisher

// MARK: - Головний View для екрану кав'ярні
struct CoffeeShopDetailView: View {
    // MARK: - Властивості
    let coffeeShop: CoffeeShop
    @StateObject private var viewModel = CoffeeShopDetailViewModel(coffeeShopRepository: DIContainer.shared.coffeeShopRepository)
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Константи
    private let backgroundColor = Color("backgroundColor")
    
    // MARK: - View
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Фон
            backgroundColor
                .ignoresSafeArea()
            
            // Головний контент
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Розтягувана шапка з зображенням і накладеною інформацією
                    StretchableHeaderView(coffeeShop: coffeeShop)
                        .frame(height: 320)
                    
                    // Контент на основі стану завантаження
                    contentView
                }
            }
            
            // Кнопка "Назад"
            BackButtonView()
                .padding(.top, 50) // Підняли кнопку, щоб не перекривалася статус-баром
        }
        .ignoresSafeArea(edges: .top)
        // Повністю ховаємо навігаційну панель
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadMenuGroups(coffeeShopId: coffeeShop.id)
        }
    }
    
    // MARK: - Допоміжні компоненти
    
    /// Відображає різний контент в залежності від стану завантаження
    private var contentView: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.menuGroups.isEmpty {
                emptyStateView
            } else {
                menuContentView
            }
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
    
    /// Відображає меню кав'ярні
    private var menuContentView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Фільтр категорій
            categoryFilterView
            
            // Меню кав'ярні - групи меню
            ForEach(viewModel.menuGroups) { group in
                MenuGroupView(group: group)
            }
        }
        .padding(.top, 5)
    }
    
    // Категорії для фільтрації
    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Кнопка "Всі"
                CategoryButton(
                    title: "Всі",
                    isSelected: true,
                    action: { /* Фільтрація */ }
                )
                
                // Кнопки категорій на основі груп меню
                ForEach(viewModel.menuGroups) { group in
                    CategoryButton(
                        title: group.name,
                        isSelected: false,
                        action: { /* Фільтрація для групи */ }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Preview
struct CoffeeShopDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CoffeeShopDetailView(coffeeShop: MockData.singleCoffeeShop)
                .environmentObject(AuthenticationManager())
                .preferredColorScheme(.dark)
        }
    }
}
