//
//  CustomizationOptionsEditorView.swift
//  Nidus
//
//  Created by Andrii Liakhovych
//

import SwiftUI

struct CustomizationOptionsEditorView: View {
    @Binding var customizationOptions: [CustomizationOption]
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
            
            if customizationOptions.isEmpty {
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
                ForEach(customizationOptions.indices, id: \.self) { optionIndex in
                    optionGroupView(for: customizationOptions[optionIndex], optionIndex: optionIndex)
                }
            }
        }
        .sheet(isPresented: $showingAddOptionSheet) {
            CustomizationOptionFormView(
                option: $newOption,
                onSave: {
                    if let editingIndex = editingOptionIndex {
                        // Оновлення існуючої групи опцій - створюємо нову з оновленими даними
                        let updatedOption = CustomizationOption(
                            id: customizationOptions[editingIndex].id,
                            name: newOption.name,
                            choices: customizationOptions[editingIndex].choices,
                            required: newOption.required
                        )
                        customizationOptions[editingIndex] = updatedOption
                    } else {
                        // Додавання нової групи опцій
                        let newOptionObj = CustomizationOption(
                            id: UUID().uuidString,
                            name: newOption.name,
                            choices: [],
                            required: newOption.required
                        )
                        customizationOptions.append(newOptionObj)
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
                            // Оновлення існуючого варіанту вибору - створюємо новий масив з оновленим вибором
                            var updatedChoices = customizationOptions[selectedIndex].choices
                            updatedChoices[editingData.choiceIndex] = CustomizationChoice(
                                id: updatedChoices[editingData.choiceIndex].id,
                                name: newChoice.name,
                                price: newChoice.price
                            )
                            
                            // Створюємо нову опцію з оновленими варіантами вибору
                            let updatedOption = CustomizationOption(
                                id: customizationOptions[selectedIndex].id,
                                name: customizationOptions[selectedIndex].name,
                                choices: updatedChoices,
                                required: customizationOptions[selectedIndex].required
                            )
                            customizationOptions[selectedIndex] = updatedOption
                        } else {
                            // Додавання нового варіанту вибору
                            let newChoiceObj = CustomizationChoice(
                                id: UUID().uuidString,
                                name: newChoice.name,
                                price: newChoice.price
                            )
                            
                            // Створюємо нову опцію з доданим варіантом вибору
                            var updatedChoices = customizationOptions[selectedIndex].choices
                            updatedChoices.append(newChoiceObj)
                            
                            let updatedOption = CustomizationOption(
                                id: customizationOptions[selectedIndex].id,
                                name: customizationOptions[selectedIndex].name,
                                choices: updatedChoices,
                                required: customizationOptions[selectedIndex].required
                            )
                            customizationOptions[selectedIndex] = updatedOption
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
                    customizationOptions.remove(at: optionIndex)
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
                ForEach(option.choices.indices, id: \.self) { choiceIndex in
                    choiceRow(
                        for: option.choices[choiceIndex],
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
                // Створюємо копію варіантів вибору без вибраного варіанту
                var updatedChoices = customizationOptions[optionIndex].choices
                updatedChoices.remove(at: choiceIndex)
                
                // Створюємо нову опцію з оновленими варіантами вибору
                let updatedOption = CustomizationOption(
                    id: customizationOptions[optionIndex].id,
                    name: customizationOptions[optionIndex].name,
                    choices: updatedChoices,
                    required: customizationOptions[optionIndex].required
                )
                customizationOptions[optionIndex] = updatedOption
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

// Допоміжні моделі для форм

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
                            .onChange(of: priceString) { _, newValue in
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

struct CustomizationOptionsEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleOptions: [CustomizationOption] = [
            CustomizationOption(
                id: "1",
                name: "Сироп",
                choices: [
                    CustomizationChoice(id: "1-1", name: "Ванільний", price: 10),
                    CustomizationChoice(id: "1-2", name: "Карамельний", price: 10)
                ],
                required: false
            ),
            CustomizationOption(
                id: "2",
                name: "Тип молока",
                choices: [
                    CustomizationChoice(id: "2-1", name: "Звичайне", price: nil),
                    CustomizationChoice(id: "2-2", name: "Соєве", price: 15)
                ],
                required: true
            )
        ]
        
        CustomizationOptionsEditorView(customizationOptions: .constant(sampleOptions))
            .padding()
            .previewLayout(.sizeThatFits)
            .background(Color("backgroundColor"))
            .preferredColorScheme(.dark)
    }
}
