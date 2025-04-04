//
//  AdminUserUpdateRoleView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/30/25.
//

import SwiftUI

struct AdminUserUpdateRoleView: View {
    @StateObject private var viewModel = AdminViewModel()
    @State private var searchEmail = ""
    @State private var selectedRoles: [String] = []
    @State private var isUserFound = false
    @State private var showSuccessAlert = false
    
    // Доступні ролі
    let availableRoles = [
        "buyer",
        "cashier",
        "coffee_shop_owner",
        "superadmin"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Секція пошуку користувача
                VStack(alignment: .leading, spacing: 10) {
                    Text("Крок 1: Знайдіть користувача")
                        .font(.headline)
                        .foregroundColor(Color("primaryText"))
                        .padding(.horizontal)
                    
                    HStack {
                        CustomTextField(
                            iconName: "envelope",
                            placeholder: "Email користувача",
                            text: $searchEmail,
                            keyboardType: .emailAddress
                        )
                        
                        Button(action: {
                            if !searchEmail.isEmpty {
                                Task {
                                    do {
                                        await viewModel.searchUserByEmail(email: searchEmail)
                                        
                                        if let user = viewModel.searchedUser {
                                            print("Користувача знайдено: \(user.email)")
                                            print("Ролі: \(user.roles?.map { $0.name } ?? [])")
                                            
                                            // Завантажуємо поточні ролі користувача
                                            if let userRoles = user.roles {
                                                selectedRoles = userRoles.map { $0.name }
                                            } else {
                                                // Якщо ролей немає, встановлюємо порожній масив
                                                selectedRoles = []
                                            }
                                            isUserFound = true
                                        } else {
                                            isUserFound = false
                                            print("Користувача не знайдено")
                                        }
                                    } catch {
                                        print("Помилка пошуку користувача: \(error)")
                                    }
                                }
                            }
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20))
                                .foregroundColor(Color("primary"))
                                .frame(width: 44, height: 44)
                                .background(Color("inputField"))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 10)
                
                if viewModel.isLoading {
                    ProgressView("Пошук користувача...")
                        .padding()
                } else if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .multilineTextAlignment(.center)
                } else if let user = viewModel.searchedUser, isUserFound {
                    // Секція відображення знайденого користувача
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Крок 2: Виберіть ролі")
                            .font(.headline)
                            .foregroundColor(Color("primaryText"))
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        // Картка користувача
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.email)
                                    .font(.headline)
                                    .foregroundColor(Color("primaryText"))
                                
                                Text("ID: \(user.id)")
                                    .font(.caption)
                                    .foregroundColor(Color("secondaryText"))
                                
                                // Додаємо відображення поточних ролей
                                Text("Поточні ролі: \(user.rolesString)")
                                    .font(.caption)
                                    .foregroundColor(Color("secondaryText"))
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color("cardColor"))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Вибір ролей
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Виберіть ролі:")
                                .font(.subheadline)
                                .foregroundColor(Color("secondaryText"))
                                .padding(.horizontal)
                            
                            ForEach(availableRoles, id: \.self) { role in
                                Button(action: {
                                    if selectedRoles.contains(role) {
                                        selectedRoles.removeAll { $0 == role }
                                    } else {
                                        selectedRoles.append(role)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: selectedRoles.contains(role) ? "checkmark.square.fill" : "square")
                                            .foregroundColor(Color("primary"))
                                        
                                        Text(role)
                                            .foregroundColor(Color("primaryText"))
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(Color("cardColor"))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Кнопка оновлення
                        Button(action: {
                            Task {
                                do {
                                    // Викликаємо оновлення ролей через модель
                                    await viewModel.updateUserRoles(
                                        userId: user.id,
                                        roles: selectedRoles
                                    )
                                    
                                    // Оновлюємо інформацію про користувача після оновлення ролей
                                    await viewModel.searchUserByEmail(email: searchEmail)
                                    
                                    showSuccessAlert = true
                                } catch {
                                    print("Помилка оновлення ролей: \(error)")
                                }
                            }
                        }) {
                            Text("Оновити ролі")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color("primary"))
                                .cornerRadius(12)
                        }
                        .padding()
                        .disabled(viewModel.isLoading || selectedRoles.isEmpty)
                    }
                } else if !searchEmail.isEmpty && !viewModel.isLoading {
                    Text("Користувача не знайдено")
                        .foregroundColor(Color("secondaryText"))
                        .padding()
                }
                
                Spacer()
            }
            .padding(.vertical)
        }
        .background(Color("backgroundColor").ignoresSafeArea())
        .navigationTitle("Зміна ролей")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Успішно оновлено", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Ролі користувача успішно оновлено")
        }
    }
}

struct AdminUserUpdateRoleView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AdminUserUpdateRoleView()
        }
        .preferredColorScheme(.dark)
    }
}
