//
//  PaymentWebView.swift
//  Nidus
//
//  Created by Claude on 5/31/25.
//

import SwiftUI
import WebKit

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
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ PaymentWebView: Сторінка завантажена")
            
            if let url = webView.url {
                print("   - Поточний URL: \(url.absoluteString)")
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ PaymentWebView: Помилка завантаження: \(error.localizedDescription)")
        }
        
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