import SwiftUI

struct OrderDetailsView: View {
    @StateObject private var viewModel: OrderDetailsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    init(order: OrderHistory) {
        _viewModel = StateObject(wrappedValue: OrderDetailsViewModel(order: order))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Фоновий градієнт як в інших екранах
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
                        // Для темного режиму використовуємо існуючий колір
                        Color("backgroundColor")
                    }
                }
                .ignoresSafeArea()
                
                // Логотип як фон
                Image("Logo")
                    .resizable()
                    .renderingMode(.original)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIScreen.main.bounds.width * 0.7)
                    .saturation(1.5)
                    .opacity(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Order Header
                    orderHeaderSection
                    
                    // Coffee Shop Info
                    coffeeShopSection
                    
                    // Items Section
                    itemsSection
                    
                    // Payment Section
                    paymentSection
                    
                    // Status History Section
                    statusHistorySection
                }
                .padding()
                }
            }
            .navigationTitle("Деталі замовлення")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрити") {
                        dismiss()
                    }
                    .foregroundColor(Color("primary"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        Button(action: {
                            viewModel.refreshCustomizationNames()
                        }) {
                            Image(systemName: "textformat")
                                .foregroundColor(Color("primary"))
                        }
                        
                        Button(action: {
                            viewModel.refreshPaymentInfo()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(Color("primary"))
                        }
                        .disabled(viewModel.isLoadingPayment)
                    }
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
    }
    
    // MARK: - Sections
    
    private var orderHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.order.orderNumber)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color("primaryText"))
                    
                    Text(viewModel.order.formattedCreatedDate)
                        .font(.subheadline)
                        .foregroundColor(Color("secondaryText"))
                }
                
                Spacer()
                
                StatusBadge(
                    isActive: true,
                    activeText: viewModel.order.statusDisplayName,
                    inactiveText: "",
                    activeColor: Color(viewModel.order.statusColor),
                    inactiveColor: Color.gray
                )
            }
            
            Divider()
                .background(Color("secondaryText").opacity(0.3))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Загальна сума")
                        .font(.subheadline)
                        .foregroundColor(Color("secondaryText"))
                    
                    Text(viewModel.formattedTotalAmount)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color("primary"))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Товарів")
                        .font(.subheadline)
                        .foregroundColor(Color("secondaryText"))
                    
                    Text("\(viewModel.totalItemsCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color("primary"))
                }
            }
        }
        .padding()
        .background(
            ZStack {
                BlurView(
                    style: colorScheme == .light ? .systemThinMaterial : .systemMaterialDark,
                    opacity: colorScheme == .light ? 0.95 : 0.95
                )
                if colorScheme == .light {
                    Color("nidusLightBlueGray").opacity(0.12)
                }
            }
        )
        .cornerRadius(12)
    }
    
    private var coffeeShopSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Кав'ярня")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color("primaryText"))
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(Color("primary"))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.order.displayCoffeeShopName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("primaryText"))
                    
                    if viewModel.order.displayCoffeeShopName == "Невідома кав'ярня" {
                        Text("ID: \(String(viewModel.order.coffeeShopId.prefix(8)))...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if viewModel.order.displayCoffeeShopName == "Невідома кав'ярня" {
                    Button(action: {
                        viewModel.refreshCustomizationNames()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundColor(Color("primary"))
                    }
                }
            }
            .padding()
            .background(
                ZStack {
                    BlurView(
                        style: colorScheme == .light ? .systemThinMaterial : .systemMaterialDark,
                        opacity: colorScheme == .light ? 0.95 : 0.95
                    )
                    if colorScheme == .light {
                        Color("nidusLightBlueGray").opacity(0.08)
                    }
                }
            )
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
        }
    }
    
    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Замовлені товари")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 8) {
                ForEach(viewModel.order.items) { item in
                    OrderItemCard(item: item)
                }
            }
        }
    }
    
    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Оплата")
                .font(.headline)
                .fontWeight(.semibold)
            
            if viewModel.isLoadingPayment {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    
                    Text("Завантаження...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            } else if let payment = viewModel.paymentInfo {
                PaymentInfoCard(payment: payment, orderAmount: viewModel.order.totalAmount)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: viewModel.order.isPaid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundColor(viewModel.order.isPaid ? .green : .orange)
                        
                        Text(viewModel.order.isPaid ? "Оплачено" : "Не оплачено")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text("Сума: \(viewModel.formattedTotalAmount)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    private var statusHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Історія статусів")
                .font(.headline)
                .fontWeight(.semibold)
            
            if viewModel.order.statusHistory.isEmpty {
                Text("Немає історії статусів")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.order.statusHistory.sorted(by: { $0.createdAt > $1.createdAt })) { historyItem in
                        StatusHistoryCard(historyItem: historyItem)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct CustomizationDisplayView: View {
    let data: CustomizationDisplayData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Інгредієнти
            if !data.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Інгредієнти:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("primary"))
                    
                    ForEach(data.ingredients.indices, id: \.self) { index in
                        let ingredient = data.ingredients[index]
                        
                        HStack(alignment: .center, spacing: 8) {
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(Color("primary"))
                            
                            Text(ingredient.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color("primaryText"))
                            
                            Text("\(ingredient.quantity) \(ingredient.unit)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if ingredient.additionalPrice > 0 {
                                Text("+\(String(format: "%.0f", ingredient.additionalPrice)) ₴")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color("primary"))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color("primary").opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.vertical, 1)
                    }
                }
            }
            
            // Опції
            if !data.optionGroups.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Опції:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("primary"))
                    
                    ForEach(Array(data.optionGroups.keys.sorted()), id: \.self) { groupName in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(groupName):")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            if let options = data.optionGroups[groupName] {
                                ForEach(options.indices, id: \.self) { index in
                                    let option = options[index]
                                    
                                    HStack(alignment: .center, spacing: 8) {
                                        Text("◦")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        
                                        Text(option.name)
                                            .font(.caption)
                                            .foregroundColor(Color("primaryText"))
                                        
                                        if option.quantity > 1 {
                                            Text("x\(option.quantity)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if option.additionalPrice > 0 {
                                            Text("+\(String(format: "%.0f", option.additionalPrice)) ₴")
                                                .font(.caption2)
                                                .fontWeight(.semibold)
                                                .foregroundColor(Color("primary"))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color("primary").opacity(0.1))
                                                .cornerRadius(4)
                                        }
                                    }
                                    .padding(.vertical, 1)
                                }
                            }
                        }
                        .padding(.leading, 8)
                    }
                }
            }
        }
    }
}

