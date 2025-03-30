//
//  AdminUsersView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/30/25.
//

import SwiftUI

struct AdminUsersView: View {
    @StateObject private var viewModel = AdminViewModel()
    @State private var searchEmail = ""
    @State private var isShowingSearchResult = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Пошук користувача за email
            VStack(spacing: 16) {
                HStack {
                    CustomTextField(
                        iconName: "envelope",
                        placeholder: "Пошук користувача за email",
                        text: $searchEmail,
                        keyboardType: .emailAddress
                    )
                    
                    Button(action: {
                        if !searchEmail.isEmpty {
                            Task {
                                await viewModel.searchUserByEmail(email: searchEmail)
                                isShowingSearchResult = true
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
                
                // Показуємо результат пошуку
                if isShowingSearchResult {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color("primary")))
                    } else if let error = viewModel.error {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    } else if let user = viewModel.searchedUser {
                        UserRowView(user: user)
                            .background(Color("cardColor"))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    } else {
                        Text("Користувача не знайдено")
                            .foregroundColor(Color("secondaryText"))
                            .padding()
                    }
                }
            }
            
            // Кнопка "Показати всіх користувачів"
            Button(action: {
                Task {
                    await viewModel.getAllUsers()
                }
            }) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 16))
                    Text("Показати всіх користувачів")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color("primary"))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            // Список всіх користувачів
            if viewModel.isLoading {
                Spacer()
                ProgressView("Завантаження...")
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("primary")))
                Spacer()
            } else if let error = viewModel.error {
                Spacer()
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else if !viewModel.users.isEmpty {
                List {
                    ForEach(viewModel.users) { user in
                        UserRowView(user: user)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .background(Color("backgroundColor"))
            } else if !viewModel.isLoading {
                Spacer()
                Text("Натисніть кнопку, щоб загрузити список користувачів")
                    .foregroundColor(Color("secondaryText"))
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            }
        }
        .background(Color("backgroundColor")
            .ignoresSafeArea())
        .navigationTitle("Управління користувачами")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Компонент для відображення окремого користувача
struct UserRowView: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 12) {
            // Аватар користувача
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
            
            // Інформація про користувача
            VStack(alignment: .leading, spacing: 4) {
                Text(user.fullName)
                    .font(.headline)
                    .foregroundColor(Color("primaryText"))
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(Color("secondaryText"))
            }
            
            Spacer()
            
            // Кнопки управління користувачем
            Menu {
                Button(action: {
                    // Редагувати користувача
                }) {
                    Label("Редагувати", systemImage: "pencil")
                }
                
                Button(action: {
                    // Змінити роль
                }) {
                    Label("Змінити роль", systemImage: "shield")
                }
                
                Button(role: .destructive, action: {
                    // Видалити користувача
                }) {
                    Label("Видалити", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundColor(Color("secondaryText"))
                    .padding(8)
                    .background(Color("inputField").opacity(0.5))
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

struct AdminUsersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AdminUsersView()
        }
        .preferredColorScheme(.dark)
    }
}
