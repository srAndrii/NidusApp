import SwiftUI
import Kingfisher
import Combine

// MARK: - Головний View для екрану кав'ярні
struct CoffeeShopDetailView: View {
    let coffeeShop: CoffeeShop
    @StateObject private var viewModel = CoffeeShopDetailViewModel(coffeeShopRepository: DIContainer.shared.coffeeShopRepository)
    
    // Темний фон
    private let backgroundColor = Color("backgroundColor") // замість Color(hex:)
    
    var body: some View {
        ZStack {
            // Фон
            backgroundColor
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Розтягувана шапка з зображенням і накладеною інформацією
                    StretchableHeaderView(coffeeShop: coffeeShop)
                        .frame(height: 320)
                    
                    // Якщо ще завантажуються дані
                    if viewModel.isLoading {
                        ProgressView("Завантаження меню...")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                            .foregroundColor(Color("primaryText"))
                    } else if viewModel.menuGroups.isEmpty {
                        // Якщо дані порожні
                        Text("Меню недоступне")
                            .font(.headline)
                            .foregroundColor(Color("secondaryText"))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else {
                        // Категорії
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
                }
            }
        }
        .ignoresSafeArea(edges: .top) // Ігноруємо Safe Area для верхньої частини
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(coffeeShop.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("primaryText"))
            }
        }
        .onAppear {
            viewModel.loadMenuGroups(coffeeShopId: coffeeShop.id)
        }
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

// MARK: - Розтягувана шапка з зображенням
struct StretchableHeaderView: View {
    let coffeeShop: CoffeeShop
    
    var body: some View {
        GeometryReader { geometry in
            let minHeight: CGFloat = 300 // Мінімальна висота зображення
            let scrollY = geometry.frame(in: .global).minY
            let scrollYOffset = max(0, scrollY)
            let headerHeight = minHeight + scrollYOffset // Збільшуємо висоту при прокрутці вниз
            
            ZStack(alignment: .bottom) {
                // Зображення або заглушка з ефектом розтягування
                if let logoUrl = coffeeShop.logoUrl, let url = URL(string: logoUrl) {
                    KFImage(url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: headerHeight)
                        .offset(y: -scrollYOffset/2) // Ефект паралаксу
                        .clipped()
                } else {
                    ZStack {
                        Rectangle()
                            .fill(Color("cardColor").opacity(0.7))
                            .frame(width: geometry.size.width, height: headerHeight)
                            .offset(y: -scrollYOffset/2)
                        
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("primary"))
                    }
                }
                
                // Напівпрозорий блок з інформацією
                VStack(spacing: 0) {
                    // Інформаційний блок із заокругленими верхніми кутами
                    ZStack {
                        // Напівпрозорий фон із заокругленнями лише зверху
                        CustomCornerShape(radius: 20, corners: [.topLeft, .topRight])
                            .fill(Color.black.opacity(0.5))
                            .frame(height: 160)
                        
                        // Інформація про кав'ярню
                        VStack(alignment: .leading, spacing: 12) {
                            // Назва кав'ярні
                            Text(coffeeShop.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                            
                            // Адреса
                            if let address = coffeeShop.address {
                                Text(address)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                            }
                            
                            // Статусна інформація (відкрито/закрито, години)
                            HStack(spacing: 12) {
                                // Статус відкрито/закрито
                                StatusBadge(
                                    isActive: coffeeShop.isOpen,
                                    activeText: "Відкрито",
                                    inactiveText: "Закрито",
                                    activeColor: .green,
                                    inactiveColor: .red
                                )
                                
                                // Показуємо робочі години
                                if let workingHours = coffeeShop.workingHours {
                                    let calendar = Calendar.current
                                    let weekday = calendar.component(.weekday, from: Date()) - 1
                                    let weekdayString = String(weekday)
                                    
                                    if let todayHours = workingHours[weekdayString] {
                                        if !todayHours.isClosed {
                                            Text("\(todayHours.open) - \(todayHours.close)")
                                                .font(.callout)
                                                .foregroundColor(.white)
                                                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                                        } else {
                                            Text("Сьогодні вихідний")
                                                .font(.callout)
                                                .foregroundColor(.white)
                                                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            
                            // Можливість попереднього замовлення
                            if coffeeShop.allowScheduledOrders {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.white.opacity(0.9))
                                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                                    
                                    Text("Можливе попереднє замовлення")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                    .padding(.bottom, 0)
                }
            }
            .frame(width: geometry.size.width, height: max(minHeight, headerHeight))
        }
    }
}

// MARK: - Компонент для кнопки категорії
struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.callout)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? Color("primary") : Color("secondaryText"))
                
                // Індикатор вибраної категорії
                if isSelected {
                    Circle()
                        .fill(Color("primary"))
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
        }
    }
}

// MARK: - Компонент для відображення статусу
struct StatusBadge: View {
    let isActive: Bool
    let activeText: String
    let inactiveText: String
    let activeColor: Color
    let inactiveColor: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? activeColor : inactiveColor)
                .frame(width: 8, height: 8)
            
            Text(isActive ? activeText : inactiveText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isActive ? activeColor : inactiveColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            (isActive ? activeColor : inactiveColor)
                .opacity(0.1)
                .cornerRadius(12)
        )
    }
}

