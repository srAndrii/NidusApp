//
//  CustomizationOptionsEditorView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import SwiftUI

struct CustomizationOptionsEditorView: View {
    @ObservedObject var viewModel: MenuItemEditorViewModel
    @State private var showingAddOptionSheet = false
    @State private var showingAddChoiceSheet = false
    @State private var newOption = CustomizationOptionFormModel()
    @State private var newChoice = CustomizationChoiceFormModel()
    @State private var editingOptionIndex: Int? = nil
    @State private var editingChoiceData: (optionIndex: Int, choiceIndex: Int)? = nil
    @State private var selectedOptionIndex: Int? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Заголовок секції
            HStack {
                Text("Опції кастомізації")
                    .font(.headline)
                    .foregroundColor(Color("primaryText"))
                
                Spacer()
                
                Button(action: {
                    newOption = CustomizationOptionFormModel()
                    editingOptionIndex = nil
                    showingAddOptionSheet = true
                }) {
                    Label("Додати групу", systemImage: "plus")
                        .foregroundColor(Color("primary"))
                }
            }
            .padding(.horizontal)
            
            if viewModel.customizationOptions.isEmpty {
                // Повідомлення, коли немає опцій кастомізації
                VStack {
                    Text("Опції кастомізації відсутні")
                        .font(.subheadline)
                        .foregroundColor(Color("secondaryText"))
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .background(Color("cardColor"))
                .cornerRadius(8)
                .padding(.horizontal)
            } else {
                // Список груп опцій кастомізації
                ForEach(Array(viewModel.customizationOptions.enumerated()), id: \.element.id) { optionIndex, option in
                    optionGroupView(for: option, optionIndex: optionIndex)
                }
            }
        }
        .sheet(isPresented: $showingAddOptionSheet) {
            CustomizationOptionFormView(
                option: $newOption,
                onSave: {
                    if let editingIndex = editingOptionIndex {
                        // Оновлення існуючої групи опцій
                        viewModel.updateCustomizationOption(
                            at: editingIndex,
                            name: newOption.name,
                            required: newOption.required
                        )
                    } else {
                        // Додавання нової групи опцій
                        viewModel.addCustomizationOption(
                            name: newOption.name,
                            required: newOption.required
                        )
                    }
                    showingAddOptionSheet = false
                }
            )
        }
        .sheet(isPresented: $showingAddChoiceSheet) {
            CustomizationChoiceFormView(
                choice: $newChoice,
                onSave: {
                    if let selectedIndex = selectedOptionIndex {
                        if let editingData = editingChoiceData, editingData.optionIndex == selectedIndex {
                            // Оновлення існуючого варіанту вибору
                            viewModel.updateChoiceInOption(
                                optionIndex: editingData.optionIndex,
                                choiceIndex: editingData.choiceIndex,
                                name: newChoice.name,
                                price: newChoice.price
                            )
                        } else {
                            // Додавання нового варіанту вибору
                            viewModel.addChoiceToOption(
                                at: selectedIndex,
                                name: newChoice.name,
                                price: newChoice.price
                            )
                        }
                    }
                    showingAddChoiceSheet = false
                }
            )
        }
    }
    
    private func optionGroupView(for option: CustomizationOption, optionIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Заголовок групи опцій
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.name)
                        .font(.headline)
                        .foregroundColor(Color("primaryText"))
                    
                    if option.required {
                        Text("Обов'язковий вибір")
                            .font(.caption)
                            .foregroundColor(Color("primary"))
                    }
                }
                
                Spacer()
                
                // Кнопка додавання варіанту вибору
                Button(action: {
                    selectedOptionIndex = optionIndex
                    newChoice = CustomizationChoiceFormModel()
                    editingChoiceData = nil
                    showingAddChoiceSheet = true
                }) {
                    Label("", systemImage: "plus.circle")
                        .foregroundColor(Color("primary"))
                }
                
                // Кнопка редагування групи
                Button(action: {
                    editingOptionIndex = optionIndex
                    newOption = CustomizationOptionFormModel(from: option)
                    showingAddOptionSheet = true
                }) {
                    Label("", systemImage: "pencil")
                        .foregroundColor(Color("primary"))
                }
                
                // Кнопка видалення групи
                Button(action: {
                    viewModel.removeCustomizationOption(at: optionIndex)
                }) {
                    Label("", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
            
            // Список варіантів вибору
            if option.choices.isEmpty {
                Text("Немає варіантів вибору")
                    .font(.caption)
                    .foregroundColor(Color("secondaryText"))
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(option.choices.enumerated()), id: \.element.id) { choiceIndex, choice in
                    choiceRow(
                        for: choice,
                        optionIndex: optionIndex,
                        choiceIndex: choiceIndex
                    )
                }
            }
        }
        .padding()
        .background(Color("cardColor"))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private func choiceRow(for choice: CustomizationChoice, optionIndex: Int, choiceIndex: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(choice.name)
                    .font(.subheadline)
                    .foregroundColor(Color("primaryText"))
                
                if let price = choice.price, price > 0 {
                    Text("+\(formatPrice(price))")
                        .font(.caption)
                        .foregroundColor(Color("primary"))
                }
            }
            
            Spacer()
            
            // Кнопка редагування варіанту вибору
            Button(action: {
                selectedOptionIndex = optionIndex
                editingChoiceData = (optionIndex, choiceIndex)
                newChoice = CustomizationChoiceFormModel(from: choice)
                showingAddChoiceSheet = true
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(Color("primary"))
            }
            
            // Кнопка видалення варіанту вибору
            Button(action: {
                viewModel.removeChoiceFromOption(
                    optionIndex: optionIndex,
                    choiceIndex: choiceIndex
                )
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "UAH"
        formatter.currencySymbol = "₴"
        return formatter.string(from: price as NSDecimalNumber) ?? "\(price) ₴"
    }
}

// Ці структури залишаються незмінними
struct CustomizationOptionFormModel {
    var name: String = ""
    var required: Bool = false
    
    init(from option: CustomizationOption? = nil) {
        if let option = option {
            name = option.name
            required = option.required
        }
    }
}

struct CustomizationChoiceFormModel {
    var name: String = ""
    var price: Decimal? = nil
    
    init(from choice: CustomizationChoice? = nil) {
        if let choice = choice {
            name = choice.name
            price = choice.price
        }
    }
}

// Форма для додавання/редагування групи опцій
struct CustomizationOptionFormView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var option: CustomizationOptionFormModel
    var onSave: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Інформація про групу опцій")) {
                    TextField("Назва групи (напр. 'Сироп', 'Тип молока')", text: $option.name)
                    Toggle("Обов'язковий вибір", isOn: $option.required)
                }
                
                Button(action: {
                    onSave()
                }) {
                    Text("Зберегти")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(option.name.isEmpty ? Color.gray : Color("primary"))
                        .cornerRadius(8)
                }
                .disabled(option.name.isEmpty)
                .listRowInsets(EdgeInsets())
                .padding()
            }
            .navigationTitle(Text("Група опцій"))
            .navigationBarItems(trailing: Button("Скасувати") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// Форма для додавання/редагування варіанту вибору
struct CustomizationChoiceFormView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var choice: CustomizationChoiceFormModel
    var onSave: () -> Void
    
    @State private var priceString: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Інформація про варіант вибору")) {
                    TextField("Назва варіанту (напр. 'Ванільний', 'Соєве')", text: $choice.name)
                    
                    HStack {
                        Text("Додаткова ціна:")
                        Spacer()
                        TextField("0.00", text: $priceString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: priceString) { oldValue, newValue in
                                if let price = Decimal(string: newValue.replacingOccurrences(of: ",", with: ".")) {
                                    choice.price = price
                                } else if newValue.isEmpty {
                                    choice.price = nil
                                }
                            }
                            .onAppear {
                                if let price = choice.price {
                                    priceString = "\(price)"
                                }
                            }
                    }
                }
                
                Button(action: {
                    onSave()
                }) {
                    Text("Зберегти")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(choice.name.isEmpty ? Color.gray : Color("primary"))
                        .cornerRadius(8)
                }
                .disabled(choice.name.isEmpty)
                .listRowInsets(EdgeInsets())
                .padding()
            }
            .navigationTitle(Text("Варіант вибору"))
            .navigationBarItems(trailing: Button("Скасувати") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
