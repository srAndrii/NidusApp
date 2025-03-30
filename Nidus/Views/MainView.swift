//
//  MainView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        TabView {
            // Вкладка "Кав'ярні"
            NavigationView {
                HomeView()
            }
            .tabItem {
                Label("Кав'ярні", systemImage: "cup.and.saucer.fill")
            }
            
            // Вкладка "QR-код"
            NavigationView {
                QRCodeView()
            }
            .tabItem {
                Label("Мій код", systemImage: "qrcode")
            }
            
            // Вкладка "Профіль"
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Профіль", systemImage: "person.fill")
            }
        }
        .accentColor(Color("primary")) // Оранжевий колір для активних елементів
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(AuthenticationManager())
            .preferredColorScheme(.dark)
    }
}
