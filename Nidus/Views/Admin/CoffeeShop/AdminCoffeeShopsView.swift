import SwiftUI

// Визначаємо тип перегляду (всі кав'ярні або тільки мої)
enum CoffeeShopViewMode {
    case allShops
    case myShops
}

struct AdminCoffeeShopsView: View {
    @StateObject private var viewModel: CoffeeShopViewModel
    @StateObject private var menuGroupsViewModel = MenuGroupsViewModel()
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingCreateSheet = false
    @State private var showingEditSheet = false
    @State private var showingAssignOwnerSheet = false
    @State private var showingAddMenuGroupSheet = false
    @State private var showingDeleteAlert = false
    @State private var selectedCoffeeShop: CoffeeShop?
    @State private var showToast = false
    @State private var toastMessage = ""
    
    // Режим перегляду (всі кав'ярні або тільки мої)
    private let viewMode: CoffeeShopViewMode
    // Початкова кав'ярня (для режиму однієї кав'ярні)
    private var initialCoffeeShop: CoffeeShop?
     
    init(viewMode: CoffeeShopViewMode = .allShops, initialCoffeeShop: CoffeeShop? = nil) {
        // Створюємо тимчасовий AuthManager для ініціалізації
        let authManager = AuthenticationManager()
        self._viewModel = StateObject(wrappedValue: CoffeeShopViewModel(authManager: authManager))
        self.viewMode = viewMode
        self.initialCoffeeShop = initialCoffeeShop
    }
    
    // Перевіряємо чи є в користувача лише одна кав'ярня
    private var hasOnlyOneCoffeeShop: Bool {
        return (initialCoffeeShop != nil) ||
               (viewMode == .myShops && viewModel.myCoffeeShops.count == 1 && !viewModel.isSuperAdmin())
    }
    
    // Отримання єдиної кав'ярні для власника
    private var singleCoffeeShop: CoffeeShop? {
        return initialCoffeeShop ?? (hasOnlyOneCoffeeShop ? viewModel.myCoffeeShops.first : nil)
    }
    
    var body: some View {
        ZStack {
            Color("backgroundColor")
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                if viewModel.isLoading {
                    ProgressView("Завантаження...")
                        .padding()
                } else if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .multilineTextAlignment(.center)
                } else if hasOnlyOneCoffeeShop, let coffeeShop = singleCoffeeShop {
                    // Спеціальний вигляд для власника з однією кав'ярнею
                    singleCoffeeShopView(coffeeShop)
                } else {
                    // Стандартний список кав'ярень
                    multipleShopsView()
                }
            }
            
