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
    @State private var isUpdating = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
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
                                        print("Пошук користувача: \(searchEmail)")
                                        await viewModel.searchUserByEmail(email: searchEmail)
                                        
                                        if let user = viewModel.searchedUser {
                                            firstName = user.firstName ?? ""
                                            lastName = user.lastName ?? ""
                                            phone = user.phone ?? ""
                                            isUserFound = true
                                            
                                            // Відладка - виводимо знайдені дані
                                            print("Знайдено користувача: \(user.email)")
                                            print("firstName: \(user.firstName ?? "nil"), lastName: \(user.lastName ?? "nil"), phone: \(user.phone ?? "nil")")
                                        } else {
                                            isUserFound = false
                                            print("Користувача не знайдено")
                                        }
                                    } catch {
                                        print("Помилка при пошуку: \(error)")
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
                    ProgressView("Завантаження...")
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
                                
                                // Поточні дані користувача
                                Group {
                                    if let firstName = user.firstName {
                                        Text("Ім'я: \(firstName)")
                                            .font(.caption)
                                            .foregroundColor(Color("secondaryText"))
                                    }
                                    
                                    if let lastName = user.lastName {
                                        Text("Прізвище: \(lastName)")
                                            .font(.caption)
                                            .foregroundColor(Color("secondaryText"))
                                    }
                                    
                                    if let phone = user.phone {
                                        Text("Телефон: \(phone)")
                                            .font(.caption)
                                            .foregroundColor(Color("secondaryText"))
                                    }
                                }
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
                                isUpdating = true
                                do {
                                    // Виводимо дані перед оновленням
                                    print("Дані для оновлення:")
                                    print("firstName: \(firstName.isEmpty ? "nil" : firstName)")
                                    print("lastName: \(lastName.isEmpty ? "nil" : lastName)")
                                    print("phone: \(phone.isEmpty ? "nil" : phone)")
                                    
                                    // Викликаємо метод оновлення профілю, тепер з правильним endpoint
                                    await viewModel.updateUserProfile(
                                        userId: user.id,
                                        firstName: firstName.isEmpty ? nil : firstName,
                                        lastName: lastName.isEmpty ? nil : lastName,
                                        phone: phone.isEmpty ? nil : phone
                                    )
                                    
                                    // Перевіряємо наявність помилки
                                    if let error = viewModel.error {
                                        errorMessage = error
                                        showErrorAlert = true
                                    } else {
                                        // Оновлюємо дані на формі
                                        if let updatedUser = viewModel.searchedUser {
                                            // Оновлення полів форми
                                            firstName = updatedUser.firstName ?? ""
                                            lastName = updatedUser.lastName ?? ""
                                            phone = updatedUser.phone ?? ""
                                        }
                                        showSuccessAlert = true
                                    }
                                } catch {
                                    print("Помилка оновлення профілю: \(error)")
                                    errorMessage = error.localizedDescription
                                    showErrorAlert = true
                                }
                                isUpdating = false
                            }
                        }) {
                            if isUpdating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color("primary"))
                                    .cornerRadius(12)
                            } else {
                                Text("Оновити профіль")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color("primary"))
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                        .disabled(viewModel.isLoading || isUpdating)
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
            Button("OK", role: .cancel) {
                // Повторно оновимо дані після успішного оновлення
                if !searchEmail.isEmpty {
                    Task {
                        await viewModel.searchUserByEmail(email: searchEmail)
                    }
                }
            }
        } message: {
            Text("Профіль користувача успішно оновлено")
        }
        .alert("Помилка оновлення", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage.isEmpty ? "Невідома помилка при оновленні профілю" : errorMessage)
        }
    }
}
