import SwiftUI

struct CreateMenuItemView: View {
    @Environment(\.presentationMode) var presentationMode
    let menuGroup: MenuGroup
    @ObservedObject var viewModel: MenuItemsViewModel
    
    // Стан форми з використанням розширеної моделі
    @State private var menuItemForm = MenuItemFormModel()
    @StateObject private var editorViewModel = MenuItemEditorViewModel(from: MenuItem(
        id: UUID().uuidString,
        name: "",
        price: 0,
        isAvailable: true,
        createdAt: Date(),
        updatedAt: Date()
    ))
    @State private var selectedImage: UIImage?
    @State private var isSubmitting = false
    
    // Стан для вибору секції
    @State private var selectedTab = 0
    
    // Стан для роботи з зображеннями
    @State private var showImagePicker = false
    @State private var showImagePickerDialog = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        NavigationView {
            mainContentView
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(
                selectedImage: $selectedImage,
                isPresented: $showImagePicker,
                sourceType: sourceType
            )
        }
        .overlay(
            Group {
                if showImagePickerDialog {
                    ImagePickerDialog(
                        isPresented: $showImagePickerDialog,
                        showImagePicker: $showImagePicker,
                        sourceType: $sourceType
                    )
                }
            }
        )
    }
    
    // MARK: - Основний контент
    
    private var mainContentView: some View {
        ZStack {
            Color("backgroundColor")
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Вкладки для перемикання між розділами
                    tabSelectorView
                    
                    // Вміст вкладок
                    selectedTabContent
                    
                    // Кнопка створення
                    createButtonView
                    
                    // Помилка
                    errorView
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Новий пункт меню")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("Скасувати") {
            presentationMode.wrappedValue.dismiss()
        })
        .onChange(of: viewModel.showSuccess) { oldValue, newValue in
            if newValue {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    // MARK: - Компоненти інтерфейсу
    
    private var tabSelectorView: some View {
        Picker("", selection: $selectedTab) {
            Text("Основне").tag(0)
            Text("Кастомізація").tag(1)
            Text("Зображення").tag(2)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var selectedTabContent: some View {
        if selectedTab == 0 {
            basicInfoSection
        } else if selectedTab == 1 {
            customizationSection
        } else {
            imageSection
        }
    }
    
    private var basicInfoSection: some View {
        VStack(spacing: 16) {
            CustomTextField(
                iconName: "cup.and.saucer",
                placeholder: "Назва",
                text: $menuItemForm.name
            )
            .padding(.horizontal)
            
            CustomTextField(
                iconName: "hryvniasign.circle",
                placeholder: "Ціна (₴)",
                text: $menuItemForm.price,
                keyboardType: .decimalPad
            )
            .padding(.horizontal)
            
            CustomTextField(
                iconName: "text.alignleft",
                placeholder: "Опис (необов'язково)",
                text: $menuItemForm.description
            )
            .padding(.horizontal)
            
            // Перемикач доступності
            HStack {
                Text("Доступний для замовлення:")
                    .foregroundColor(Color("primaryText"))
                
                Spacer()
                
                Toggle("", isOn: $menuItemForm.isAvailable)
                    .labelsHidden()
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color("cardColor"))
        .cornerRadius(12)
        .padding(.horizontal)
        .onAppear {
            // Синхронізуємо значення з editorViewModel
            editorViewModel.name = menuItemForm.name
            editorViewModel.price = menuItemForm.price
            editorViewModel.description = menuItemForm.description
            editorViewModel.isAvailable = menuItemForm.isAvailable
        }
        .onChange(of: menuItemForm.name) { oldValue, newValue in
            editorViewModel.name = newValue
        }
        .onChange(of: menuItemForm.price) { oldValue, newValue in
            editorViewModel.price = newValue
        }
        .onChange(of: menuItemForm.description) { oldValue, newValue in
            editorViewModel.description = newValue
        }
        .onChange(of: menuItemForm.isAvailable) { oldValue, newValue in
            editorViewModel.isAvailable = newValue
        }
    }
    
    private var customizationSection: some View {
        // Використовуємо нову структуру MenuItemCustomizationEditor,
        // яка тепер приймає viewModel замість окремих властивостей
        MenuItemCustomizationEditor(viewModel: editorViewModel)
            .onAppear {
                // Синхронізуємо isCustomizable між формою та viewModel
                editorViewModel.isCustomizable = menuItemForm.isCustomizable
                editorViewModel.ingredients = menuItemForm.ingredients
                editorViewModel.customizationOptions = menuItemForm.customizationOptions
            }
            .onChange(of: editorViewModel.isCustomizable) { oldValue, newValue in
                menuItemForm.isCustomizable = newValue
            }
            .onChange(of: editorViewModel.ingredients) { oldValue, newValue in
                menuItemForm.ingredients = newValue
            }
            .onChange(of: editorViewModel.customizationOptions) { oldValue, newValue in
                menuItemForm.customizationOptions = newValue
            }
    }
    
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Зображення пункту меню")
                .font(.headline)
                .foregroundColor(Color("primaryText"))
                .padding(.horizontal)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("inputField"))
                    .frame(height: 200)
                
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                } else {
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(Color("secondaryText"))
                        Text("Виберіть зображення")
                            .foregroundColor(Color("secondaryText"))
                    }
                }
            }
            .padding(.horizontal)
            
            Button(action: { showImagePickerDialog = true }) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Вибрати зображення")
                }
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color("primary"))
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color("cardColor"))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var createButtonView: some View {
        Button(action: createMenuItem) {
            if isSubmitting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text("Створити пункт меню")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(menuItemForm.name.isEmpty || menuItemForm.price.isEmpty ? Color.gray : Color("primary"))
        .foregroundColor(.white)
        .cornerRadius(12)
        .padding(.horizontal)
        .disabled(menuItemForm.name.isEmpty || menuItemForm.price.isEmpty || isSubmitting)
    }
    
    @ViewBuilder
    private var errorView: some View {
        if let error = viewModel.error {
            Text(error)
                .foregroundColor(.red)
                .padding()
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Логіка створення пункту меню
    
    private func createMenuItem() {
        guard let priceDecimal = Decimal(string: menuItemForm.price.replacingOccurrences(of: ",", with: ".")) else {
            viewModel.error = "Вкажіть коректну ціну"
            return
        }
        
        isSubmitting = true
        
        Task {
            do {
                // Підготовка даних меню-айтема
                var updatedMenuItemForm = menuItemForm
                
                // Оновлюємо значення з editorViewModel
                updatedMenuItemForm.isCustomizable = editorViewModel.isCustomizable
                updatedMenuItemForm.ingredients = editorViewModel.ingredients
                updatedMenuItemForm.customizationOptions = editorViewModel.customizationOptions
                
                // Якщо кастомізація вимкнена, очищаємо відповідні поля
                if !updatedMenuItemForm.isCustomizable {
                    updatedMenuItemForm.ingredients = []
                    updatedMenuItemForm.customizationOptions = []
                }
                
                // Створення пункту меню з повними даними про кастомізацію
                let menuItemParams: [String: Any] = [
                    "name": updatedMenuItemForm.name,
                    "price": priceDecimal,
                    "description": updatedMenuItemForm.description.isEmpty ? NSNull() : updatedMenuItemForm.description,
                    "isAvailable": updatedMenuItemForm.isAvailable,
                    "ingredients": updatedMenuItemForm.isCustomizable ? updatedMenuItemForm.ingredients : NSNull(),
                    "customizationOptions": updatedMenuItemForm.isCustomizable ? updatedMenuItemForm.customizationOptions : NSNull()
                ]
                
                print("Створення пункту меню з параметрами: \(menuItemParams)")
                
                // Створення пункту меню через API
                let createdMenuItem = try await viewModel.createMenuItem(
                    groupId: menuGroup.id,
                    name: updatedMenuItemForm.name,
                    price: priceDecimal,
                    description: updatedMenuItemForm.description.isEmpty ? nil : updatedMenuItemForm.description,
                    isAvailable: updatedMenuItemForm.isAvailable
                )
                
                print("Пункт меню успішно створено з ID: \(createdMenuItem.id)")
                
                // Якщо є кастомізація, оновлюємо пункт меню з даними про кастомізацію
                if updatedMenuItemForm.isCustomizable {
                    let updateResult = try await viewModel.updateMenuItem(
                        groupId: menuGroup.id,
                        itemId: createdMenuItem.id,
                        updates: [
                            "ingredients": updatedMenuItemForm.ingredients,
                            "customizationOptions": updatedMenuItemForm.customizationOptions
                        ]
                    )
                    
                    print("Дані про кастомізацію успішно оновлено")
                }
                
                // Якщо є зображення, завантажуємо його
                if let selectedImage = selectedImage {
                    if let compressedImageData = NetworkService.shared.compressImage(selectedImage, format: .jpeg, compressionQuality: 0.7) {
                        print("Зображення успішно стиснуто: \(compressedImageData.count) байт")
                        
                        let uploadRequest = ImageUploadRequest(
                            imageData: compressedImageData,
                            fileName: "menu_item_\(createdMenuItem.id).jpg",
                            mimeType: "image/jpeg"
                        )
                        
                        // Додаємо затримку у 0.5 секунди, щоб переконатися, що запис у БД завершився
                        try await Task.sleep(nanoseconds: 500_000_000)
                        
                        try await viewModel.uploadMenuItemImage(
                            groupId: menuGroup.id,
                            itemId: createdMenuItem.id,
                            imageRequest: uploadRequest
                        )
                        
                        print("Зображення успішно завантажено")
                    } else {
                        print("Помилка стиснення зображення")
                        viewModel.error = "Помилка при підготовці зображення для завантаження"
                    }
                }
                
                isSubmitting = false
            } catch {
                print("Помилка при створенні пункту меню: \(error)")
                viewModel.error = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}
