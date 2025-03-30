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

// Оновлений екран профілю
struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        ZStack {
            Color.backGround
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Заголовок профілю
                VStack(spacing: 16) {
                    // Аватар користувача
                    ZStack {
                        Circle()
                            .fill(Color("cardColor"))
                            .frame(width: 100, height: 100)
                        
                        if let user = authManager.currentUser, let avatarUrl = user.avatarUrl, let url = URL(string: avatarUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .clipShape(Circle())
                                case .failure(_), .empty:
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(Color("secondaryText"))
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: 100, height: 100)
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color("secondaryText"))
                        }
                    }
                    
                    // Ім'я користувача
                    Text(getUserName())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color("primaryText"))
                    
                    // Email користувача
                    Text(getUserEmail())
                        .font(.subheadline)
                        .foregroundColor(Color("secondaryText"))
                }
                .padding(.top, 40)
                
                // Розділювач
                Rectangle()
                    .fill(Color("secondary").opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                
                // Список налаштувань
                VStack(spacing: 0) {
                    ProfileMenuRow(icon: "person.fill", title: "Особисті дані")
                    ProfileMenuRow(icon: "creditcard.fill", title: "Способи оплати")
                    ProfileMenuRow(icon: "bell.fill", title: "Сповіщення")
                    ProfileMenuRow(icon: "questionmark.circle.fill", title: "Підтримка")
                    ProfileMenuRow(icon: "gear", title: "Налаштування")
                }
                .background(Color("cardColor"))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Кнопка виходу
                Button(action: {
                    Task {
                        await authManager.signOut()
                    }
                }) {
                    Text("Вийти")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Мій профіль")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func getUserName() -> String {
        if let user = authManager.currentUser {
            if let firstName = user.firstName, let lastName = user.lastName {
                return "\(firstName) \(lastName)"
            } else if let firstName = user.firstName {
                return firstName
            } else if let lastName = user.lastName {
                return lastName
            }
        }
        return "Користувач Nidus"
    }
    
    private func getUserEmail() -> String {
        if let user = authManager.currentUser {
            return user.email
        }
        return "email@example.com"
    }
}

// Компонент для елементу меню профілю
struct ProfileMenuRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        Button(action: {
            // Дія при натисканні
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color("primary"))
                    .frame(width: 24, height: 24)
                    .padding(.trailing, 8)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(Color("primaryText"))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color("secondaryText"))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
        }
        .background(Color("cardColor"))
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(AuthenticationManager())
            .preferredColorScheme(.dark)
    }
}