            // Показуємо кнопку додавання кав'ярні лише для стандартного списку
            if viewModel.canManageCoffeeShops() && !hasOnlyOneCoffeeShop {
                VStack {
                    Spacer()
                    
                    Button(action: {
                        showingCreateSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                                .font(.headline)
                            
                            Text("Додати кав'ярню")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .background(Color("primary"))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    .padding(.bottom, 20)
                }
            }
            
            // Додаємо тост внизу екрану
            Toast(message: viewModel.successMessage, isShowing: $viewModel.showSuccess)
        }
        .onAppear {
            // Оновлюємо ViewModel щоб використати @EnvironmentObject
            viewModel.authManager = authManager
            
            // Завантажуємо дані в залежності від режиму перегляду
            Task {
                if initialCoffeeShop != nil {
                    // Якщо є початкова кав'ярня, відразу завантажуємо її групи меню
                    await menuGroupsViewModel.loadMenuGroups(coffeeShopId: initialCoffeeShop!.id)
                } else if viewMode == .myShops {
                    await viewModel.loadMyCoffeeShops()
                    
                    // Якщо в нас одна кав'ярня, відразу завантажуємо групи меню
                    if hasOnlyOneCoffeeShop, let coffeeShop = singleCoffeeShop {
                        await menuGroupsViewModel.loadMenuGroups(coffeeShopId: coffeeShop.id)
                    }
                } else {
                    await viewModel.loadAllCoffeeShops()
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateCoffeeShopView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingEditSheet) {
            if let coffeeShop = selectedCoffeeShop {
                EditCoffeeShopView(viewModel: viewModel, coffeeShop: coffeeShop)
            }
        }
        .sheet(isPresented: $showingAssignOwnerSheet) {
            if let coffeeShop = selectedCoffeeShop {
                AssignOwnerView(viewModel: viewModel, coffeeShop: coffeeShop)
            }
        }
        .sheet(isPresented: $showingAddMenuGroupSheet) {
            if let coffeeShop = singleCoffeeShop {
                CreateMenuGroupView(coffeeShopId: coffeeShop.id, viewModel: menuGroupsViewModel)
            }
        }
        .alert("Видалення кав'ярні", isPresented: $showingDeleteAlert) {
            Button("Скасувати", role: .cancel) {}
            Button("Видалити", role: .destructive) {
                if let coffeeShop = selectedCoffeeShop {
                    Task {
                        await viewModel.deleteCoffeeShop(id: coffeeShop.id)
                    }
                }
            }
        } message: {
            if let name = selectedCoffeeShop?.name {
                Text("Ви впевнені, що хочете видалити кав'ярню '\(name)'? Ця дія незворотна.")
            } else {
                Text("Ви впевнені, що хочете видалити цю кав'ярню? Ця дія незворотна.")
            }
        }
        // Встановлюємо заголовок
        .navigationTitle(hasOnlyOneCoffeeShop ? "Моя кав'ярня" : (viewMode == .myShops ? "Мої кав'ярні" : "Кав'ярні"))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Вигляд для однієї кав'ярні (для власника з однією кав'ярнею)
    @ViewBuilder
    private func singleCoffeeShopView(_ coffeeShop: CoffeeShop) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Картка кав'ярні
                CoffeeShopAdminRow(
                    coffeeShop: coffeeShop,
                    canManage: viewModel.canManageCoffeeShop(coffeeShop),
                    isSuperAdmin: viewModel.isSuperAdmin(),
                    onEdit: {
                        selectedCoffeeShop = coffeeShop
                        showingEditSheet = true
                    },
                    onDelete: {
                        selectedCoffeeShop = coffeeShop
                        showingDeleteAlert = true
                    },
                    onAssignOwner: {
                        selectedCoffeeShop = coffeeShop
                        showingAssignOwnerSheet = true
                    }
                )
                .background(Color("cardColor"))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Заголовок секції меню
                HStack {
                    Text("Групи меню")
                        .font(.headline)
                        .foregroundColor(Color("primaryText"))
                    
                    Spacer()
                    
                    // Кнопка додавання кав'ярні
                    Button(action: {
                        showingCreateSheet = true
                    }) {
                        Label("Додати кав'ярню", systemImage: "plus")
                            .font(.subheadline)
                            .foregroundColor(Color("primary"))
                    }
                }
                .padding(.horizontal)
                
                if menuGroupsViewModel.isLoading {
                    ProgressView("Завантаження груп меню...")
                        .padding()
                } else if let error = menuGroupsViewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .multilineTextAlignment(.center)
                } else if menuGroupsViewModel.menuGroups.isEmpty {
                    // Повідомлення, коли немає груп меню
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 40))
                            .foregroundColor(Color("secondaryText"))
                            .padding(.bottom, 8)
                        
                        Text("Групи меню відсутні")
                            .font(.headline)
                            .foregroundColor(Color("primaryText"))
                        
