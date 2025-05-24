//
//  CartView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 5/18/25.
//

import SwiftUI
import WebKit

struct CartView: View {
    @StateObject private var viewModel = CartViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var tabBarManager: TabBarManager
    @State private var showConfirmationDialog = false
    @State private var showOrderCancellationAlert = false
    @State private var comment: String = ""
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        ZStack {
            // Фоновий градієнт
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
            
            // Основний контент
            VStack(spacing: 0) {
                // Заголовок кав'ярні (якщо є товари)
                if let coffeeShop = viewModel.currentCoffeeShop, !viewModel.cart.isEmpty {
                    coffeeShopHeaderView(coffeeShop)
                }
                
                if viewModel.cart.isEmpty {
                    emptyCartView
                } else {
                    // Список товарів корзини
                    cartItemsListView
                    
                    // Секція з коментарем
                    commentSectionView
                    
                    // Підсумок і кнопка оформлення
                    checkoutSectionView
                }
            }
            .padding(.top, 1)
            
            // Індикатор завантаження
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("primary")))
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
                    .ignoresSafeArea()
            }
            
            // Вікно успішної оплати
            if viewModel.showPaymentSuccess {
                successPaymentView
            }
        }
        .navigationTitle("Корзина")
        .navigationBarTitleDisplayMode(.inline)
        
        // Попередження про конфлікт кав'ярень
        .alert("Заміна кав'ярні", isPresented: $viewModel.showCoffeeShopConflict) {
            Button("Очистити і додати", role: .destructive) {
                viewModel.clearCartAndAddNewItem()
            }
            Button("Скасувати", role: .cancel) {
                viewModel.cancelAddingNewItem()
            }
        } message: {
            Text("У кошику вже є товари з іншої кав'ярні. Щоб додати цей товар, потрібно очистити корзину. Продовжити?")
        }
        
        // WebView для оплати
        .sheet(isPresented: $viewModel.showPaymentWebView) {
            // При закритті перевіряємо статус оплати
            Task {
                await viewModel.checkPaymentStatus()
            }
        } content: {
            if let url = viewModel.paymentUrl {
                NavigationView {
                    PaymentWebView(url: url)
                        .navigationTitle("Оплата")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Закрити") {
                                    viewModel.showPaymentWebView = false
                                }
                            }
                            
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Готово") {
                                    // Вручну тригеримо успішну оплату
                                    viewModel.showPaymentWebView = false
                                    NotificationCenter.default.post(name: .paymentSuccessful, object: nil)
                                }
                                .foregroundColor(.green)
                            }
                        }
                }
            }
        }
        
        // Діалог підтвердження очищення корзини
        .actionSheet(isPresented: $showConfirmationDialog) {
            ActionSheet(
                title: Text("Очистити корзину?"),
                message: Text("Ви впевнені, що хочете видалити всі товари з корзини?"),
                buttons: [
                    .destructive(Text("Очистити")) {
                        viewModel.clearCart()
                    },
                    .cancel()
                ]
            )
        }
        
        // Помилка
        .alert("Помилка", isPresented: Binding<Bool>(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("ОК", role: .cancel) {}
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
        
        // Підтвердження скасування замовлення
        .alert("Скасувати замовлення?", isPresented: $showOrderCancellationAlert) {
            Button("Скасувати замовлення", role: .destructive) {
                Task {
                    await viewModel.cancelOrder()
                }
            }
            Button("Ні", role: .cancel) {}
        } message: {
            Text("Ви впевнені, що хочете скасувати поточне замовлення?")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.cart.isEmpty {
                    HStack(spacing: 20) {
                        // Кнопка очищення корзини
                        Button(action: {
                            showConfirmationDialog = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(Color("primary"))
                        }
                        
                        // Кнопка закриття sheet
                        Button(action: {
                            tabBarManager.isCartSheetPresented = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(Color("primary"))
                        }
                    }
                } else {
                    // Тільки кнопка закриття для порожньої корзини
                    Button(action: {
                        tabBarManager.isCartSheetPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(Color("primary"))
                    }
                }
            }
        }
    }
    
    // MARK: - Компоненти інтерфейсу
    
    // Заголовок з інформацією про кав'ярню
    private func coffeeShopHeaderView(_ coffeeShop: CoffeeShop) -> some View {
        HStack(spacing: 4) {
            Text("Ваше замовлення з")
                .font(.subheadline)
                .foregroundColor(Color("secondaryText"))
            
            Text(coffeeShop.name)
                .font(.headline)
                .foregroundColor(Color("primaryText"))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                // Скляний фон
                BlurView(
                    style: colorScheme == .light ? .systemThinMaterial : .systemMaterialDark,
                    opacity: colorScheme == .light ? 0.95 : 0.95
                )
                // Додатково тонуємо під кольори застосунку
                Group {
                    if colorScheme == .light {
                        // Тонування для світлої теми з новими кольорами
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("nidusMistyBlue").opacity(0.25),
                                Color("nidusCoolGray").opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .opacity(0.4)
                        
                        // Додаткове тонування для ефекту глибини
                        Color("nidusLightBlueGray").opacity(0.12)
                    } else {
                        // Додатковий шар для глибини у темному режимі
                        Color.black.opacity(0.15)
                    }
                }
            }
        )
    }
    
    // Список товарів у корзині
    private var cartItemsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.cart.items) { item in
                    CartItemRow(
                        item: item,
                        onQuantityChanged: { newQuantity in
                            viewModel.updateQuantity(for: item.id, quantity: newQuantity)
                        },
                        onRemove: {
                            viewModel.removeItem(withId: item.id)
                        }
                    )
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
        }
    }
    
    // Вид порожньої корзини
    private var emptyCartView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "cart")
                .font(.system(size: 70))
                .foregroundColor(Color("primary").opacity(0.8))
            
            Text("Ваша корзина порожня")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color("primaryText"))
            
            Text("Додайте товари з меню кав'ярні")
                .font(.subheadline)
                .foregroundColor(Color("secondaryText"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Кнопка переходу до кав'ярень та закриття sheet
            Button(action: {
                // Закриваємо sheet з корзиною
                tabBarManager.isCartSheetPresented = false
                // Перемикаємося на вкладку "Кав'ярні"
                tabBarManager.switchToTab(.coffeeShops)
            }) {
                HStack {
                    Image(systemName: "cup.and.saucer.fill")
                    Text("Перейти до кав'ярень")
                }
                .padding()
                .background(Color("primary"))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.top, 12)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // Секція для введення коментаря
    private var commentSectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Коментар до замовлення")
                .font(.subheadline)
                .foregroundColor(Color("secondaryText"))
            
            CustomTextField(
                iconName: "text.bubble", 
                placeholder: "Вкажіть особливі побажання...", 
                text: $comment
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    // Секція підсумку та оформлення замовлення
    private var checkoutSectionView: some View {
        VStack(spacing: 12) {
            // Підсумок - без фону
            HStack {
                Text("Всього:")
                    .font(.headline)
                    .foregroundColor(Color("primaryText"))
                
                Spacer()
                
                Text(viewModel.formattedTotalPrice)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color("primary"))
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Кнопка оформлення - з фоном тільки для самої кнопки
            Button(action: {
                Task {
                    await viewModel.checkout(comment: comment.isEmpty ? nil : comment)
                }
            }) {
                HStack {
                    Text("Оформити замовлення")
                        .font(.headline)
                    
                    Spacer()
                    
                    Image(systemName: "creditcard.fill")
                }
                .padding()
                .background(Color("primary"))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .disabled(viewModel.isLoading)
            
            // Якщо є активне замовлення, показуємо кнопки для повторної оплати і скасування
            if viewModel.currentOrderId != nil {
                HStack(spacing: 16) {
                    // Кнопка для повторної оплати
                    Button(action: {
                        Task {
                            await viewModel.retryPayment()
                        }
                    }) {
                        HStack {
                            Image(systemName: "creditcard")
                            Text("Спробувати оплатити знову")
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color("primary").opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    // Кнопка для скасування замовлення
                    Button(action: {
                        showOrderCancellationAlert = true
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Скасувати")
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .padding(.bottom, 24)
    }
    
    // Вікно успішної оплати
    private var successPaymentView: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Зображення успіху
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.green)
                }
                
                // Текст успіху
                Text("Оплата успішна!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Ваше замовлення прийнято і буде готове найближчим часом")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                // Кнопка закриття
                Button(action: {
                    viewModel.showPaymentSuccess = false
                    viewModel.currentOrderId = nil
                }) {
                    Text("Продовжити")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("primary"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                }
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("cardColor").opacity(0.95))
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 32)
        }
    }
    
    // Кнопка закриття sheet
    private func closeSheet() {
        tabBarManager.isCartSheetPresented = false
    }
}

// MARK: - Компонент рядка товару в корзині
struct CartItemRow: View {
    let item: CartItem
    let onQuantityChanged: (Int) -> Void
    let onRemove: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Зображення товару або заглушка
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color("inputField"))
                    .frame(width: 80, height: 90)
                
                if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        case .failure(_), .empty:
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 30))
                                .foregroundColor(Color("primary"))
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color("primary"))
                }
            }
            
            // Інформація про товар
            VStack(alignment: .leading, spacing: 4) {
                // Назва з розміром
                HStack(spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(Color("primaryText"))
                        .lineLimit(1)
                    
                    if let selectedSize = item.selectedSize {
                        Text(selectedSize)
                            .font(.subheadline)
                            .foregroundColor(Color("primary"))
                            .fontWeight(.bold)
                    }
                }
                
                // Компактний варіант відображення кастомізації
                if let customizationSummary = item.getCustomizationSummary() {
                    Text(customizationSummary)
                        .font(.caption2)
                        .foregroundColor(Color("secondaryText"))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .onAppear {
                            print("📝 CartItemRow: Товар має кастомізацію: \(customizationSummary)")
                            print("   - Повні дані кастомізації: \(String(describing: item.customization))")
                        }
                }
                
                // Елементи керування кількістю
                HStack(spacing: 12) {
                    // Зменшення кількості
                    Button(action: {
                        if item.quantity > 1 {
                            onQuantityChanged(item.quantity - 1)
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(item.quantity > 1 ? Color("primary") : Color("secondaryText").opacity(0.5))
                    }
                    .disabled(item.quantity <= 1)
                    
                    // Кількість
                    Text("\(item.quantity)")
                        .font(.headline)
                        .foregroundColor(Color("primaryText"))
                        .frame(minWidth: 24)
                        .multilineTextAlignment(.center)
                    
                    // Збільшення кількості
                    Button(action: {
                        onQuantityChanged(item.quantity + 1)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color("primary"))
                    }
                }
            }
            
            Spacer()
            
            // Кнопка видалення і загальна сума
            VStack(alignment: .trailing, spacing: 8) {
                // Кнопка видалення
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(Color.red.opacity(0.8))
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Загальна сума
                Text("₴\(formatPrice(item.totalPrice))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color("primary"))
            }
        }
        .padding(12)
        .background(
            ZStack {
                // Скляний фон
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.clear)
                    .overlay(
                        BlurView(
                            style: colorScheme == .light ? .systemThinMaterial : .systemMaterialDark,
                            opacity: colorScheme == .light ? 0.95 : 0.95
                        )
                    )
                    .overlay(
                        Group {
                            if colorScheme == .light {
                                // Тонування для світлої теми
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color("nidusMistyBlue").opacity(0.25),
                                        Color("nidusCoolGray").opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .opacity(0.4)
                                
                                Color("nidusLightBlueGray").opacity(0.12)
                            } else {
                                // Темна тема
                                Color.black.opacity(0.15)
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            colorScheme == .light
                                ? Color("nidusCoolGray").opacity(0.4)
                                : Color.black.opacity(0.35),
                            colorScheme == .light
                                ? Color("nidusLightBlueGray").opacity(0.25)
                                : Color.black.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
    }
    
    // Форматування ціни
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: price)) ?? "\(price)"
    }
}

// MARK: - WebView для сторінки оплати
struct PaymentWebView: UIViewRepresentable {
    let url: URL
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        
        // Дозволяємо всі медіа типи
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        print("🌐 PaymentWebView: Створено WebView для URL: \(url)")
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
        print("🌐 PaymentWebView: Завантажуємо URL: \(url)")
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: PaymentWebView
        
        init(_ parent: PaymentWebView) {
            self.parent = parent
        }
        
        // Обробка початку навігації
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            guard let url = navigationAction.request.url else {
                print("⚠️ PaymentWebView: URL не знайдено в navigation action")
                decisionHandler(.allow)
                return
            }
            
            print("🔗 PaymentWebView: Navigation до URL: \(url.absoluteString)")
            
            // Перевіряємо різні варіанти redirect URL
            let urlString = url.absoluteString.lowercased()
            
            if urlString.contains("nidus://") || 
               urlString.contains("payment-callback") ||
               urlString.contains("success") ||
               urlString.contains("завершено") ||
               url.scheme == "nidus" {
                
                print("✅ PaymentWebView: Знайдено redirect URL, закриваємо WebView")
                print("   - URL: \(url.absoluteString)")
                print("   - Scheme: \(url.scheme ?? "немає")")
                print("   - Host: \(url.host ?? "немає")")
                
                // Відхиляємо навігацію до redirect URL
                decisionHandler(.cancel)
                
                // Закриваємо WebView та повідомляємо про успішну оплату
                DispatchQueue.main.async {
                    // Відправляємо notification про успішну оплату
                    NotificationCenter.default.post(name: .paymentSuccessful, object: nil)
                    
                    // Закриваємо WebView
                    self.parent.presentationMode.wrappedValue.dismiss()
                }
                
                return
            }
            
            // Дозволяємо всі інші URL
            decisionHandler(.allow)
        }
        
        // Обробка завершення завантаження
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ PaymentWebView: Сторінка завантажена")
            
            if let url = webView.url {
                print("   - Поточний URL: \(url.absoluteString)")
            }
        }
        
        // Обробка помилок завантаження
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ PaymentWebView: Помилка завантаження: \(error.localizedDescription)")
        }
        
        // Обробка помилок provisional navigation
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            let nsError = error as NSError
            print("❌ PaymentWebView: Provisional navigation помилка:")
            print("   - Код: \(nsError.code)")
            print("   - Домен: \(nsError.domain)")
            print("   - Опис: \(error.localizedDescription)")
            
            // Ігноруємо помилки timeout для redirect URL
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorTimedOut {
                print("⚠️ PaymentWebView: Timeout помилка (можливо redirect), перевіряємо URL")
                
                if let url = webView.url, url.scheme == "nidus" {
                    print("✅ PaymentWebView: Timeout на redirect URL, закриваємо WebView")
                    
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .paymentSuccessful, object: nil)
                        self.parent.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct CartView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CartView()
        }
    }
}
