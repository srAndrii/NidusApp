//
//  AdminUserUpdateProfileView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/30/25.
//

import SwiftUI

struct AdminUserUpdateProfileView: View {
    @StateObject private var viewModel = AdminViewModel()
    @State private var searchEmail = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var isUserFound = false
    @State private var showSuccessAlert = false
    
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
                                    await viewModel.searchUserByEmail(email: searchEmail)
                                    
                                    if let user = viewModel.searchedUser {
                                        firstName = user.firstName ?? ""
                                        lastName = user.lastName ?? ""
                                        phone = user.phone ?? ""
                                        isUserFound = true
                                    } else {
                                        isUserFound = false
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
                        Text("Крок 2: Оновіть дані")
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
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color("cardColor"))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Форма оновлення
                        VStack(spacing: 12) {
                            CustomTextField(
                                iconName: "person.fill",
                                placeholder: "Ім'я",
                                text: $firstName
                            )
                            
                            CustomTextField(
                                iconName: "person.fill",
                                placeholder: "Прізвище",
                                text: $lastName
                            )
                            
                            CustomTextField(
                                iconName: "phone.fill",
                                placeholder: "Телефон",
                                text: $phone,
                                keyboardType: .phonePad
                            )
                        }
                        .padding(.horizontal)
                        
                        // Кнопка оновлення
                        Button(action: {
                            Task {
                                // Викликаємо оновлення профілю через модель
                                do {
                                    try await viewModel.updateUserProfile(
                                        userId: user.id,
                                        firstName: firstName.isEmpty ? nil : firstName,
                                        lastName: lastName.isEmpty ? nil : lastName,
                                        phone: phone.isEmpty ? nil : phone
                                    )
                                    showSuccessAlert = true
                                } catch {
                                    // Помилка обробляється у viewModel і потрапляє в viewModel.error
                                }
                            }
                        }) {
                            Text("Оновити профіль")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color("primary"))
                                .cornerRadius(12)
                        }
                        .padding()
                        .disabled(viewModel.isLoading)
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
        .navigationTitle("Оновлення профілю")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Успішно оновлено", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Профіль користувача успішно оновлено")
        }
    }
}

struct AdminUserUpdateProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AdminUserUpdateProfileView()
        }
        .preferredColorScheme(.dark)
    }
}
