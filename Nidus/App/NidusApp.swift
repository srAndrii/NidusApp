//
//  NidusApp.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//
// App/NidusApp.swift
import SwiftUI

// Розширення для Notification.Name
extension Notification.Name {
    static let paymentSuccessful = Notification.Name(rawValue: "paymentSuccessful")
}

@main
struct NidusApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var tabBarManager = DIContainer.shared.tabBarManager
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authManager.isAuthenticated {
                    MainView()
                        .environmentObject(tabBarManager)
                        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToOrderHistory"))) { _ in
                            // Закриваємо корзину та переходимо до історії замовлень
                            tabBarManager.isCartSheetPresented = false
                            tabBarManager.switchToTab(.orders)
                        }
                } else {
                    AuthView()
                }
            }
            .environmentObject(authManager)
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }
    
    // Обробка deep links
    private func handleDeepLink(_ url: URL) {
        print("🔗 Deep link отримано: \(url)")
        
        // Перевіряємо, чи це callback з оплати
        if url.scheme == "nidus" && url.host == "payment-callback" {
            print("💳 Callback з оплати отримано")
            
            // Закриваємо корзину та повідомляємо CartViewModel про успішну оплату
            DispatchQueue.main.async {
                tabBarManager.isCartSheetPresented = false
                
                // Відправляємо notification для CartViewModel
                NotificationCenter.default.post(name: .paymentSuccessful, object: nil)
                
                print("✅ Корзину закрито та відправлено повідомлення про успішну оплату")
            }
        }
    }
}
