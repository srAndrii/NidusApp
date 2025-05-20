//
//  MenuItemDetailView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/8/25.
//

import SwiftUI
import Kingfisher

struct MenuItemDetailView: View {
    // MARK: - Властивості
    let menuItem: MenuItem
    let coffeeShopId: String // Додаємо ID кав'ярні як параметр
    @StateObject private var viewModel: MenuItemDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Стани екрану
    @State private var selectedSize: String = "" // Порожній рядок для автоматичного вибору розміру за замовчуванням
    @State private var quantity: Int = 1
    @State private var showToast = false
    @State private var toastMessage = ""
    
    // MARK: - Конструктор
    init(menuItem: MenuItem, coffeeShopId: String) {
        self.menuItem = menuItem
        self.coffeeShopId = coffeeShopId
        self._viewModel = StateObject(wrappedValue: MenuItemDetailViewModel(menuItem: menuItem, coffeeShopId: coffeeShopId))
    }
    
    // MARK: - View
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Фон
            Group {
                if colorScheme == .light {
                    ZStack {
                        // Основний горизонтальний градієнт
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("nidusCoolGray").opacity(0.9),
                                Color("nidusLightBlueGray").opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        
                        // Додатковий вертикальний градієнт для текстури
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("nidusCoolGray").opacity(0.15),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        // Тонкий шар кольору для затінення в кутах
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color("nidusCoolGray").opacity(0.2)
                            ]),
                            center: .bottomTrailing,
                            startRadius: UIScreen.main.bounds.width * 0.2,
                            endRadius: UIScreen.main.bounds.width
                        )
                    }
                } else {
                    // Для темного режиму використовуємо існуючий колір
                    Color("backgroundColor")
                }
            }
            .ignoresSafeArea()
            
            // Логотип як фон
            Image("Logo")
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
                .frame(width: UIScreen.main.bounds.width * 0.7)
                .saturation(1.5)
                .opacity(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Головний контент
            ScrollView {
                VStack(spacing: 0) {
                    // Зображення товару зі стрейчаблом
                    imageWithOverlay
                    
                    // Основна інформація
                    VStack(spacing: 24) {
                        // Секція з описом
                        descriptionSection
                        
                        // Секція з вибором розміру (якщо підтримується)
                        sizeSelectionSection
                        
                        // Секція кастомізації (якщо підтримується)
                        if viewModel.hasCustomizationOptions {
                            customizationSection
                        }
                        
                        // Секція кількості та кнопки "Додати до кошика"
                        orderSection
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 16)
                }
            }
            
            // Кнопка "Назад"
            BackButtonView()
                .padding(.top, 50)

                .padding(.leading, 12)
            
            // Toast повідомлення
            if showToast {
                Toast(message: toastMessage, isShowing: $showToast)
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .top)
    }
    
    // MARK: - Компоненти інтерфейсу
    
    /// Зображення з напівпрозорим накладенням
    private var imageWithOverlay: some View {
        ZStack(alignment: .bottom) {
            // Зображення
            GeometryReader { geometry in
                if let imageUrl = menuItem.imageUrl, let url = URL(string: imageUrl) {
                    KFImage(url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: 320)
                        .clipped()
                } else {
                    // Заглушка, якщо зображення відсутнє
                    ZStack {
                        Rectangle()
                            .fill(Color("cardColor"))
                            .frame(width: geometry.size.width, height: 320)
                        
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Color("primary"))
                    }
                }
            }
            .frame(height: 320)
            
            // Напівпрозоре накладення із заокругленими кутами
            VStack(alignment: .leading, spacing: 8) {
                // Верхня частина: Назва продукту і статус
                HStack(alignment: .top) {
                    // Назва продукту
                    Text(menuItem.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                    
                    Spacer()
                    
                    // Іконка статусу доступності
                    if !menuItem.isAvailable {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                    
                }
                
                // Ціна
                Text("₴\(formatPrice(menuItem.price))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color("primary"))
                    .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                // Напівпрозорий фон із заокругленими верхніми кутами
                CustomCornerShape(radius: 20, corners: [.topLeft, .topRight])
                    .fill(Color.black.opacity(0.5))
            )
        }
    }
    
    /// Секція з описом товару
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Опис")
                .font(.headline)
                .foregroundColor(Color("primaryText"))
            
            if let description = menuItem.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(Color("secondaryText"))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Опис відсутній")
                    .font(.body)
                    .foregroundColor(Color("secondaryText"))
                    .italic()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            ZStack {
                // Скляний фон
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.clear)
                    .overlay(
                        BlurView(
                            style: colorScheme == .light ? .systemThinMaterial : .systemMaterialDark,
                            opacity: colorScheme == .light ? 0.95 : 0.95
                        )
                    )
                    .overlay(
                        Group {
                            if colorScheme == .light {
                                // Тонування для світлої теми
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color("nidusMistyBlue").opacity(0.25),
                                        Color("nidusCoolGray").opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .opacity(0.4)
                                
                                Color("nidusLightBlueGray").opacity(0.12)
                            } else {
                                // Темна тема
                                Color.black.opacity(0.15)
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            colorScheme == .light 
                                ? Color("nidusCoolGray").opacity(0.4)
                                : Color.black.opacity(0.35),
                            colorScheme == .light
                                ? Color("nidusLightBlueGray").opacity(0.25)
                                : Color.black.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
    }
    
    /// Секція з вибором розміру
    private var sizeSelectionSection: some View {
        Group {
            if !viewModel.availableSizes.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Розмір")
                        .font(.headline)
                        .foregroundColor(Color("primaryText"))
                    
                    // Селектор розміру (без заголовка)
                    SizeSelectorView(
                        selectedSize: $selectedSize,
                        sizes: viewModel.availableSizes,
                        onSizeChanged: { size in
                            viewModel.updatePrice(for: size)
                        },
                        showTitle: false
                    )
                    .padding(.top, 0)
                    .frame(maxWidth: .infinity) // Для центрування елементів
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8) // Зменшений вертикальний padding
                .background(
                    ZStack {
                        // Скляний фон
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.clear)
                            .overlay(
                                BlurView(
                                    style: colorScheme == .light ? .systemThinMaterial : .systemMaterialDark,
                                    opacity: colorScheme == .light ? 0.95 : 0.95
                                )
                            )
                            .overlay(
                                Group {
                                    if colorScheme == .light {
                                        // Тонування для світлої теми
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color("nidusMistyBlue").opacity(0.25),
                                                Color("nidusCoolGray").opacity(0.1)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        .opacity(0.4)
                                        
                                        Color("nidusLightBlueGray").opacity(0.12)
                                    } else {
                                        // Темна тема
                                        Color.black.opacity(0.15)
                                    }
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    colorScheme == .light 
                                        ? Color("nidusCoolGray").opacity(0.4)
                                        : Color.black.opacity(0.35),
                                    colorScheme == .light
                                        ? Color("nidusLightBlueGray").opacity(0.25)
                                        : Color.black.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
            }
        }
    }
    
    /// Секція кастомізації
    private var customizationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Інгредієнти для кастомізації
            if let ingredients = menuItem.ingredients, !ingredients.isEmpty {
                ingredientsCustomizationView
            }
            
            // Опції кастомізації
            if let options = menuItem.customizationOptions, !options.isEmpty {
                customizationOptionsView
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // Інгредієнти для кастомізації
    private var ingredientsCustomizationView: some View {
        VStack(alignment: .leading, spacing: 12) {
           
            
            ForEach(menuItem.ingredients?.filter { $0.isCustomizable } ?? [], id: \.id) { ingredient in
                IngredientCustomizationView(
                    ingredient: ingredient,
                    value: Binding(
                        get: { viewModel.ingredientCustomizations[ingredient.id ?? ingredient.name] ?? ingredient.amount },
                        set: { newValue in
                            viewModel.ingredientCustomizations[ingredient.id ?? ingredient.name] = newValue
                            viewModel.updateCustomization()
                        }
                    )
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // Опції кастомізації
    private var customizationOptionsView: some View {
        VStack(alignment: .leading, spacing: 12) {

            
            ForEach(menuItem.customizationOptions ?? [], id: \.id) { option in
                CustomizationOptionView(option: option, viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// Секція з кількістю та кнопкою замовлення
    private var orderSection: some View {
        VStack(spacing: 16) {
            // Вибір кількості
            VStack(spacing: 4) {
                Text("Кількість")
                    .font(.subheadline)
                    .foregroundColor(Color("primaryText"))
                    .frame(maxWidth: .infinity, alignment: .center)
                
                HStack {
                    Spacer()
                    
                    // Новий компактний селектор кількості з центрованим розташуванням
                    HStack(spacing: 12) {
                        // Зменшити кількість
                        Button(action: {
                            if quantity > 1 {
                                quantity -= 1
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color("primary"))
                                    .frame(width: 32, height: 32)
                                    .shadow(color: Color("primary").opacity(0.2), radius: 3, x: 0, y: 1)
                                
                                Image(systemName: "minus")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(quantity <= 1)
                        .opacity(quantity > 1 ? 1.0 : 0.5)
                        
                        // Поточна кількість
                        Text("\(quantity)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color("primaryText"))
                            .frame(minWidth: 40)
                            .multilineTextAlignment(.center)
                        
                        // Збільшити кількість
                        Button(action: {
                            quantity += 1
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color("primary"))
                                    .frame(width: 32, height: 32)
                                    .shadow(color: Color("primary").opacity(0.2), radius: 3, x: 0, y: 1)
                                
                                Image(systemName: "plus")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(
                        ZStack {
                            // Скляний фон
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.clear)
                                .overlay(
                                    BlurView(
                                        style: colorScheme == .light ? .systemThinMaterial : .systemMaterialDark,
                                        opacity: colorScheme == .light ? 0.95 : 0.95
                                    )
                                )
                                .overlay(
                                    Group {
                                        if colorScheme == .light {
                                            // Тонування для світлої теми
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color("nidusMistyBlue").opacity(0.25),
                                                    Color("nidusCoolGray").opacity(0.1)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            .opacity(0.4)
                                            
                                            Color("nidusLightBlueGray").opacity(0.12)
                                        } else {
                                            // Темна тема
                                            Color.black.opacity(0.15)
                                        }
                                    }
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    )
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        colorScheme == .light 
                                            ? Color("nidusCoolGray").opacity(0.4)
                                            : Color.black.opacity(0.35),
                                        colorScheme == .light
                                            ? Color("nidusLightBlueGray").opacity(0.25)
                                            : Color.black.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                    
                    Spacer()
                }
            }
            
            // Кнопка "Додати до кошика"
            Button(action: {
                // Діагностичне повідомлення
                print("👆 MenuItemDetailView: Натиснуто кнопку 'Додати до кошика'")
                print("   - Товар: \(menuItem.name)")
                print("   - Кількість: \(quantity)")
                print("   - Вибраний розмір: \(selectedSize)")
                
                // Тут буде логіка додавання до кошика
                viewModel.addToCart(quantity: quantity)
                toastMessage = "Додано до кошика: \(menuItem.name) x\(quantity)"
                showToast = true
                
                // Діагностичне повідомлення після виклику методу
                print("✅ MenuItemDetailView: Виклик методу addToCart завершено")
            }) {
                HStack {
                    Text("Додати до кошика")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("₴\(formatPrice(viewModel.currentPrice * Decimal(quantity)))")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    // Градієнт для кнопки
                    LinearGradient(
                        gradient: Gradient(colors: [Color("primary").opacity(0.8), Color("primary")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(!menuItem.isAvailable)
            .opacity(menuItem.isAvailable ? 1.0 : 0.5)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Допоміжні методи
    
    /// Форматування ціни
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        
        return formatter.string(from: NSDecimalNumber(decimal: price)) ?? "\(price)"
    }
}

// MARK: - Preview
struct MenuItemDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Приклад з базовими даними
        MenuItemDetailView(menuItem: MockData.mockCappuccino, coffeeShopId: "shop-1")
            .previewDisplayName("Basic Item")
        
        // Приклад з кастомізацією
        let customizedItem = MenuItem(
            id: "custom-1",
            name: "Кастомізована кава",
            price: 85.0,
            description: "Кава з можливістю налаштування інгредієнтів та додаткових опцій",
            imageUrl: nil,
            isAvailable: true,
            menuGroupId: "group-1",
            ingredients: [],
            customizationOptions: [
                CustomizationOption(
                    id: "milk-type",
                    name: "Тип молока",
                    choices: [
                        CustomizationChoice(id: "no-milk", name: "Без молока", price: nil),
                        CustomizationChoice(id: "regular", name: "Звичайне", price: nil),
                        CustomizationChoice(id: "oat", name: "Вівсяне", price: Decimal(15)),
                        CustomizationChoice(id: "almond", name: "Мигдальне", price: Decimal(20))
                    ],
                    required: true
                ),
                CustomizationOption(
                    id: "syrup",
                    name: "Сироп",
                    choices: [
                        CustomizationChoice(id: "no-syrup", name: "Без сиропу", price: nil),
                        CustomizationChoice(id: "vanilla", name: "Ванільний", price: Decimal(10)),
                        CustomizationChoice(id: "caramel", name: "Карамельний", price: Decimal(10))
                    ],
                    required: false
                )
            ],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        MenuItemDetailView(menuItem: customizedItem, coffeeShopId: "shop-1")
            .previewDisplayName("With Customization")
    }
}
