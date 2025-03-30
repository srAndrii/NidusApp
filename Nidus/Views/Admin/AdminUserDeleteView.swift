//
//  AdminUserDeleteView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/30/25.
//

import SwiftUI

struct AdminUserDeleteView: View {
    @StateObject private var viewModel = AdminViewModel()
    @State private var searchEmail = ""
    @State private var isUserFound = false
    @State private var showConfirmation = false
    @State private var showSuccessAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Попередження
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 24))
                    
                    Text("Увага! Ця дія незворотна.")
                        .font(.headline)
                        .foregroundColor(.yellow)
                }
                .padding()
                .background(Color.yellow.opacity(0.15))
                .cornerRadius(12)
                .padding(.horizontal)
                
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
                                    
                                    if viewModel.searchedUser != nil {
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
                        Text("Крок 2: Підтвердіть видалення")
                            .font(.headline)
                            .foregroundColor(Color("primaryText"))
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        // Картка користувача
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color("inputField"))
                                    .frame(width: 50, height: 50)
                                
                                if let avatarUrl = user.avatarUrl, let url = URL(string: avatarUrl) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .clipShape(Circle())
                                        case .failure(_), .empty:
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(Color("secondaryText"))
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .frame(width: 50, height: 50)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color("secondaryText"))
                                }
                            }
                            
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
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color("cardColor"))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Кнопка видалення
                        Button(action: {
                            showConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 16))
                                Text("Видалити користувача")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                        .padding()
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
        .navigationTitle("Видалення користувача")
        .navigationBarTitleDisplayMode(.inline)
        .actionSheet(isPresented: $showConfirmation) {
            ActionSheet(
                title: Text("Підтвердження видалення"),
                message: Text("Ви впевнені, що хочете видалити цього користувача? Ця дія незворотна."),
                buttons: [
                    .destructive(Text("Видалити")) {
                        if let user = viewModel.searchedUser {
                            Task {
                                await viewModel.deleteUser(userId: user.id)
                                if viewModel.error == nil {
                                    showSuccessAlert = true
                                }
                            }
                        }
                    },
                    .cancel(Text("Скасувати"))
                ]
            )
        }
        .alert("Успішно видалено", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {
                // Повертаємось на попередній екран
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Користувача успішно видалено")
        }
    }
}

struct AdminUserDeleteView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AdminUserDeleteView()
        }
        .preferredColorScheme(.dark)
    }
}
