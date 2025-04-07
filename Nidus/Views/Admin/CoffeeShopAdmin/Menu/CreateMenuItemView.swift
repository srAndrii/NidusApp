import SwiftUI

struct CreateMenuItemView: View {
    @Environment(\.presentationMode) var presentationMode
    let menuGroup: MenuGroup
    @ObservedObject var viewModel: MenuItemsViewModel
    
    // Стан форми з використанням розширеної моделі
    @State private var menuItemForm = MenuItemFormModel()
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
            ZStack {
                Color("backgroundColor")
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Вкладки для перемикання між розділами
                        Picker("", selection: $selectedTab) {
                            Text("Основне").tag(0)
                            Text("Кастомізація").tag(1)
                            Text("Зображення").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        // Вміст вкладок
                        if selectedTab == 0 {
                            // Основна інформація
                            basicInfoSection
                        } else if selectedTab == 1 {
                            // Кастомізація
                            MenuItemCustomizationEditor(
                                isCustomizable: $menuItemForm.isCustomizable,
                                ingredients: $menuItemForm.ingredients,
                                customizationOptions: $menuItemForm.customizationOptions
                            )
                        } else {
                            // Зображення
                            imageSection
                        }
                        
                        // Кнопка створення
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
            .navigationTitle("Новий пункт меню")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Скасувати") {
                presentationMode.wrappedValue.dismiss()
            })
            .onChange(of: viewModel.showSuccess) { newValue in
                if newValue {
                    presentationMode.wrappedValue.dismiss()
                }
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
    }
    
    // MARK: - Компоненти інтерфейсу
    
    // Секція основної інформації
    private var basicInfoSection: some View {
        VStack(spacing: 16) {
            CustomTextField(
                iconName: "cup.and.saucer",
                placeholder: "Назва",
                text: $menuItemForm.name
            )
            
            CustomTextField(
                iconName: "hryvniasign.circle",
                placeholder: "Ціна (₴)",
                text: $menuItemForm.price,
                keyboardType: .decimalPad
            )
            
            CustomTextField(
                iconName: "text.alignleft",
                placeholder: "Опис (необов'язково)",
                text: $menuItemForm.description
            )
            
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
    }
    
    // Секція зображення
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
                    try await viewModel.updateMenuItem(
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
