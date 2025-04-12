//
//  IngredientsEditorView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import SwiftUI

struct IngredientsEditorView: View {
    @ObservedObject var viewModel: MenuItemEditorViewModel
    @State private var showingAddIngredientSheet = false
    @State private var newIngredient = IngredientFormModel()
    @State private var editingIndex: Int? = nil
    @State private var showAlert = false
    
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
                    editingIndex = nil
                    showingAddIngredientSheet = true
                }) {
                    Label("Додати", systemImage: "plus")
                        .foregroundColor(Color("primary"))
                }
            }
            .padding(.horizontal)
            
            if viewModel.ingredients.isEmpty == true {
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
                
               ForEach(Array(viewModel.ingredients.enumerated()), id: \.element.id) { index, ingredient in
                    ingredientRow(for: ingredient, index: index)
                
                }
            }
        }
        .sheet(isPresented: $showingAddIngredientSheet) {
            IngredientFormView(
                ingredient: $newIngredient,
                onSave: {
                    if let editingIndex = editingIndex {
                        // Оновлення існуючого інгредієнта
                        let updatedIngredient = Ingredient(
                            id: viewModel.ingredients[editingIndex].id,
                            name: newIngredient.name,
                            amount: newIngredient.amount,
                            unit: newIngredient.unit,
                            isCustomizable: newIngredient.isCustomizable,
                            minAmount: newIngredient.isCustomizable ? newIngredient.minAmount : nil,
                            maxAmount: newIngredient.isCustomizable ? newIngredient.maxAmount : nil,
                            freeAmount: newIngredient.isCustomizable ? newIngredient.freeAmount : nil,
                            pricePerUnit: newIngredient.isCustomizable ? newIngredient.pricePerUnit : nil
                        )
                        
                        viewModel.updateIngredient(at: editingIndex, with: updatedIngredient)
                    } else {
                        // Додавання нового інгредієнта
                        let newIngredientObj = Ingredient(
                            id: UUID().uuidString, // Завжди генеруємо новий ID
                            name: newIngredient.name,
                            amount: newIngredient.amount,
                            unit: newIngredient.unit,
                            isCustomizable: newIngredient.isCustomizable,
                            minAmount: newIngredient.isCustomizable ? newIngredient.minAmount : nil,
                            maxAmount: newIngredient.isCustomizable ? newIngredient.maxAmount : nil,
                            freeAmount: newIngredient.isCustomizable ? newIngredient.freeAmount : nil,
                            pricePerUnit: newIngredient.isCustomizable ? newIngredient.pricePerUnit : nil
                        )
                        
                        viewModel.addIngredient(newIngredientObj)
                    }
                    showingAddIngredientSheet = false
                },
                ingredients: viewModel.ingredients,
                currentIndex: editingIndex
            )
        }
    }
    
    private func ingredientRow(for ingredient: Ingredient, index: Int) -> some View {
        // Той самий код рядка інгредієнта з оригінального коду, але:
        // - замість модифікації @Binding використовуються методи ViewModel
        // - кнопки дій використовують методи ViewModel: updateIngredient, removeIngredient
        
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
                
                // Якщо інгредієнт можна кастомізувати, показуємо його межі та ціни
                if ingredient.isCustomizable {
                    HStack {
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
                    
                    // Додано: інформація про безкоштовну кількість та ціну
                    HStack {
                        if let freeAmount = ingredient.freeAmount {
                            Text("Безкоштовно: \(String(format: "%.1f", freeAmount)) \(ingredient.unit)")
                                .font(.caption)
                                .foregroundColor(Color("primary"))
                        }
                        
                        Spacer()
                        
                        if let pricePerUnit = ingredient.pricePerUnit, pricePerUnit > 0 {
                            Text("+\(pricePerUnit) ₴/\(ingredient.unit)")
                                .font(.caption)
                                .foregroundColor(Color("primary"))
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
                    viewModel.removeIngredient(at: index)
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

// Оновлена модель форми інгредієнта
struct IngredientFormModel {
    var id: String = UUID().uuidString
    var name: String = ""
    var amount: Double = 1.0
    var unit: String = "шт."
    var isCustomizable: Bool = false
    var minAmount: Double? = nil
    var maxAmount: Double? = nil
    var freeAmount: Double? = nil // Додано: безкоштовна кількість
    var pricePerUnit: Decimal? = nil // Додано: ціна за одиницю
    
    // Ініціалізатор для створення форми з існуючого інгредієнта
    init(from ingredient: Ingredient? = nil) {
        if let ingredient = ingredient {
            id = ingredient.id ?? UUID().uuidString
            name = ingredient.name
            amount = ingredient.amount
            unit = ingredient.unit
            isCustomizable = ingredient.isCustomizable
            minAmount = ingredient.minAmount
            maxAmount = ingredient.maxAmount
            freeAmount = ingredient.freeAmount // Додано
            pricePerUnit = ingredient.pricePerUnit // Додано
        }
    }
}

// Оновлена форма для додавання/редагування інгредієнта
struct IngredientFormView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var ingredient: IngredientFormModel
    var onSave: () -> Void
    var ingredients: [Ingredient]? // Необов'язковий масив інгредієнтів для перевірки
    var currentIndex: Int? // Індекс поточного інгредієнта, якщо редагуємо
    
    @State private var showAlert = false
    
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
                        
                        // Додано: поле для безкоштовної кількості
                        HStack {
                            Text("Безкоштовна кількість:")
                            Spacer()
                            TextField("", value: $ingredient.freeAmount, formatter: NumberFormatter())
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                        
                        // Додано: поле для ціни за одиницю
                        HStack {
                            Text("Ціна за додаткову одиницю:")
                            Spacer()
                            
                            // Поле для введення десяткового числа
                            let binding = Binding<String>(
                                get: {
                                    if let price = ingredient.pricePerUnit {
                                        return "\(NSDecimalNumber(decimal: price))"
                                    }
                                    return ""
                                },
                                set: {
                                    if let value = Decimal(string: $0.replacingOccurrences(of: ",", with: ".")) {
                                        ingredient.pricePerUnit = value
                                    } else {
                                        ingredient.pricePerUnit = nil
                                    }
                                }
                            )
                            
                            TextField("0", text: binding)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            
                            Text("₴")
                                .foregroundColor(Color("secondaryText"))
                        }
                    }
                }
                
                // Додано: секція з інформацією про безкоштовні кількості
                if ingredient.isCustomizable {
                    Section(header: Text("Інформація про ціноутворення")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Безкоштовні кількості:")
                                .font(.subheadline)
                            
                            Text("• Якщо клієнт вибирає кількість не більше безкоштовної, додаткова плата не стягується")
                                .font(.caption)
                                .foregroundColor(Color("secondaryText"))
                            
                            Text("• Якщо клієнт вибирає більшу кількість, оплачується лише різниця")
                                .font(.caption)
                                .foregroundColor(Color("secondaryText"))
                            
                            Text("• Якщо ціна за одиницю не вказана, всі кількості будуть безкоштовними")
                                .font(.caption)
                                .foregroundColor(Color("secondaryText"))
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Button(action: {
                    // Перевірка на дублікат тільки якщо переданий масив інгредієнтів
                    if let ingredients = ingredients {
                        let exists = ingredients.contains(where: { 
                            $0.name.lowercased() == ingredient.name.lowercased() && 
                            (currentIndex == nil || ingredients.firstIndex(where: { $0.id == $0.id }) != currentIndex)
                        })
                        
                        if exists {
                            // Показати попередження, але не блокувати додавання
                            showAlert = true
                        } else {
                            // Якщо немає дублікатів, просто зберігаємо
                            onSave()
                        }
                    } else {
                        // Якщо інгредієнти не передані, просто зберігаємо
                        onSave()
                    }
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
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Увага"),
                        message: Text("Інгредієнт з назвою '\(ingredient.name)' вже існує в цьому пункті меню. Бажаєте додати ще один?"),
                        primaryButton: .cancel(Text("Скасувати")),
                        secondaryButton: .default(Text("Додати все одно"), action: {
                            // При підтвердженні додаємо інгредієнт незважаючи на дублікат
                            onSave()
                        })
                    )
                }
            }
            .navigationTitle(Text("Інгредієнт"))
            .navigationBarItems(trailing: Button("Скасувати") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