                        Text("Додайте першу групу меню для організації вашого меню")
                            .font(.subheadline)
                            .foregroundColor(Color("secondaryText"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(Color("cardColor"))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    // Список груп меню
                    VStack(spacing: 12) {
                        ForEach(menuGroupsViewModel.menuGroups) { group in
                            // Отримуємо кількість пунктів меню для групи
                            let itemsCount = menuGroupsViewModel.getMenuItemsCount(for: group.id)
                            
                            NavigationLink(destination: MenuItemsListView(menuGroup: group)) {
                                VStack(spacing: 0) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(group.name)
                                                .font(.headline)
                                                .foregroundColor(Color("primaryText"))
                                            
                                            if let description = group.description, !description.isEmpty {
                                                Text(description)
                                                    .font(.subheadline)
                                                    .foregroundColor(Color("secondaryText"))
                                                    .lineLimit(2)
                                            }
                                            
                                            HStack(spacing: 12) {
                                                // Порядковий номер
                                                HStack(spacing: 4) {
                                                    Image(systemName: "number")
                                                        .font(.caption)
                                                        .foregroundColor(Color("primary"))
                                                    
                                                    Text("Порядок: \(group.displayOrder)")
                                                        .font(.caption)
                                                        .foregroundColor(Color("secondaryText"))
                                                }
                                                
                                                // Кількість пунктів меню
                                                HStack(spacing: 4) {
                                                    Image(systemName: "square.stack")
                                                        .font(.caption)
                                                        .foregroundColor(Color("primary"))
                                                    
                                                    Text("\(itemsCount) \(menuItemText(itemsCount))")
                                                        .font(.caption)
                                                        .foregroundColor(Color("secondaryText"))
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        // Індикатор переходу
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(Color("secondaryText"))
                                            .font(.system(size: 14, weight: .semibold))
                                            .padding(.trailing, 4)
                                    }
                                    .padding(16)
                                }
                                .background(Color("cardColor"))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                .contentShape(Rectangle()) // Важливо для того, щоб вся картка була клікабельною
                            }
                            .buttonStyle(PlainButtonStyle()) // Використовуємо PlainButtonStyle для кращого контролю
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Кнопка додавання групи меню
                Button(action: {
                    showingAddMenuGroupSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Додати групу меню")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("primary"))
                    .cornerRadius(12)
                }
                .padding()
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
        .onChange(of: menuGroupsViewModel.showSuccess) { newValue in
            if newValue {
                // Перезавантажуємо групи меню після успішного оновлення
                Task {
                    await menuGroupsViewModel.loadMenuGroups(coffeeShopId: coffeeShop.id)
                }
            }
        }
    }
    
    private func menuItemText(_ count: Int) -> String {
        let lastDigit = count % 10
        let lastTwoDigits = count % 100
        
        if lastTwoDigits >= 11 && lastTwoDigits <= 19 {
            return "пунктів меню"
        }
        
        switch lastDigit {
        case 1:
            return "пункт меню"
        case 2, 3, 4:
            return "пункти меню"
        default:
            return "пунктів меню"
        }
    }
    
    // Стандартний список кав'ярень
    @ViewBuilder
    private func multipleShopsView() -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Заголовок зі статистикою
                HStack {
                    Text("Загальна кількість: \(coffeeShopsToShow.count)")
                        .font(.subheadline)
                        .foregroundColor(Color("secondaryText"))
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Список кав'ярень
                ForEach(coffeeShopsToShow) { coffeeShop in
                    CoffeeShopAdminRow(
                        coffeeShop: coffeeShop,
                        canManage: viewModel.canManageCoffeeShop(coffeeShop),
                        isSuperAdmin: viewModel.isSuperAdmin(),
                        onEdit: {
                            selectedCoffeeShop = coffeeShop
                            showingEditSheet = true
                        },
                        onDelete: {
                            selectedCoffeeShop = coffeeShop
                            showingDeleteAlert = true
                        },
                        onAssignOwner: {
                            selectedCoffeeShop = coffeeShop
                            showingAssignOwnerSheet = true
                        }
                    )
                    .background(Color("cardColor"))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        
        // Якщо список порожній
        if coffeeShopsToShow.isEmpty && !viewModel.isLoading {
            VStack(spacing: 24) {
                Image(systemName: "cup.and.saucer")
                    .font(.system(size: 60))
                    .foregroundColor(Color("secondaryText"))
                
                Text(viewMode == .myShops ? "У вас немає кав'ярень" : "Кав'ярні відсутні")
                    .font(.headline)
                    .foregroundColor(Color("primaryText"))
                
                Text(viewMode == .myShops
                    ? "Ви ще не створили жодної кав'ярні або адміністратор ще не призначив вас власником"
                    : "Створіть свою першу кав'ярню, натиснувши кнопку нижче")
                    .font(.subheadline)
                    .foregroundColor(Color("secondaryText"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding()
        }
    }
    
    // Визначаємо, які кав'ярні показувати
    private var coffeeShopsToShow: [CoffeeShop] {
        if viewMode == .myShops {
            return viewModel.myCoffeeShops
        } else if viewModel.isSuperAdmin() {
            return viewModel.coffeeShops
        } else {
            return viewModel.myCoffeeShops
        }
    }
}

struct AdminCoffeeShopsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                AdminCoffeeShopsView(viewMode: .allShops)
                    .environmentObject(AuthenticationManager())
            }
            .previewDisplayName("Всі кав'ярні")
            
            NavigationView {
                AdminCoffeeShopsView(viewMode: .myShops)
                    .environmentObject(AuthenticationManager())
            }
            .previewDisplayName("Мої кав'ярні")
        }
        .preferredColorScheme(.dark)
    }
}
