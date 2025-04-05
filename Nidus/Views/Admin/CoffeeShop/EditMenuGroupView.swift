//
//  EditMenuGroupView.swift
//  Nidus
//
//  Created by Andrii Liakhovych
//

import SwiftUI

struct EditMenuGroupView: View {
    @Environment(\.presentationMode) var presentationMode
    let coffeeShopId: String
    let menuGroup: MenuGroup
    @ObservedObject var viewModel: MenuGroupsViewModel
    
    @State private var name: String
    @State private var description: String
    @State private var displayOrder: Int
    @State private var isSubmitting = false
    
    init(coffeeShopId: String, menuGroup: MenuGroup, viewModel: MenuGroupsViewModel) {
        self.coffeeShopId = coffeeShopId
        self.menuGroup = menuGroup
        self.viewModel = viewModel
        
        // Ініціалізуємо стан з поточними значеннями
        _name = State(initialValue: menuGroup.name)
        _description = State(initialValue: menuGroup.description ?? "")
        _displayOrder = State(initialValue: menuGroup.displayOrder)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("backgroundColor")
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Редагування групи меню")
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
                        
                        // Кнопка збереження
                        Button(action: updateMenuGroup) {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Зберегти зміни")
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
            .navigationTitle("Редагування групи меню")
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
    
    private func updateMenuGroup() {
        isSubmitting = true
        
        Task {
            await viewModel.updateMenuGroup(
                coffeeShopId: coffeeShopId,
                groupId: menuGroup.id,
                name: name,
                description: description.isEmpty ? nil : description,
                displayOrder: displayOrder
            )
            
            isSubmitting = false
        }
    }
}
