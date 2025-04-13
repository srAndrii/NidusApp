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
                    // Обгортаємо в додатковий координатор для стабільності скролінгу
                    ScrollingCoordinatorView {
                        scrollContentView
                    }
                    .navigationDestination(for: MenuItem.self) { item in
                        MenuItemDetailView(menuItem: item)
                    }
                }
                .navigationBarHidden(true)
            } else {
                // Для iOS 15 і раніше
                // Обгортаємо в додатковий координатор для стабільності скролінгу
                ScrollingCoordinatorView {
                    scrollContentView
                }
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
            
            // Додаємо затримку для перевірки готовності груп
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("📊 Перевірка завантажених груп:")
                for group in viewModel.menuGroups {
                    print("📊 Группа доступна: \(group.id), назва: \(group.name)")
                }
            }
        }
    }
    
    // MARK: - Головний скролабельний контент
    private var scrollContentView: some View {
        // Додаємо @EnvironmentObject для отримання стану скролінгу
        ScrollViewReader { proxy in
            print("🔍 ScrollViewReader створено")
            
            // Отримуємо стан скролінгу з середовища
            return GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    // Об'єднано весь контент в один VStack
                    VStack(spacing: 0) {
                        // Розтягувана шапка з зображенням і накладеною інформацією
                        StretchableHeaderView(coffeeShop: coffeeShop)
                            .frame(height: 320)
                            .id("top") // Ідентифікатор для прокрутки до верху
                            .onAppear {
                                print("🔍 StretchableHeaderView з'явився")
                            }

                        // Контент на основі стану завантаження
                        if viewModel.isLoading {
                            loadingView
                                .padding(.top, 20)
                        } else if viewModel.menuGroups.isEmpty {
                            emptyStateView
                                .padding(.top, 20)
                        } else {
                            // Фільтр категорій
                            categoryFilterView(proxy: proxy, geometry: geometry)

                            // Меню кав'ярні - групи меню з ідентифікаторами
                            VStack(spacing: 24) { // Збільшений відступ між групами для кращої візуальної ієрархії
                                ForEach(viewModel.menuGroups) { group in
                                    MenuGroupView(group: group)
                                        .id(group.id) // ID переміщено сюди для більш стабільної роботи ScrollViewReader
                                        .onAppear {
                                            print("🔍 MenuGroupView з'явився для групи: \(group.id)")
                                        }
                                }
                                
                                // Додаємо невидимий спейсер внизу для забезпечення додаткового місця під останньою групою
                                // особливо важливо для пристроїв з різними розмірами екрану
                                Spacer()
                                    .frame(height: 100) // Висота приблизно дорівнює висоті таб-бару з запасом
                                    .id("bottom_spacer")
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }
                    }
                }
                .edgesIgnoringSafeArea(.top)
                .background(Color("backgroundColor"))
                // Додаємо прослуховувач для ScrollState
                .onScrollStateChange(proxy: proxy)
            }
        }
    }
    
    // MARK: - Фільтр категорій
    private func categoryFilterView(proxy: ScrollViewProxy, geometry: GeometryProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Кнопка "Всі"
                CategoryButton(
                    title: "Всі",
                    isSelected: selectedCategory == nil,
                    action: {
                        // Спершу змінюємо стан без анімації
                        selectedCategory = nil
                        
                        print("🔍 Скролінг до верху (Всі категорії)")
                        
                        // Використовуємо EnvironmentObject для координації скролінгу
                        scrollToTop(proxy: proxy)
                    }
                )
                
                // Кнопки категорій з функцією прокрутки
                ForEach(viewModel.menuGroups) { group in
                    CategoryButton(
                        title: group.name,
                        isSelected: selectedCategory == group.id,
                        action: {
                            // Спершу змінюємо стан без анімації
                            selectedCategory = group.id
                            
                            print("🚀 Натиснуто кнопку для групи: \(group.id), назва: \(group.name)")
                            
                            // Використовуємо EnvironmentObject для координації скролінгу
                            scrollToGroup(id: group.id, proxy: proxy, geometry: geometry)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Допоміжні методи скролінгу
    
    // Скрол до верху
    private func scrollToTop(proxy: ScrollViewProxy) {
        withAnimation {
            proxy.scrollTo("top", anchor: .top)
        }
    }
    
    // Скрол до групи
    private func scrollToGroup(id: String, proxy: ScrollViewProxy, geometry: GeometryProxy) {
        let isLastGroup = id == viewModel.menuGroups.last?.id
        let anchor: UnitPoint = isLastGroup ? .bottom : .top
        
        // Скролінг з анімацією
        withAnimation(.easeInOut(duration: 0.5)) {
            proxy.scrollTo(id, anchor: anchor)
        }
        
        // Додаємо резервну логіку через невелику затримку для надійності
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if isLastGroup {
                // Для останньої групи скролимо до нашого спейсера
                proxy.scrollTo("bottom_spacer", anchor: .top)
            } else {
                // Для інших груп робимо резервний скрол
                withAnimation {
                    proxy.scrollTo(id, anchor: .top)
                }
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

// MARK: - Координатор скролінгу
struct ScrollingCoordinatorView<Content: View>: View {
    let content: Content
    @State private var selectedGroupId: String? = nil
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .environmentObject(ScrollState())
    }
}

// Стан скролінгу, який можна передавати через середовище
class ScrollState: ObservableObject {
    @Published var scrollToGroupId: String? = nil
    
    func scrollTo(groupId: String) {
        print("🌟 ScrollState: Запит на скроліг до групи \(groupId)")
        self.scrollToGroupId = groupId
        
        // Скидаємо ID після короткої затримки
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.scrollToGroupId = nil
        }
    }
}

// MARK: - Модифікатор для реагування на зміни в ScrollState
extension View {
    func onScrollStateChange(proxy: ScrollViewProxy) -> some View {
        self.modifier(ScrollStateChangeModifier(proxy: proxy))
    }
}

struct ScrollStateChangeModifier: ViewModifier {
    @EnvironmentObject private var scrollState: ScrollState
    let proxy: ScrollViewProxy
    
    func body(content: Content) -> some View {
        content
            .onChange(of: scrollState.scrollToGroupId) { id in
                if let groupId = id {
                    print("📜 ScrollStateChangeModifier: прокрутка до \(groupId)")
                    
                    // Спроба 1: негайна прокрутка
                    withAnimation {
                        proxy.scrollTo(groupId, anchor: .top)
                    }
                    
                    // Спроба 2: з затримкою для надійності
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo(groupId, anchor: .top)
                        }
                    }
                }
            }
    }
}
