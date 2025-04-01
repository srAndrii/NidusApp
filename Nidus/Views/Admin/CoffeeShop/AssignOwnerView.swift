//
//  AssignOwnerView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/31/25.
//


import SwiftUI

struct AssignOwnerView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: CoffeeShopViewModel
    @StateObject private var adminViewModel = AdminViewModel()
    let coffeeShop: CoffeeShop
    
    @State private var searchEmail = ""
    @State private var isSearching = false
    @State private var selectedUserId: String?
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("backgroundColor")
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Інформація про кав'ярню
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Кав'ярня")
                                .font(.headline)
                                .foregroundColor(Color("primaryText"))
                                .padding(.horizontal)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(coffeeShop.name)
                                        .font(.title3)
                                        .foregroundColor(Color("primaryText"))
                                    
                                    if let address = coffeeShop.address {
                                        Text(address)
                                            .font(.subheadline)
                                            .foregroundColor(Color("secondaryText"))
                                    }
                                    
                                    Text("ID: \(coffeeShop.id)")
                                        .font(.caption)
                                        .foregroundColor(Color("secondaryText"))
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color("cardColor"))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .background(Color("cardColor"))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Пошук користувача
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Знайти користувача")
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
                                    searchUser()
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
                            
                            // Результати пошуку
                            if adminViewModel.isLoading {
                                ProgressView("Пошук...")
                                    .padding()
                            } else if let error = adminViewModel.error {
                                Text(error)
                                    .foregroundColor(.red)
                                    .padding()
                                    .multilineTextAlignment(.center)
                            } else if let user = adminViewModel.searchedUser {
                                // Показуємо знайденого користувача
                                VStack(spacing: 8) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(user.fullName)
                                                .font(.headline)
                                                .foregroundColor(Color("primaryText"))
                                            
                                            Text(user.email)
                                                .font(.subheadline)
                                                .foregroundColor(Color("secondaryText"))
                                            
                                            Text("ID: \(user.id)")
                                                .font(.caption)
                                                .foregroundColor(Color("secondaryText"))
                                            
                                            // Показуємо ролі
                                            Text("Ролі: \(user.rolesString)")
                                                .font(.caption)
                                                .foregroundColor(Color("secondaryText"))
                                        }
                                        
                                        Spacer()
                                        
                                        // Кнопка вибору
                                        Button(action: {
                                            selectedUserId = user.id
                                        }) {
                                            if selectedUserId == user.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(Color("primary"))
                                            } else {
                                                Image(systemName: "circle")
                                                    .font(.title2)
                                                    .foregroundColor(Color("secondaryText"))
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color("inputField"))
                                    .cornerRadius(12)
                                    
                                    // Перевірка ролі користувача
                                    if !userHasOwnerRole(user) {
                                        HStack {
                                            Image(systemName: "exclamationmark.triangle")
                                                .foregroundColor(.orange)
                                            
                                            Text("Цей користувач не має ролі \"Власник кав'ярні\".")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                        .background(Color("cardColor"))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Кнопка призначення власника
                        Button(action: {
                            assignOwner()
                        }) {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Призначити власника")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedUserId == nil ? Color.gray : Color("primary"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .disabled(selectedUserId == nil || isSubmitting)
                        
                        // Повідомлення про помилку
                        if let error = viewModel.error {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Призначення власника")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Скасувати") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onChange(of: viewModel.showSuccess) { newValue in
                if newValue {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private func searchUser() {
        if !searchEmail.isEmpty {
            isSearching = true
            
            Task {
                await adminViewModel.searchUserByEmail(email: searchEmail)
                isSearching = false
                
                // Якщо знайдено користувача, автоматично вибираємо його
                if let user = adminViewModel.searchedUser {
                    selectedUserId = user.id
                } else {
                    selectedUserId = nil
                }
            }
        }
    }
    
    private func userHasOwnerRole(_ user: User) -> Bool {
        return user.roles?.contains(where: { $0.name == "coffee_shop_owner" }) ?? false
    }
    
    private func assignOwner() {
        guard let userId = selectedUserId else { return }
        
        isSubmitting = true
        
        Task {
            await viewModel.assignOwner(coffeeShopId: coffeeShop.id, userId: userId)
            isSubmitting = false
        }
    }
}
