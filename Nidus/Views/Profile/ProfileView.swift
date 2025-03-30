//
//  ProfileView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/30/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        ZStack {
            // Явно встановлюємо колір фону для всього екрану
            Color("backgroundColor")
                .edgesIgnoringSafeArea(.all)
            
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
                    .fill(Color("secondaryText").opacity(0.2))
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
                    
                    // Розділювач перед адмін-панеллю
                    Divider()
                        .background(Color("secondaryText").opacity(0.2))
                        .padding(.leading, 56)
                    
                    // Додаємо пункт Адмін панель
                    NavigationLink(destination: AdminPanelView()) {
                        HStack {
                            Image(systemName: "shield.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color("primary"))
                                .frame(width: 24, height: 24)
                                .padding(.trailing, 8)
                            
                            Text("Адмін панель")
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

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
                .environmentObject(AuthenticationManager())
        }
    }
}
