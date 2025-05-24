import SwiftUI

struct OrderHistoryView: View {
    @StateObject private var viewModel = OrderHistoryViewModel()
    @State private var showingFilterSheet = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Фоновий градієнт
                backgroundGradient
                    .ignoresSafeArea()
                
                // Логотип як фон
                logoBackground
                
                // Основний контент
                VStack(spacing: 0) {
                    // Header з пошуком і фільтрами
                    headerSection
                        .padding(.top, 8)
                    
                    // Список замовлень або empty state
                    contentSection
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    // Простір для Tab Bar
                    Color.clear.frame(height: 0)
                }
            }
        }
        .navigationTitle("Мої замовлення")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Оновлюємо замовлення при появі екрану
            viewModel.refreshOrders()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 8) {
                    // Кнопка діагностики
                    Button("🔍") {
                        Task {
                            await viewModel.orderHistoryService.diagnoseFetchIssue()
                        }
                    }
                    .foregroundColor(Color("primary"))
                    
                    refreshButton
                }
            }
        }
        .sheet(isPresented: $viewModel.showingOrderDetails) {
            if let selectedOrder = viewModel.selectedOrder {
                OrderDetailsView(order: selectedOrder)
            }
        }
        .alert("Помилка", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
    }
    
    // MARK: - Background Components
    
    private var backgroundGradient: some View {
        Group {
            if colorScheme == .light {
                ZStack {
                    // Основний горизонтальний градієнт
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color("nidusCoolGray").opacity(0.9),
                            Color("nidusLightBlueGray").opacity(0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    
                    // Додатковий вертикальний градієнт для текстури
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color("nidusCoolGray").opacity(0.15),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Тонкий шар кольору для затінення в кутах
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color("nidusCoolGray").opacity(0.2)
                        ]),
                        center: .bottomTrailing,
                        startRadius: UIScreen.main.bounds.width * 0.2,
                        endRadius: UIScreen.main.bounds.width
                    )
                }
            } else {
                Color("backgroundColor")
            }
        }
    }
    
    private var logoBackground: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image("Logo")
                    .resizable()
                    .renderingMode(.original)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIScreen.main.bounds.width * 0.7)
                    .saturation(1.5)
                    .opacity(1)
                Spacer()
            }
            Spacer()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            searchBar
            
            // Filter Chips
            filterChips
        }
        .padding(.horizontal, 16)
        .background(Color.clear)
    }
    
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color("secondaryText"))
                
                TextField("Пошук замовлень...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(Color("primaryText"))
                
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color("secondaryText"))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    BlurView(
                        style: colorScheme == .light ? .systemThinMaterial : .systemMaterialDark,
                        opacity: 0.95
                    )
                    if colorScheme == .light {
                        Color("nidusLightBlueGray").opacity(0.15)
                    }
                }
            )
            .cornerRadius(12)
        }
    }
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(OrderHistoryFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        viewModel.filterChanged(to: filter)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        Group {
            if viewModel.isLoading && viewModel.orders.isEmpty {
                loadingView
            } else if viewModel.isEmptyState {
                emptyStateView
            } else {
                ordersList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color("primary")))
                .scaleEffect(1.2)
            
            Text("Завантаження замовлень...")
                .font(.subheadline)
                .foregroundColor(Color("secondaryText"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 60)
                
                Image(systemName: "list.clipboard")
                    .font(.system(size: 64))
                    .foregroundColor(Color("primary").opacity(0.8))
                
                VStack(spacing: 8) {
                    Text("Немає замовлень")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("primaryText"))
                    
                    Text("Ваші замовлення з'являться тут після їх створення")
                        .font(.subheadline)
                        .foregroundColor(Color("secondaryText"))
                        .multilineTextAlignment(.center)
                }
                
                Button("Оновити") {
                    viewModel.refreshOrders()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color("primary"))
                .foregroundColor(.white)
                .cornerRadius(12)
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 40)
        }
        .refreshable {
            await refreshOrders()
        }
    }
    
    private var ordersList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Додаємо відступ зверху
                Color.clear.frame(height: 8)
                
                ForEach(viewModel.filteredOrders) { order in
                    OrderHistoryCard(order: order) {
                        viewModel.selectOrder(order)
                    }
                    .onAppear {
                        // Load more data if needed
                        if order.id == viewModel.filteredOrders.last?.id {
                            viewModel.loadMoreOrdersIfNeeded()
                        }
                    }
                }
                
                if viewModel.isLoadingMore {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color("primary")))
                        Text("Завантаження...")
                            .font(.caption)
                            .foregroundColor(Color("secondaryText"))
                    }
                    .padding()
                }
                
                // Додаємо відступ знизу для Tab Bar
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 16)
        }
        .refreshable {
            await refreshOrders()
        }
    }
    
    private var refreshButton: some View {
        Button(action: {
            viewModel.refreshOrders()
        }) {
            Image(systemName: "arrow.clockwise")
                .foregroundColor(Color("primary"))
        }
        .disabled(viewModel.isLoading)
    }
    
    // MARK: - Methods
    
    @MainActor
    private func refreshOrders() async {
        viewModel.refreshOrders()
        
        // Симулюємо мінімальний час для pull-to-refresh анімації
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 секунди
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    ZStack {
                        if isSelected {
                            Color("primary")
                        } else {
                            BlurView(
                                style: colorScheme == .light ? .systemThinMaterial : .systemMaterialDark,
                                opacity: 0.95
                            )
                            if colorScheme == .light {
                                Color("nidusLightBlueGray").opacity(0.15)
                            }
                        }
                    }
                )
                .foregroundColor(isSelected ? .white : Color("primaryText"))
                .cornerRadius(20)
        }
    }
}

