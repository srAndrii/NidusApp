//
//  SizesEditorView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 5/21/25.
//

import SwiftUI

struct SizesEditorView: View {
    @ObservedObject var viewModel: MenuItemEditorViewModel
    @State private var showingAddSizeSheet = false
    @State private var editingSizeIndex: Int?
    
    // Стан для нового розміру
    @State private var sizeName = ""
    @State private var sizeAbbreviation = ""
    @State private var sizeAdditionalPrice = ""
    @State private var sizeIsDefault = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Заголовок розділу
            HStack {
                Toggle(isOn: $viewModel.hasMultipleSizes) {
                    HStack {
                        Image(systemName: "ruler")
                        Text("Продукт має різні розміри")
                    }
                    .font(.headline)
                    .foregroundColor(Color("primaryText"))
                }
                .toggleStyle(SwitchToggleStyle(tint: Color("primary")))
            }
            .padding(.horizontal)
            
            if viewModel.hasMultipleSizes {
                // Інформація про розміри
                if viewModel.sizes.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "ruler.fill")
                                .font(.largeTitle)
                                .foregroundColor(Color("secondaryText"))
                            Text("Увімкніть різні розміри, щоб додати варіанти розмірів продукту (наприклад, S, M, L).")
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color("secondaryText"))
                        }
                        .padding()
                        Spacer()
                    }
                } else {
                    // Список розмірів
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(Array(viewModel.sizes.enumerated()), id: \.element.id) { index, size in
                                SizeRowView(
                                    size: size,
                                    onEdit: {
                                        editingSizeIndex = index
                                        sizeName = size.name
                                        sizeAbbreviation = size.abbreviation
                                        sizeAdditionalPrice = "\(size.additionalPrice)"
                                        sizeIsDefault = size.isDefault
                                        showingAddSizeSheet = true
                                    },
                                    onDelete: {
                                        viewModel.removeSize(at: index)
                                    }
                                )
                                .padding(.horizontal)
                                .background(index % 2 == 0 ? Color("inputField").opacity(0.5) : Color.clear)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.bottom, 60) // Додатковий простір для плаваючої кнопки
                    }
                    .frame(maxHeight: 300)
                }
                
                // Кнопка додавання розміру
                Button(action: {
                    // Скидаємо форму і відкриваємо вікно додавання
                    editingSizeIndex = nil
                    sizeName = ""
                    sizeAbbreviation = ""
                    sizeAdditionalPrice = "0"
                    sizeIsDefault = viewModel.sizes.isEmpty  // За замовчуванням, якщо це перший розмір
                    showingAddSizeSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Додати розмір")
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .foregroundColor(.white)
                    .background(Color("primary"))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top, 5)
            } else {
                // Пояснення, коли розміри вимкнені
                VStack(alignment: .center, spacing: 10) {
                    Text("Різні розміри вимкнено")
                        .font(.headline)
                        .foregroundColor(Color("secondaryText"))
                    
                    Text("Увімкніть різні розміри, щоб додати варіанти розмірів продукту (наприклад, S, M, L).")
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color("secondaryText"))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color("inputField").opacity(0.5))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingAddSizeSheet) {
            SizeEditSheet(
                isPresented: $showingAddSizeSheet,
                sizeName: $sizeName,
                sizeAbbreviation: $sizeAbbreviation,
                sizeAdditionalPrice: $sizeAdditionalPrice,
                sizeIsDefault: $sizeIsDefault,
                onSave: {
                    saveSizeChanges()
                }
            )
        }
    }
    
    private func saveSizeChanges() {
        guard !sizeName.isEmpty, !sizeAbbreviation.isEmpty else {
            return
        }
        
        guard let additionalPrice = Decimal(string: sizeAdditionalPrice.replacingOccurrences(of: ",", with: ".")) else {
            return
        }
        
        if let index = editingSizeIndex {
            // Оновлення існуючого розміру
            viewModel.updateSize(
                at: index,
                name: sizeName,
                abbreviation: sizeAbbreviation,
                additionalPrice: additionalPrice,
                isDefault: sizeIsDefault
            )
        } else {
            // Додавання нового розміру
            viewModel.addSize(
                name: sizeName,
                abbreviation: sizeAbbreviation,
                additionalPrice: additionalPrice,
                isDefault: sizeIsDefault
            )
        }
    }
}

struct SizeRowView: View {
    let size: Size
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(size.name)
                        .font(.headline)
                        .foregroundColor(Color("primaryText"))
                    
                    Text("(\(size.abbreviation))")
                        .font(.subheadline)
                        .foregroundColor(Color("secondaryText"))
                    
                    if size.isDefault {
                        Text("За замовчуванням")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color("primary"))
                            .cornerRadius(4)
                    }
                }
                
                Text("Додаткова ціна: \(formatPrice(size.additionalPrice)) ₴")
                    .font(.subheadline)
                    .foregroundColor(Color("secondaryText"))
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(Color("primary"))
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatPrice(_ price: Decimal) -> String {
        return NSDecimalNumber(decimal: price).stringValue
    }
}

struct SizeEditSheet: View {
    @Binding var isPresented: Bool
    @Binding var sizeName: String
    @Binding var sizeAbbreviation: String
    @Binding var sizeAdditionalPrice: String
    @Binding var sizeIsDefault: Bool
    
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Інформація про розмір")) {
                    TextField("Назва розміру (напр. 'Великий')", text: $sizeName)
                    TextField("Абревіатура (напр. 'L')", text: $sizeAbbreviation)
                    
                    HStack {
                        Text("Додаткова ціна:")
                        Spacer()
                        TextField("0", text: $sizeAdditionalPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("₴")
                    }
                    
                    Toggle("Розмір за замовчуванням", isOn: $sizeIsDefault)
                        .toggleStyle(SwitchToggleStyle(tint: Color("primary")))
                }
                
                Section(header: Text("Інформація про ціноутворення")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Базова ціна продукту відноситься до розміру за замовчуванням")
                            .font(.caption)
                            .foregroundColor(Color("secondaryText"))
                        
                        Text("• Додаткова ціна додається до базової для інших розмірів")
                            .font(.caption)
                            .foregroundColor(Color("secondaryText"))
                        
                        Text("• Один розмір повинен бути встановлений як розмір за замовчуванням")
                            .font(.caption)
                            .foregroundColor(Color("secondaryText"))
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationBarTitle("Розмір продукту", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Скасувати") {
                    isPresented = false
                },
                trailing: Button("Зберегти") {
                    onSave()
                    isPresented = false
                }
                .disabled(sizeName.isEmpty || sizeAbbreviation.isEmpty)
            )
        }
    }
}

// Preview для розробки
struct SizesEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = MenuItemEditorViewModel(from: MenuItem(
            id: "1",
            name: "Капучино",
            price: 75,
            hasMultipleSizes: true,
            sizes: [
                Size(name: "Маленький", abbreviation: "S", additionalPrice: 0, isDefault: true),
                Size(name: "Середній", abbreviation: "M", additionalPrice: 15, isDefault: false),
                Size(name: "Великий", abbreviation: "L", additionalPrice: 30, isDefault: false)
            ]
        ))
        
        return SizesEditorView(viewModel: viewModel)
            .padding()
            .background(Color("backgroundColor"))
            .previewLayout(.sizeThatFits)
    }
} 