//
//  AdminUsersMenuView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/30/25.
//

import SwiftUI

struct AdminUsersMenuView: View {
    var body: some View {
        // Використовуємо ZStack для повного контролю над фоном
        ZStack {
            // Явно встановлюємо колір фону і переконуємося, що він займає весь екран
            Color("backgroundColor")
                .edgesIgnoringSafeArea(.all)
            
            // Вміст з вертикальним скролом
            ScrollView {
                VStack(spacing: 0) {
                    Text("ДОСТУПНІ ДІЇ")
                        .font(.caption)
                        .foregroundColor(Color("secondaryText"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    
                    // Картка з меню (тут явно задаємо фон для картки)
                    VStack(spacing: 0) {
                        // Знайти користувачів - виправлене посилання
                        NavigationLink(destination: AdminUsersView()) {
                            HStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color("primary"))
                                    .frame(width: 28, height: 28)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Знайти користувачів")
                                        .font(.headline)
                                        .foregroundColor(Color("primaryText"))
                                    
                                    Text("Пошук за email або всіх користувачів")
                                        .font(.caption)
                                        .foregroundColor(Color("secondaryText"))
                                }
                                
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
                            .padding(.leading, 60)
                        
                        // Оновити профіль - виправлене посилання
                        NavigationLink(destination: AdminUserUpdateProfileView()) {
                            HStack(spacing: 16) {
                                Image(systemName: "person.text.rectangle")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color("primary"))
                                    .frame(width: 28, height: 28)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Оновити профіль користувача")
                                        .font(.headline)
                                        .foregroundColor(Color("primaryText"))
                                    
                                    Text("Редагування імені, прізвища та телефону")
                                        .font(.caption)
                                        .foregroundColor(Color("secondaryText"))
                                }
                                
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
                            .padding(.leading, 60)
                        
                        // Змінити роль - виправлене посилання
                        NavigationLink(destination: AdminUserUpdateRoleView()) {
                            HStack(spacing: 16) {
                                Image(systemName: "shield.lefthalf.filled")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color("primary"))
                                    .frame(width: 28, height: 28)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Змінити роль користувача")
                                        .font(.headline)
                                        .foregroundColor(Color("primaryText"))
                                    
                                    Text("Призначення ролей для користувача")
                                        .font(.caption)
                                        .foregroundColor(Color("secondaryText"))
                                }
                                
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
                            .padding(.leading, 60)
                        
                        // Видалити користувача - виправлене посилання
                        NavigationLink(destination: AdminUserDeleteView()) {
                            HStack(spacing: 16) {
                                Image(systemName: "person.crop.circle.badge.xmark")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color("primary"))
                                    .frame(width: 28, height: 28)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Видалити користувача")
                                        .font(.headline)
                                        .foregroundColor(Color("primaryText"))
                                    
                                    Text("Повне видалення облікового запису")
                                        .font(.caption)
                                        .foregroundColor(Color("secondaryText"))
                                }
                                
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
        .navigationTitle("Управління користувачами")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AdminUsersMenuView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AdminUsersMenuView()
        }
        .preferredColorScheme(.dark)
    }
}
