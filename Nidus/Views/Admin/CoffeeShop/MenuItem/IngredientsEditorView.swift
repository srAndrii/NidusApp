//
//  IngredientsEditorView.swift
//  Nidus
//
//  Created by Andrii Liakhovych
//

import SwiftUI

struct IngredientsEditorView: View {
    @Binding var ingredients: [Ingredient]
    @State private var showingAddIngredientSheet = false
    @State private var newIngredient = IngredientFormModel()
    @State private var editingIndex: Int? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Заголовок секції
            HStack {
                Text("Інгредієнти")
                    .font(.headline)
                    .foregroundColor(Color("primaryText"))
                
                Spacer()
                
                Button(action: {
                    newIngredient = IngredientFormModel()
                    showingAddIngredientSheet = true
                }) {
                    Label("Додати", systemImage: "plus")
                        .foregroundColor(Color("primary"))
                }
            }
            .padding(.horizontal)
            
            if ingredients.isEmpty {
                // Повідомлення, коли немає інгредієнтів
                VStack {
                    Text("Інгредієнти відсутні")
                        .font(.subheadline)
                        .foregroundColor(Color("secondaryText"))
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .background(Color("cardColor"))
                .cornerRadius(8)
                .padding(.horizontal)
            } else {
                // Список інгредієнтів
                ForEach(ingredients.indices, id: \.self) { index in
                    ingredientRow(for: ingredients[index], index: index)
                }
            }
        }
        .sheet(isPresented: $showingAddIngredientSheet) {
            IngredientFormView(
                ingredient: $newIngredient,
                onSave: {
                    if let editingIndex = editingIndex {
                        // Оновлення існуючого інгредієнта
                        ingredients[editingIndex] = Ingredient(
                            name: newIngredient.name,
                            amount: newIngredient.amount,
                            unit: newIngredient.unit,
                            isCustomizable: newIngredient.isCustomizable,
                            minAmount: newIngredient.isCustomizable ? newIngredient.minAmount : nil,
                            maxAmount: newIngredient.isCustomizable ? newIngredient.maxAmount : nil
                        )
                        self.editingIndex = nil
                    } else {
                        // Додавання нового інгредієнта
                        ingredients.append(Ingredient(
                            name: newIngredient.name,
                            amount: newIngredient.amount,
                            unit: newIngredient.unit,
                            isCustomizable: newIngredient.isCustomizable,
                            minAmount: newIngredient.isCustomizable ? newIngredient.minAmount : nil,
                            maxAmount: newIngredient.isCustomizable ? newIngredient.maxAmount : nil
                        ))
                    }
                    showingAddIngredientSheet = false
                }
            )
        }
    }
    
    private func ingredientRow(for ingredient: Ingredient, index: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(.headline)
                    .foregroundColor(Color("primaryText"))
                
                HStack {
                    Text("\(String(format: "%.1f", ingredient.amount)) \(ingredient.unit)")
                        .font(.subheadline)
                        .foregroundColor(Color("secondaryText"))
                    
                    Spacer()
                    
                    // Показуємо, чи можна кастомізувати
                    if ingredient.isCustomizable {
                        Label("Кастомізується", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color("primary"))
                    } else {
                        Label("Фіксований", systemImage: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color("secondaryText"))
                    }
                }
                
                // Якщо інгредієнт можна кастомізувати, показуємо його межі
                if ingredient.isCustomizable {
                    HStack {
                        Text("Межі: ")
                            .font(.caption)
                            .foregroundColor(Color("secondaryText"))
                        
                        if let minAmount = ingredient.minAmount {
                            Text("мін. \(String(format: "%.1f", minAmount))")
                                .font(.caption)
                                .foregroundColor(Color("secondaryText"))
                        }
                        
                        if ingredient.minAmount != nil && ingredient.maxAmount != nil {
                            Text("-")
                                .font(.caption)
                                .foregroundColor(Color("secondaryText"))
                        }
                        
                        if let maxAmount = ingredient.maxAmount {
                            Text("макс. \(String(format: "%.1f", maxAmount))")
                                .font(.caption)
                                .foregroundColor(Color("secondaryText"))
                        }
                    }
                }
            }
            
            Spacer()
            
            // Кнопки дій
            HStack(spacing: 16) {
                Button(action: {
                    editingIndex = index
                    newIngredient = IngredientFormModel(from: ingredient)
                    showingAddIngredientSheet = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(Color("primary"))
                }
                
                Button(action: {
                    ingredients.remove(at: index)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color("cardColor"))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// Допоміжна модель для форми інгредієнта
struct IngredientFormModel {
    var name: String = ""
    var amount: Double = 1.0
    var unit: String = "шт."
    var isCustomizable: Bool = false
    var minAmount: Double? = nil
    var maxAmount: Double? = nil
    
    // Ініціалізатор для створення форми з існуючого інгредієнта
    init(from ingredient: Ingredient? = nil) {
        if let ingredient = ingredient {
            name = ingredient.name
            amount = ingredient.amount
            unit = ingredient.unit
            isCustomizable = ingredient.isCustomizable
            minAmount = ingredient.minAmount
            maxAmount = ingredient.maxAmount
        }
    }
}

// Форма для додавання/редагування інгредієнта
struct IngredientFormView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var ingredient: IngredientFormModel
    var onSave: () -> Void
    
    // Доступні одиниці виміру
    let availableUnits = ["г", "мл", "шт.", "порція"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Основна інформація")) {
                    TextField("Назва інгредієнта", text: $ingredient.name)
                    
                    HStack {
                        Text("Кількість:")
                        Spacer()
                        TextField("", value: $ingredient.amount, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    Picker("Одиниця виміру", selection: $ingredient.unit) {
                        ForEach(availableUnits, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Кастомізація")) {
                    Toggle("Можна кастомізувати", isOn: $ingredient.isCustomizable)
                    
                    if ingredient.isCustomizable {
                        HStack {
                            Text("Мінімальна кількість:")
                            Spacer()
                            TextField("", value: $ingredient.minAmount, formatter: NumberFormatter())
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                        
                        HStack {
                            Text("Максимальна кількість:")
                            Spacer()
                            TextField("", value: $ingredient.maxAmount, formatter: NumberFormatter())
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
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
                        .background(ingredient.name.isEmpty ? Color.gray : Color("primary"))
                        .cornerRadius(8)
                }
                .disabled(ingredient.name.isEmpty)
                .listRowInsets(EdgeInsets())
                .padding()
            }
            .navigationTitle(Text("Інгредієнт"))
            .navigationBarItems(trailing: Button("Скасувати") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct IngredientsEditorView_Previews: PreviewProvider {
    static var previews: some View {
        IngredientsEditorView(ingredients: .constant([
            Ingredient(name: "Espresso", amount: 1.0, unit: "шт.", isCustomizable: true, minAmount: 1, maxAmount: 3),
            Ingredient(name: "Молоко", amount: 150.0, unit: "мл", isCustomizable: false, minAmount: nil, maxAmount: nil)
        ]))
        .padding()
        .previewLayout(.sizeThatFits)
        .background(Color("backgroundColor"))
        .preferredColorScheme(.dark)
    }
}
