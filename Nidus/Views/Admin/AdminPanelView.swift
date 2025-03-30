//
//  AdminPanelView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/30/25.
//

import SwiftUI

struct AdminPanelView: View {
    var body: some View {
        // Використовуємо ZStack щоб мати повний контроль над фоном
        ZStack {
            // Явно встановлюємо колір фону і переконуємося, що він займає весь екран
            Color("backgroundColor") // або можна спробувати інші назви кольорів, якщо ця не працює
                .edgesIgnoringSafeArea(.all)
            
            // Вміст з вертикальним скролом
            ScrollView {
                VStack(spacing: 0) {
                    Text("АДМІНІСТРУВАННЯ")
                        .font(.caption)
                        .foregroundColor(Color("secondaryText"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    
                    // Картка з меню (тут явно задаємо фон для картки)
                    VStack(spacing: 0) {
                        // Користувачі
                        NavigationLink(destination: AdminUsersMenuView()) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color("primary"))
                                    .frame(width: 24, height: 24)
                                
                                Text("Користувачі")
                                    .font(.body)
                                    .foregroundColor(Color("primaryText"))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color("secondaryText"))
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                        }
                        
                        Divider()
                            .background(Color("secondaryText").opacity(0.2))
                            .padding(.leading, 56)
                        
                        // Ролі
                        NavigationLink(destination: Text("Управління ролями")) {
                            HStack {
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color("primary"))
                                    .frame(width: 24, height: 24)
                                
                                Text("Ролі")
                                    .font(.body)
                                    .foregroundColor(Color("primaryText"))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color("secondaryText"))
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                        }
                        
                        Divider()
                            .background(Color("secondaryText").opacity(0.2))
                            .padding(.leading, 56)
                        
                        // Кав'ярні
                        NavigationLink(destination: Text("Управління кав'ярнями")) {
                            HStack {
                                Image(systemName: "cup.and.saucer.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color("primary"))
                                    .frame(width: 24, height: 24)
                                
                                Text("Кав'ярні")
                                    .font(.body)
                                    .foregroundColor(Color("primaryText"))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color("secondaryText"))
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                        }
                        
                        Divider()
                            .background(Color("secondaryText").opacity(0.2))
                            .padding(.leading, 56)
                        
                        // Меню групи
                        NavigationLink(destination: Text("Управління групами меню")) {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color("primary"))
                                    .frame(width: 24, height: 24)
                                
                                Text("Меню групи")
                                    .font(.body)
                                    .foregroundColor(Color("primaryText"))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color("secondaryText"))
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                        }
                        
                        Divider()
                            .background(Color("secondaryText").opacity(0.2))
                            .padding(.leading, 56)
                        
                        // Пункти меню
                        NavigationLink(destination: Text("Управління пунктами меню")) {
                            HStack {
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color("primary"))
                                    .frame(width: 24, height: 24)
                                
                                Text("Пункти меню")
                                    .font(.body)
                                    .foregroundColor(Color("primaryText"))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color("secondaryText"))
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                        }
                        
                        Divider()
                            .background(Color("secondaryText").opacity(0.2))
                            .padding(.leading, 56)
                        
                        // Замовлення
                        NavigationLink(destination: Text("Управління замовленнями")) {
                            HStack {
                                Image(systemName: "bag.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color("primary"))
                                    .frame(width: 24, height: 24)
                                
                                Text("Замовлення")
                                    .font(.body)
                                    .foregroundColor(Color("primaryText"))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color("secondaryText"))
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                        }
                        
                        Divider()
                            .background(Color("secondaryText").opacity(0.2))
                            .padding(.leading, 56)
                        
                        // Платежі
                        NavigationLink(destination: Text("Управління платежами")) {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color("primary"))
                                    .frame(width: 24, height: 24)
                                
                                Text("Платежі")
                                    .font(.body)
                                    .foregroundColor(Color("primaryText"))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color("secondaryText"))
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                        }
                    }
                    .background(Color("cardColor"))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Адмін панель")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AdminPanelView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AdminPanelView()
        }
        .preferredColorScheme(.dark)
    }
}
