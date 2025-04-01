//
//  CreateCoffeeShopView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/31/25.
//

// Views/Admin/CoffeeShops/CreateCoffeeShopView.swift
import SwiftUI

struct CreateCoffeeShopView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: CoffeeShopViewModel
    
    @State private var name = ""
    @State private var address = ""
    @State private var allowScheduledOrders = false
    @State private var minPreorderTimeMinutes = 15
    @State private var maxPreorderTimeMinutes = 1440 // 24 години
    
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("backgroundColor")
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Форма
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
                        
                        // Кнопка створення
                        Button(action: {
                            createCoffeeShop()
                        }) {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Створити кав'ярню")
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
            .navigationTitle("Нова кав'ярня")
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
    
    private func createCoffeeShop() {
        isSubmitting = true
        
        Task {
            // Спочатку створюємо кав'ярню з базовими даними
            await viewModel.createCoffeeShop(name: name, address: address.isEmpty ? nil : address)
            
            // Якщо є додаткові налаштування, оновлюємо їх
            if let coffeeShopId = viewModel.myCoffeeShops.last?.id {
                let params: [String: Any] = [
                    "allowScheduledOrders": allowScheduledOrders,
                    "minPreorderTimeMinutes": minPreorderTimeMinutes,
                    "maxPreorderTimeMinutes": maxPreorderTimeMinutes
                ]
                
                await viewModel.updateCoffeeShop(id: coffeeShopId, params: params)
            }
            
            isSubmitting = false
        }
    }
}   