struct OrderHistoryCard: View {
    let order: OrderHistory
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(order.orderNumber)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("primaryText"))
                        
                        Text(order.formattedCreatedDate)
                            .font(.caption)
                            .foregroundColor(Color("secondaryText"))
                    }
                    
                    Spacer()
                    
                    StatusBadge(
                        isActive: true,
                        activeText: order.statusDisplayName,
                        inactiveText: "",
                        activeColor: Color(order.statusColor),
                        inactiveColor: Color.gray
                    )
                }
                
                // Coffee Shop
                if let coffeeShopName = order.coffeeShopName {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(Color("primary"))
                            .font(.caption)
                        
                        Text(coffeeShopName)
                            .font(.subheadline)
                            .foregroundColor(Color("secondaryText"))
                    }
                }
                
                // Items preview
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(order.items.prefix(2)) { item in
                        HStack {
                            Text("\(item.quantity)x \(item.name)")
                                .font(.subheadline)
                                .foregroundColor(Color("primaryText"))
                            
                            if let sizeName = item.sizeName {
                                Text("(\(sizeName))")
                                    .font(.caption)
                                    .foregroundColor(Color("secondaryText"))
                            }
                            
                            Spacer()
                            
                            Text(item.totalPrice)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color("primaryText"))
                        }
                    }
                    
                    if order.items.count > 2 {
                        Text("та ще \(order.items.count - 2) товарів...")
                            .font(.caption)
                            .foregroundColor(Color("secondaryText"))
                    }
                }
                
                Divider()
                    .background(Color("secondaryText").opacity(0.3))
                
                // Footer
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: order.isPaid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundColor(order.isPaid ? .green : .orange)
                            .font(.caption)
                        
                        Text(order.isPaid ? "Оплачено" : "Не оплачено")
                            .font(.caption)
                            .foregroundColor(order.isPaid ? .green : .orange)
                    }
                    
                    Spacer()
                    
                    Text(String(format: "%.2f ₴", order.totalAmount))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("primary"))
                }
            }
            .padding(16)
            .background(
                ZStack {
                    BlurView(
                        style: colorScheme == .light ? .systemThinMaterial : .systemMaterialDark,
                        opacity: 0.95
                    )
                    if colorScheme == .light {
                        Color("nidusLightBlueGray").opacity(0.12)
                    }
                }
            )
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct OrderHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        OrderHistoryView()
    }
}