import SwiftUI

// Визначаємо тип перегляду (всі кав'ярні або тільки мої)
enum CoffeeShopViewMode {
    case allShops
    case myShops
}

struct AdminCoffeeShopsView: View {
    @StateObject private var viewModel: CoffeeShopViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingCreateSheet = false
    @State private var showingEditSheet = false
    @State private var showingAssignOwnerSheet = false
    @State private var showingDeleteAlert = false
    @State private var selectedCoffeeShop: CoffeeShop?
    @State private var showToast = false
    @State private var toastMessage = ""
    
    // Режим перегляду (всі кав'ярні або тільки мої)
    private let viewMode: CoffeeShopViewMode
     
    init(viewMode: CoffeeShopViewMode = .allShops) {
        // Створюємо тимчасовий AuthManager для ініціалізації
        let authManager = AuthenticationManager()
        self._viewModel = StateObject(wrappedValue: CoffeeShopViewModel(authManager: authManager))
        self.viewMode = viewMode
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
                } else {
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
            }
            
            // Кнопка додавання кав'ярні (якщо користувач має право)
            if viewModel.canManageCoffeeShops() {
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
                if viewMode == .myShops {
                    await viewModel.loadMyCoffeeShops()
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
        // Встановлюємо заголовок залежно від режиму перегляду
        .navigationTitle(viewMode == .myShops ? "Мої кав'ярні" : "Кав'ярні")
        .navigationBarTitleDisplayMode(.inline)
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
