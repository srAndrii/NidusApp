//
//  CreateMenuGroupView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/2/25.
//

import SwiftUI

struct CreateMenuGroupView: View {
    @Environment(\.presentationMode) var presentationMode
    let coffeeShopId: String
    @ObservedObject var viewModel: MenuGroupsViewModel
    
    @State private var name = ""
    @State private var description = ""
    @State private var displayOrder = 1
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("backgroundColor")
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Інформація про групу меню")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            CustomTextField(
                                iconName: "list.bullet",
                                placeholder: "Назва групи",
                                text: $name
                            )
                            
                            CustomTextField(
                                iconName: "text.alignleft",
                                placeholder: "Опис (необов'язково)",
                                text: $description
                            )
                            
                            // Вибір порядку відображення
                            HStack {
                                Text("Порядок відображення:")
                                    .foregroundColor(Color("primaryText"))
                                
                                Spacer()
                                
                                Stepper(value: $displayOrder, in: 1...100) {
                                    Text("\(displayOrder)")
                                        .foregroundColor(Color("primaryText"))
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(Color("cardColor"))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Кнопка створення
                        Button(action: createMenuGroup) {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Створити групу меню")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(name.isEmpty ? Color.gray : Color("primary"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .disabled(name.isEmpty || isSubmitting)
                        
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
            .navigationTitle("Нова група меню")
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
    
    private func createMenuGroup() {
        isSubmitting = true
        
        Task {
            await viewModel.createMenuGroup(
                coffeeShopId: coffeeShopId,
                name: name,
                description: description.isEmpty ? nil : description,
                displayOrder: displayOrder
            )
            
            isSubmitting = false
        }
    }
}
