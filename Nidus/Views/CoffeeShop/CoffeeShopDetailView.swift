import SwiftUI
import Kingfisher
import Combine

// MARK: - Головний View для екрану кав'ярні
struct CoffeeShopDetailView: View {
    let coffeeShop: CoffeeShop
    @StateObject private var viewModel = CoffeeShopDetailViewModel(coffeeShopRepository: DIContainer.shared.coffeeShopRepository)
    
    // Темний фон
    private let backgroundColor = Color(hex: "#121212")
    
    var body: some View {
        ZStack {
            // Фон
            backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Шапка з зображенням та інформацією про кав'ярню
                    headerView
                    
                    // Інформація про кав'ярню
                    infoView
                    
                    // Розділювач
                    Divider()
                        .background(Color("secondaryText").opacity(0.2))
                        .padding(.vertical, 10)
                    
                    // Якщо ще завантажуються дані
                    if viewModel.isLoading {
                        ProgressView("Завантаження меню...")
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
                        VStack(alignment: .leading, spacing: 24) {
                            // Фільтр категорій (як у Starbucks)
                            categoryFilterView
                            
                            // Меню кав'ярні - групи меню
                            ForEach(viewModel.menuGroups) { group in
                                MenuGroupView(group: group)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(coffeeShop.name)
                    .font(.headline)
                    .foregroundColor(Color("primaryText"))
            }
        }
        .onAppear {
            viewModel.loadMenuGroups(coffeeShopId: coffeeShop.id)
        }
    }
    
    // Шапка з зображенням та загальною інформацією
    private var headerView: some View {
        ZStack(alignment: .bottom) {
            // Фонове зображення або заглушка
            if let logoUrl = coffeeShop.logoUrl, let url = URL(string: logoUrl) {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color(hex: "#2D3748"))
                    .frame(height: 200)
                
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color("primary"))
            }
            
            // Градієнт для покращення читабельності тексту
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0)]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 100)
            
            // Назва кав'ярні
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(coffeeShop.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    if let address = coffeeShop.address {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
    
    // Блок з інформацією про кав'ярню
    private var infoView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Статус (відкрито/закрито)
            HStack(spacing: 12) {
                StatusBadge(
                    isActive: coffeeShop.isOpen,
                    activeText: "Відкрито",
                    inactiveText: "Закрито",
                    activeColor: .green,
                    inactiveColor: .red
                )
                
                if let workingHours = coffeeShop.workingHours {
                    // Показуємо сьогоднішні години роботи
                    let calendar = Calendar.current
                    let weekday = calendar.component(.weekday, from: Date()) - 1
                    let weekdayString = String(weekday)
                    
                    if let todayHours = workingHours[weekdayString] {
                        if !todayHours.isClosed {
                            Text("\(todayHours.open) - \(todayHours.close)")
                                .font(.subheadline)
                                .foregroundColor(Color("secondaryText"))
                        } else {
                            Text("Сьогодні вихідний")
                                .font(.subheadline)
                                .foregroundColor(Color("secondaryText"))
                        }
                    }
                }
                
                Spacer()
                
                // Кнопка "Замовити"
                Button(action: {
                    // Дія для замовлення
                }) {
                    Text("Замовити")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color("primary"))
                        .cornerRadius(8)
                }
            }
            
            // Можливість попереднього замовлення
            if coffeeShop.allowScheduledOrders {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(Color("primary"))
                    
                    Text("Можливе попереднє замовлення")
                        .font(.subheadline)
                        .foregroundColor(Color("primaryText"))
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
    
    // Категорії для фільтрації (як у Starbucks)
    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
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
                    .fontWeight(isSelected ? .bold : .regular)
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

// MARK: - Компонент для відображення групи меню
struct MenuGroupView: View {
    let group: MenuGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                                .fill(Color(hex: "#1A1D24"))
                                .frame(width: 170, height: 250)
                            
                            VStack(spacing: 12) {
                                Image(systemName: "cup.and.saucer")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color("secondaryText"))
                                
                                Text("Немає доступних пунктів")
                                    .font(.subheadline)
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
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Компонент для відображення картки товару
struct MenuItemCard: View {
    let item: MenuItem
    
    // Використовуємо визначені кольори з проекту
    private var cardGradient: LinearGradient {
        return LinearGradient(
            gradient: Gradient(colors: [Color.cardTop, Color.cardBottom]),
            startPoint: .top,
            endPoint: .bottomTrailing
        )
    }
    
    // Градієнт для кнопки додавання (оранжевий)
    private let addButtonGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "#E67E22"),  // Світліший оранжевий
            Color(hex: "#D35400")   // Темніший оранжевий
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
                            .frame(width: 150, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(hex: "#2D3748"))
                                .frame(width: 150, height: 150)
                            
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color("primary"))
                        }
                    }
                }
                .frame(height: 150)
                
                // Назва та опис у фіксованій рамці
                VStack(alignment: .leading, spacing: 4) {
                    // Назва товару
                    Text(item.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.white)
                        .padding(.top, 8)
                    
                    // Опис (якщо є) з фіксованою висотою
                    if let description = item.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(Color.gray)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    } else {
                        // Пустий текст для збереження висоти
                        Text("")
                            .font(.subheadline)
                            .foregroundColor(.clear)
                    }
                }
                .frame(height: 60) // Фіксована висота для блоку назви та опису
                
                Spacer()
                
                // Ціна та кнопка додавання
                HStack {
                    // Ціна
                    Text("₴ \(formatPrice(item.price))")
                        .font(.title3)
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
                .padding(.bottom, 8)
            }
            .padding(12)
            .frame(width: 170, height: 280) // Фіксована висота всієї карточки
            .background(cardGradient) // Використовуємо ваш градієнт
            .cornerRadius(23)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            // Якщо товар недоступний, робимо його напівпрозорим
            .opacity(item.isAvailable ? 1.0 : 0.5)
            .overlay(
                Group {
                    if !item.isAvailable {
                        Text("Недоступно")
                            .font(.caption)
                            .fontWeight(.semibold)
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
                .fontWeight(.medium)
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

// MARK: - Допоміжні розширення
// Розширення для створення Color з HEX
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview Provider
struct CoffeeShopDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CoffeeShopDetailView(coffeeShop: CoffeeShop(
                id: "mock-1",
                name: "Кава на Подолі",
                address: "вул. Сагайдачного 15, Київ",
                logoUrl: nil,
                ownerId: nil,
                allowScheduledOrders: true,
                minPreorderTimeMinutes: 15,
                maxPreorderTimeMinutes: 120,
                workingHours: [
                    "1": WorkingHoursPeriod(open: "08:00", close: "22:00", isClosed: false)
                ],
                createdAt: Date(),
                updatedAt: Date(),
                menuGroups: [
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
                                price: 120.0,
                                description: "With Steamed Milk",
                                imageUrl: nil,
                                isAvailable: true,
                                menuGroupId: "group-1",
                                createdAt: Date(),
                                updatedAt: Date()
                            ),
                            MenuItem(
                                id: "item-2",
                                name: "Latte",
                                price: 140.0,
                                description: "With Extra Milk and Caramel",
                                imageUrl: nil,
                                isAvailable: true,
                                menuGroupId: "group-1",
                                createdAt: Date(),
                                updatedAt: Date()
                            )
                        ],
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                ]
            ))
        }
    }
}
