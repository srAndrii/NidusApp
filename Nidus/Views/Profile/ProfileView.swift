//
//  ProfileView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/30/25.
//

import SwiftUI

// Окремий компонент для аватара зі скляним ефектом
struct AvatarBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Circle()
            .fill(Color.clear)
            .overlay(
                // Основний ефект скла
                BlurView(
                    style: colorScheme == .light ? .systemThinMaterialDark : .systemMaterialDark,
                    opacity: colorScheme == .light ? 0.7 : 0.95
                )
            )
            .overlay(
                // Додаткові тонування
                Group {
                    if colorScheme == .light {
                        // Світла тема
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
            .clipShape(Circle())
            .overlay(
                Circle()
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
    }
}

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        // Використовуємо ZStack щоб мати повний контроль над фоном
        ZStack {
            // Спочатку встановлюємо базовий колір фону
            Group {
                if colorScheme == .light {
                    // Для світлої теми використовуємо нові кольори: nidusCoolGray, nidusMistyBlue та nidusLightBlueGray
                    ZStack {
                        // Основний горизонтальний градієнт з більшим акцентом на сірі відтінки
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
                .edgesIgnoringSafeArea(.all)
            
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
            VStack(spacing: 20) {
                // Заголовок профілю
                VStack(spacing: 16) {
                        // Аватар користувача - тепер використовуємо окремий компонент
                    ZStack {
                            // Фон аватара
                            AvatarBackground()
                            .frame(width: 100, height: 100)
                        
                            // Зображення аватара
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
                            .font(.title3)
                            .fontWeight(.semibold)
                        .foregroundColor(Color("primaryText"))
                            .padding(.top, 4)
                    
                    // Email користувача
                    Text(getUserEmail())
                            .font(.footnote)
                            .foregroundColor(Color("secondary"))
                            .padding(.top, 2)
                    }
                    .padding(.top, 30)
                    
                 
                
                    // Список налаштувань зі скляним ефектом
                VStack(spacing: 0) {
                    ProfileMenuRow(icon: "person.fill", title: "Особисті дані")
                        
                        Divider()
                            .background(Color("secondaryText").opacity(0.2))
                            .padding(.leading, 56)
                        
                    ProfileMenuRow(icon: "creditcard.fill", title: "Способи оплати")
                        
                        Divider()
                            .background(Color("secondaryText").opacity(0.2))
                            .padding(.leading, 56)
                        
                    ProfileMenuRow(icon: "bell.fill", title: "Сповіщення")
                        
                        Divider()
                            .background(Color("secondaryText").opacity(0.2))
                            .padding(.leading, 56)
                        
                    NavigationLink(destination: SupportView()) {
                        ProfileMenuRow(icon: "questionmark.circle.fill", title: "Підтримка", isNavigationRow: true)
                    }
                    .buttonStyle(PlainButtonStyle())
                        
                        Divider()
                            .background(Color("secondaryText").opacity(0.2))
                            .padding(.leading, 56)
                        
                    ProfileMenuRow(icon: "gear", title: "Налаштування")
                }
                    .background(
                        ZStack {
                            // Основний ефект скла
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
                                    
                                    // Додаткове тонування для ефекту глибини
                                    Color("nidusLightBlueGray").opacity(0.12)
                                } else {
                                    // Додатковий шар для глибини у темному режимі
                                    Color.black.opacity(0.15)
                                }
                            }
                        }
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
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
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                    .frame(maxWidth: UIScreen.main.bounds.width - 32) // Обмежуємо максимальну ширину картки
                
                    Spacer(minLength: 20)
                
                // Кнопка виходу
                Button(action: {
                    Task {
                        await authManager.signOut()
                    }
                }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.square")
                                .font(.system(size: 16))
                            
                    Text("Вийти")
                        .font(.headline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.red.opacity(0.8),
                                    Color.red
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.red.opacity(0.3), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 30)
        }
                .padding(.top, 16)
            }
        }
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
