//
//  EditCoffeeShopView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/31/25.
//


import SwiftUI

struct EditCoffeeShopView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: CoffeeShopViewModel
    let coffeeShop: CoffeeShop
    
    @State private var name: String
    @State private var address: String
    @State private var allowScheduledOrders: Bool
    @State private var minPreorderTimeMinutes: Int
    @State private var maxPreorderTimeMinutes: Int
    
    @State private var isSubmitting = false
    
    init(viewModel: CoffeeShopViewModel, coffeeShop: CoffeeShop) {
        self.viewModel = viewModel
        self.coffeeShop = coffeeShop
        
        // Ініціалізуємо значення форми з існуючої кав'ярні
        _name = State(initialValue: coffeeShop.name)
        _address = State(initialValue: coffeeShop.address ?? "")
        _allowScheduledOrders = State(initialValue: coffeeShop.allowScheduledOrders)
        _minPreorderTimeMinutes = State(initialValue: coffeeShop.minPreorderTimeMinutes)
        _maxPreorderTimeMinutes = State(initialValue: coffeeShop.maxPreorderTimeMinutes)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("backgroundColor")
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Базова інформація про кав'ярню
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Інформація про кав'ярню")
                                .font(.headline)
                                .foregroundColor(Color("primaryText"))
                                .padding(.horizontal)
                            
                            CustomTextField(
                                iconName: "building.2",
                                placeholder: "Назва кав'ярні",
                                text: $name
                            )
                            .padding(.horizontal)
                            
                            CustomTextField(
                                iconName: "location",
                                placeholder: "Адреса",
                                text: $address
                            )
                            .padding(.horizontal)
                            
                            // Налаштування попередніх замовлень
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $allowScheduledOrders) {
                                    Text("Приймати попередні замовлення")
                                        .font(.subheadline)
                                        .foregroundColor(Color("primaryText"))
                                }
                                .toggleStyle(SwitchToggleStyle(tint: Color("primary")))
                                
                                if allowScheduledOrders {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Мінімальний час для замовлення наперед:")
                                            .font(.caption)
                                            .foregroundColor(Color("secondaryText"))
                                        
                                        Picker("", selection: $minPreorderTimeMinutes) {
                                            Text("15 хвилин").tag(15)
                                            Text("30 хвилин").tag(30)
                                            Text("1 година").tag(60)
                                            Text("2 години").tag(120)
                                        }
                                        .pickerStyle(SegmentedPickerStyle())
                                        .background(Color("inputField"))
                                        .cornerRadius(8)
                                        
                                        Text("Максимальний час для замовлення наперед:")
                                            .font(.caption)
                                            .foregroundColor(Color("secondaryText"))
                                            .padding(.top, 8)
                                        
                                        Picker("", selection: $maxPreorderTimeMinutes) {
                                            Text("6 годин").tag(360)
                                            Text("12 годин").tag(720)
                                            Text("24 години").tag(1440)
                                            Text("48 годин").tag(2880)
                                        }
                                        .pickerStyle(SegmentedPickerStyle())
                                        .background(Color("inputField"))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                        .padding(.vertical)
                        .background(Color("cardColor"))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Інформація про власника (якщо це Super Admin)
                        if viewModel.isSuperAdmin() {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Власник")
                                    .font(.headline)
                                    .foregroundColor(Color("primaryText"))
                                
                                if let ownerId = coffeeShop.ownerId {
                                    HStack {
                                        Image(systemName: "person.fill")
                                            .foregroundColor(Color("primary"))
                                        
                                        Text("ID: \(ownerId)")
                                            .font(.body)
                                            .foregroundColor(Color("primaryText"))
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            // Перехід до екрану для зміни власника
                                            presentationMode.wrappedValue.dismiss()
                                        }) {
                                            Text("Змінити")
                                                .font(.footnote)
                                                .foregroundColor(Color("primary"))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color("primary").opacity(0.1))
                                                .cornerRadius(8)
                                        }
                                    }
                                    .padding()
                                    .background(Color("cardColor"))
                                    .cornerRadius(8)
                                } else {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(Color.orange)
                                        
                                        Text("Власник не призначений")
                                            .font(.body)
                                            .foregroundColor(Color("primaryText"))
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            // Перехід до екрану для призначення власника
                                            presentationMode.wrappedValue.dismiss()
                                        }) {
                                            Text("Призначити")
                                                .font(.footnote)
                                                .foregroundColor(Color("primary"))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color("primary").opacity(0.1))
                                                .cornerRadius(8)
                                        }
                                    }
                                    .padding()
                                    .background(Color("cardColor"))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Кнопка збереження
                        Button(action: {
                            updateCoffeeShop()
                        }) {
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
            .navigationTitle("Редагування кав'ярні")
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
    
    private func updateCoffeeShop() {
        isSubmitting = true
        
        Task {
            let params: [String: Any] = [
                "name": name,
                "address": address.isEmpty ? NSNull() : address,
                "allowScheduledOrders": allowScheduledOrders,
                "minPreorderTimeMinutes": minPreorderTimeMinutes,
                "maxPreorderTimeMinutes": maxPreorderTimeMinutes
            ]
            
            await viewModel.updateCoffeeShop(id: coffeeShop.id, params: params)
            
            isSubmitting = false
        }
    }
}