// Компонент для створення заокруглень тільки з вказаних сторін
struct CustomCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Компонент для відображення групи меню
struct MenuGroupView: View {
    let group: MenuGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Заголовок групи
            HStack {
                Text(group.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color("primaryText"))
                
                Spacer()
                
                // Кнопка "Показати всі"
                Button(action: {
                    // Дія для переходу до всіх пунктів категорії
                }) {
                    Text("Всі")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("primary"))
                }
            }
            .padding(.horizontal, 16)
            
            if let description = group.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Color("secondaryText"))
                    .padding(.horizontal, 16)
                    .padding(.top, -8)
            }
            
            // Горизонтальний скрол з пунктами меню
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if let menuItems = group.menuItems, !menuItems.isEmpty {
                        ForEach(menuItems) { item in
                            MenuItemCard(item: item)
                        }
                    } else {
                        // Показати заглушку, якщо немає пунктів меню
                        ZStack {
                            RoundedRectangle(cornerRadius: 23)
                                .fill(Color("cardColor"))
                                .frame(width: 170, height: 250)
                            
                            VStack(spacing: 12) {
                                Image(systemName: "cup.and.saucer")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color("secondaryText"))
                                
                                Text("Немає доступних пунктів")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("secondaryText"))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .padding(.bottom, 10)
        }
    }
}

struct MenuItemCard: View {
    let item: MenuItem
    
    // Використовуємо визначені кольори з проекту
    private var cardGradient: LinearGradient {
        return LinearGradient(
            gradient: Gradient(colors: [Color("cardTop"), Color("cardBottom")]),
            startPoint: .top,
            endPoint: .bottomTrailing
        )
    }
    
