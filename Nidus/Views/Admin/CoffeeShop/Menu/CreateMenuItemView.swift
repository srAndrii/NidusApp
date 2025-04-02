//
//  CreateMenuItemView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/2/25.
//

import SwiftUI

struct CreateMenuItemView: View {
    @Environment(\.presentationMode) var presentationMode
    let menuGroup: MenuGroup
    @ObservedObject var viewModel: MenuItemsViewModel
    
    @State private var name = ""
    @State private var price = ""
    @State private var description = ""
    @State private var isAvailable = true
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("backgroundColor")
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Інформація про пункт меню")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            CustomTextField(
                                iconName: "cup.and.saucer",
                                placeholder: "Назва",
                                text: $name
                            )
                            
                            CustomTextField(
                                iconName: "hryvniasign.circle",
                                placeholder: "Ціна (₴)",
                                text: $price,
                                keyboardType: .decimalPad
                            )
                            
                            CustomTextField(
                                iconName: "text.alignleft",
                                placeholder: "Опис (необов'язково)",
                                text: $description
                            )
                            
                            // Перемикач доступності
                            HStack {
                                Text("Доступний для замовлення:")
                                    .foregroundColor(Color("primaryText"))
                                
                                Spacer()
                                
                                Toggle("", isOn: $isAvailable)
                                    .labelsHidden()
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(Color("cardColor"))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Кнопка створення
                        Button(action: createMenuItem) {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Створити пункт меню")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(name.isEmpty || price.isEmpty ? Color.gray : Color("primary"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .disabled(name.isEmpty || price.isEmpty || isSubmitting)
                        
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
            .navigationTitle("Новий пункт меню")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Скасувати") {
                presentationMode.wrappedValue.dismiss()
            })
            .onChange(of: viewModel.showSuccess) { newValue in
                if newValue {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private func createMenuItem() {
        guard let priceDecimal = Decimal(string: price.replacingOccurrences(of: ",", with: ".")) else {
            viewModel.error = "Вкажіть коректну ціну"
            return
        }
        
        isSubmitting = true
        
        Task {
            await viewModel.createMenuItem(
                groupId: menuGroup.id,
                name: name,
                price: priceDecimal,
                description: description.isEmpty ? nil : description,
                isAvailable: isAvailable
            )
            
            isSubmitting = false
        }
    }
}
