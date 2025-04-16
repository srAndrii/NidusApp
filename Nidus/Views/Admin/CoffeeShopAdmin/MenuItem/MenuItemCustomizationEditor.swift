//
//  MenuItemCustomizationEditor.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/11/25.
//

import SwiftUI

struct MenuItemCustomizationEditor: View {
    @ObservedObject var viewModel: MenuItemEditorViewModel
    
    var body: some View {
        VStack {
            // Перемикач для увімкнення кастомізації
            HStack {
                Toggle(isOn: $viewModel.isCustomizable) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Дозволити кастомізацію інгредієнтів")
                    }
                    .font(.headline)
                }
                .toggleStyle(SwitchToggleStyle(tint: Color("primary")))
            }
            .padding(.horizontal)
            
            // Вкладки для перемикання між інгредієнтами та опціями
            if viewModel.isCustomizable {
                Picker("", selection: $viewModel.customizationTabIndex) {
                    Text("Інгредієнти").tag(0)
                    Text("Опції").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Вміст вкладок
                if viewModel.customizationTabIndex == 0 {
                    IngredientsEditorView(viewModel: viewModel)
                } else {
                    CustomizationOptionsEditorView(viewModel: viewModel)
                }
            } else {
                // Пояснення, коли кастомізація вимкнена
                VStack(alignment: .center, spacing: 10) {
                    Text("Кастомізація вимкнена")
                        .font(.headline)
                        .foregroundColor(Color("secondaryText"))
                    
                    Text("Увімкніть кастомізацію, щоб додати інгредієнти та опції, які клієнти зможуть налаштовувати.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color("secondaryText"))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color("inputField").opacity(0.5))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            
            Divider()
                .padding(.vertical, 15)
            
            // Розділ для розмірів продукту
            SizesEditorView(viewModel: viewModel)
        }
    }
}