    // Градієнт для кнопки додавання (оранжевий)
    private let addButtonGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color("primary").opacity(0.8),
            Color("primary")
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        Button(action: {
            // Дія для переходу до детального перегляду товару
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Зображення з рейтингом
                ZStack(alignment: .topTrailing) {
                    // Зображення
                    if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                        KFImage(url)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 125, height: 125)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color("cardColor").opacity(0.7))
                                .frame(width: 150, height: 150)
                            
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color("primary"))
                        }
                    }
                }
                
                // Назва та опис у фіксованій рамці
                VStack(alignment: .leading, spacing: 4) {
                    // Назва товару
                    Text(item.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.white)
                    
                    // Опис (якщо є) з фіксованою висотою
                    if let description = item.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(Color.gray)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    } else {
                        // Пустий текст для збереження висоти
                        Text("")
                            .font(.caption)
                            .foregroundColor(.clear)
                    }
                }
                .frame(height: 55) // Фіксована висота для блоку назви та опису
                .padding(.top, 5) // Додали паддінг між зображенням і текстом
                
                Spacer()
                
                // Ціна та кнопка додавання
                HStack {
                    // Ціна
                    Text("₴ \(formatPrice(item.price))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("primary"))
                    
                    Spacer()
                    
                    // Кнопка додавання
                    Button(action: {
                        // Дія для додавання в кошик
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(addButtonGradient)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                // Змінено нижній паддінг для балансу
                .padding(.bottom, 6) // Було 8
            }
            // Однаковий паддінг зі всіх сторін
            .padding(5)
            .frame(width: 135, height: 255) // Фіксована висота всієї карточки
            .background(cardGradient) // Використовуємо градієнт
            .cornerRadius(25)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            // Якщо товар недоступний, робимо його напівпрозорим
            .opacity(item.isAvailable ? 1.0 : 0.5)
            .overlay(
                Group {
                    if !item.isAvailable {
                        Text("Недоступно")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                    }
                },
                alignment: .center
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Форматування ціни без копійок
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        return formatter.string(from: NSDecimalNumber(decimal: price)) ?? "\(price)"
    }
}

// MARK: - Preview Provider з MockViewModel
struct CoffeeShopDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MockCoffeeShopDetailView(coffeeShop: previewCoffeeShop)
                .environmentObject(AuthenticationManager())
        }
    }
    
    // MockView з готовими даними
    struct MockCoffeeShopDetailView: View {
        let coffeeShop: CoffeeShop
        @StateObject private var viewModel = MockViewModel()
        
        private let backgroundColor = Color("backgroundColor")
        
        var body: some View {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Верхня частина з StretchableHeaderView залишається без змін
                        StretchableHeaderView(coffeeShop: coffeeShop)
                            .frame(height: 300)
                        
                        // Категорії
                        VStack(alignment: .leading, spacing: 5) {
                            // Фільтр категорій
                            categoryFilterView
                            
                            // Меню кав'ярні - групи меню
                            ForEach(viewModel.menuGroups) { group in
                                MenuGroupView(group: group)
                            }
                        }
                        .padding(.top, 7)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(coffeeShop.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("primaryText"))
                }
            }
        }
        
        // Фільтр категорій - такий самий як в оригіналі
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
    
    // Mock ViewModel з готовими даними
    class MockViewModel: ObservableObject {
        @Published var menuGroups: [MenuGroup] = previewMenuGroups
        @Published var isLoading: Bool = false
        
        func loadMenuGroups(coffeeShopId: String) {
            // Нічого не робимо, дані вже завантажені
        }
    }
    
    // Тестова кав'ярня
    static var previewCoffeeShop: CoffeeShop {
        CoffeeShop(
            id: "mock-1",
            name: "Кав'ярня Власника",
            address: "вул. Хрещатик, 31",
            logoUrl: "https://res.cloudinary.com/dlbbjiuco/image/upload/v1741643259/nidus/defaults/coffee-shop-logo.png",
            ownerId: "owner-1",
            allowScheduledOrders: true,
            minPreorderTimeMinutes: 15,
            maxPreorderTimeMinutes: 120,
            workingHours: [
                "0": WorkingHoursPeriod(open: "09:00", close: "20:00", isClosed: true),
                "1": WorkingHoursPeriod(open: "09:00", close: "21:00", isClosed: false),
                "2": WorkingHoursPeriod(open: "09:00", close: "21:00", isClosed: false),
                "3": WorkingHoursPeriod(open: "09:00", close: "21:00", isClosed: false),
                "4": WorkingHoursPeriod(open: "09:00", close: "21:00", isClosed: false),
                "5": WorkingHoursPeriod(open: "09:00", close: "22:00", isClosed: false),
                "6": WorkingHoursPeriod(open: "10:00", close: "20:00", isClosed: false)
            ],
            createdAt: Date(),
            updatedAt: Date(),
            menuGroups: previewMenuGroups
        )
    }
    
    // Групи меню для тестування
    static var previewMenuGroups: [MenuGroup] {
        [
            // Гарячі напої
            MenuGroup(
                id: "group-1",
                name: "Гарячі напої",
                description: "Різноманітні види кави та інші гарячі напої",
                displayOrder: 1,
                coffeeShopId: "mock-1",
                menuItems: [
                    MenuItem(
                        id: "item-1",
                        name: "Cappuccino",
                        price: 99.0,
                        description: "With Steamed Milk",
                        imageUrl: nil,
                        isAvailable: true,
                        menuGroupId: "group-1",
                        createdAt: Date(),
                        updatedAt: Date()
                    ),
                    MenuItem(
                        id: "item-2",
                        name: "Espresso",
                        price: 51.0,
                        description: "Double shot",
                        imageUrl: nil,
                        isAvailable: true,
                        menuGroupId: "group-1",
                        createdAt: Date(),
                        updatedAt: Date()
                    ),
                    MenuItem(
                        id: "item-3",
                        name: "Latte",
                        price: 110.0,
                        description: "With Extra Milk",
                        imageUrl: nil,
                        isAvailable: true,
                        menuGroupId: "group-1",
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                ],
                createdAt: Date(),
                updatedAt: Date()
            ),
            
            // Холодні напої
            MenuGroup(
                id: "group-2",
                name: "Холодні напої",
                description: "Освіжаючі холодні кавові напої",
                displayOrder: 2,
                coffeeShopId: "mock-1",
                menuItems: [
                    MenuItem(
                        id: "item-4",
                        name: "Ice Latte",
                        price: 120.0,
                        description: "Cold and Refreshing",
                        imageUrl: nil,
                        isAvailable: true,
                        menuGroupId: "group-2",
                        createdAt: Date(),
                        updatedAt: Date()
                    ),
                    MenuItem(
                        id: "item-5",
                        name: "Iced Americano",
                        price: 90.0,
                        description: "With ice cubes",
                        imageUrl: nil,
                        isAvailable: false,
                        menuGroupId: "group-2",
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                ],
                createdAt: Date(),
                updatedAt: Date()
            ),
            
            // Десерти
            MenuGroup(
                id: "group-3",
                name: "Десерти",
                description: "Смачні десерти до кави",
                displayOrder: 3,
                coffeeShopId: "mock-1",
                menuItems: [
                    MenuItem(
                        id: "item-6",
                        name: "Cheesecake",
                        price: 130.0,
                        description: "Classic NY style",
                        imageUrl: nil,
                        isAvailable: true,
                        menuGroupId: "group-3",
                        createdAt: Date(),
                        updatedAt: Date()
                    ),
                    MenuItem(
                        id: "item-7",
                        name: "Croissant",
                        price: 85.0,
                        description: "Butter croissant",
                        imageUrl: nil,
                        isAvailable: true,
                        menuGroupId: "group-3",
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                ],
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }
}