struct OrderItemCard: View {
    let item: OrderHistoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(item.quantity)x \(item.name)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(item.totalPrice)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            if let sizeName = item.sizeName {
                HStack {
                    Text("Розмір:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(sizeName)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    // Додаємо ціну за розмір, якщо є
                    if let sizePrice = item.effectiveSizeAdditionalPrice, sizePrice != 0 {
                        Spacer()
                        
                        Text(sizePrice > 0 ? "+\(String(format: "%.0f", sizePrice)) ₴" : "\(String(format: "%.0f", sizePrice)) ₴")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(sizePrice > 0 ? Color("primary") : .red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background((sizePrice > 0 ? Color("primary") : .red).opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
            
            if item.hasCustomizations {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Кастомізації:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    if let customizationData = item.customizationDisplayData {
                        CustomizationDisplayView(data: customizationData)
                    } else if let customization = item.displayCustomization {
                        // Резервний варіант для старого формату
                        let lines = customization.components(separatedBy: "\n")
                        ForEach(lines.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .font(.caption2)
                                    .foregroundColor(Color("primary"))
                                    .padding(.top, 1)
                                
                                Text(lines[index])
                                    .font(.caption)
                                    .foregroundColor(Color("primaryText"))
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer()
                            }
                        }
                    } else {
                        Text("Без кастомізацій")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color("nidusLightBlueGray").opacity(0.08))
                .cornerRadius(8)
            }
            
            if item.finalPrice != item.basePrice {
                HStack {
                    Text("Базова ціна:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.2f ₴", item.basePrice))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("З кастомізаціями:")
                        .font(.caption)
                        .foregroundColor(Color("primary"))
                    
                    Text(item.formattedPrice)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color("primary"))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

struct PaymentInfoCard: View {
    let payment: OrderPaymentInfo
    let orderAmount: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.blue)
                
                Text("Інформація про оплату")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                StatusBadge(
                    isActive: true,
                    activeText: payment.statusDisplayName,
                    inactiveText: "",
                    activeColor: Color(payment.statusColor),
                    inactiveColor: Color.gray
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                PaymentDetailRow(label: "Сума оплати", value: payment.formattedAmount)
                
                if let method = payment.method {
                    PaymentDetailRow(label: "Спосіб оплати", value: method)
                }
                
                if let transactionId = payment.transactionId {
                    PaymentDetailRow(label: "ID транзакції", value: transactionId)
                }
                
                if let completedAt = payment.completedAt {
                    let formattedDate = {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short
                    formatter.locale = Locale(identifier: "uk_UA")
                    
                    if let date = ISO8601DateFormatter().date(from: completedAt) {
                            return formatter.string(from: date)
                    }
                        return completedAt
                    }()
                    
                    PaymentDetailRow(label: "Дата оплати", value: formattedDate)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

struct PaymentDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct StatusHistoryCard: View {
    let historyItem: OrderStatusHistoryItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(historyItem.status.color))
                .frame(width: 12, height: 12)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(historyItem.status.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(historyItem.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let comment = historyItem.comment, !comment.isEmpty {
                    Text(comment)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let createdBy = historyItem.createdBy {
                    Text("Оновлено: \(createdBy)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Preview

struct OrderDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        let mockOrder = OrderHistory(
            id: "order-1",
            orderNumber: "CAF-230520-001",
            status: OrderStatus.completed,
            totalAmount: 120.0,
            coffeeShopId: "shop-1",
            coffeeShopName: "Coffee House",
            coffeeShop: CoffeeShopInfo(
                id: "shop-1",
                name: "Coffee House",
                address: "вул. Тестова, 1"
            ),
            isPaid: true,
            createdAt: "2023-05-20T14:30:00Z",
            completedAt: "2023-05-20T15:00:00Z",
            items: [
                OrderHistoryItem(
                    id: "item-1",
                    name: "Капучино",
                    price: 100.0,
                    basePrice: 80.0,
                    finalPrice: 120.0,
                    quantity: 1,
                    customization: OrderItemCustomization(
                        customizationDetails: CustomizationDetails(
                            size: CustomizationSizeDetail(name: "Дуже Великий", price: 15.0),
                            options: [
                                CustomizationOptionDetail(
                                    name: "Додаткова порція еспресо",
                                    price: 20.0,
                                    totalPrice: 20.0,
                                    quantity: 1
                                )
                            ]
                        ),
                        customizationSummary: "Розмір: Дуже Великий (+15.00 ₴) | Інгредієнти: Еспресо : 5порція | Опції: Сироп: Карамель x6; Тип молока: Соєве"
                    ),
                    sizeName: "Дуже Великий",
                    sizeAdditionalPrice: 15.0
                ),
                OrderHistoryItem(
                    id: "item-2",
                    name: "Еспресо",
                    price: 45.0,
                    basePrice: 50.0,
                    finalPrice: 45.0,
                    quantity: 1,
                    customization: nil,
                    sizeName: "Малий",
                    sizeAdditionalPrice: -5.0
                )
            ],
            statusHistory: [
                OrderStatusHistoryItem(
                    id: "history-1",
                    status: OrderStatus.created,
                    comment: "Замовлення створено",
                    createdAt: "2023-05-20T14:30:00Z",
                    createdBy: String?.none
                )
            ],
            payment: OrderPaymentInfo?.none
        )
        
        OrderDetailsView(order: mockOrder)
    }
}