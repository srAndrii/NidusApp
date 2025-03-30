//
//  MainView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

// Views/MainView.swift
import SwiftUI

struct MainView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        TabView {
            NavigationView {
                ContentView()
            }
            .tabItem {
                Label("Кав'ярні", systemImage: "cup.and.saucer.fill")
            }
            
            NavigationView {
                OrdersView()
            }
            .tabItem {
                Label("Замовлення", systemImage: "list.bullet")
            }
            
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Профіль", systemImage: "person.fill")
            }
        }
    }
}

// Заглушки для інших екранів
struct OrdersView: View {
    var body: some View {
        Text("Історія замовлень")
            .navigationTitle("Мої замовлення")
    }
}

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        VStack {
            Text("Профіль користувача")
                .navigationTitle("Мій профіль")
            
            Button("Вийти") {
                Task {
                    await authManager.signOut()
                }
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.red)
            .cornerRadius(10)
            .padding(.top, 20)
        }
    }
}

#Preview {
    MainView()
}
