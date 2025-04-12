//
//  MenuItemCustomizationEditor.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import SwiftUI

struct MenuItemCustomizationEditor: View {
    @ObservedObject var viewModel: MenuItemEditorViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Перемикач кастомізації
            Toggle("Дозволити кастомізацію", isOn: $viewModel.isCustomizable)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color("cardColor"))
                .cornerRadius(8)
                .padding(.horizontal)
                .onChange(of: viewModel.isCustomizable) { oldValue, newValue in
                    print("🔄 Зміна стану кастомізації: \(oldValue) -> \(newValue)")
                }
            
            if viewModel.isCustomizable {
                // Вкладки
                Picker("", selection: $viewModel.selectedTab) {
                    Text("Інгредієнти").tag(0)
                    Text("Опції").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Вміст вкладок
                VStack {
                    if viewModel.selectedTab == 0 {
                        IngredientsEditorView(viewModel: viewModel)
                    } else {
                        CustomizationOptionsEditorView(viewModel: viewModel)
                    }
                }
                .animation(.default, value: viewModel.selectedTab)
                .transition(.slide)
            } else {
                // Повідомлення про вимкнену кастомізацію
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 30))
                        .foregroundColor(Color("secondaryText"))
                        .padding(.top, 8)
                    
                    Text("Кастомізація вимкнена")
                        .font(.headline)
                        .foregroundColor(Color("primaryText"))
                    
                    Text("Увімкніть кастомізацію, щоб налаштувати інгредієнти та опції вибору для клієнтів.")
                        .font(.subheadline)
                        .foregroundColor(Color("secondaryText"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity)
                .background(Color("cardColor"))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            // Інформаційний блок
            if viewModel.isCustomizable {
                // Інформація про кастомізацію
                VStack(alignment: .leading, spacing: 8) {
                    Text("Система ціноутворення кастомізацій:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("primaryText"))
                    
                    // Інформація про інгредієнти
                    Text("• Інгредієнти можуть мати безкоштовну кількість та ціну за додаткові одиниці")
                        .font(.caption)
                        .foregroundColor(Color("secondaryText"))
                    
                    Text("• Клієнт оплачує лише ту кількість, яка перевищує безкоштовний ліміт")
                        .font(.caption)
                        .foregroundColor(Color("secondaryText"))
                    
                    // Інформація про опції
                    Text("• Опції кастомізації можуть мати додаткову ціну для певних варіантів")
                        .font(.caption)
                        .foregroundColor(Color("secondaryText"))
                    
                    Text("• Стандартний вибір зазвичай безкоштовний, альтернативні - з доплатою")
                        .font(.caption)
                        .foregroundColor(Color("secondaryText"))
                }
                .padding()
                .background(Color("cardColor").opacity(0.5))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
}
