//
//  FullScreenMenuItemEditor.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/5/25.
//
import SwiftUI

struct FullScreenMenuItemEditor: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: MenuItemsViewModel
    let menuGroup: MenuGroup
    let menuItem: MenuItem
    
    // Використовуємо нову модель форми для кастомізації
    @State private var menuItemForm: MenuItemFormModel
    @State private var isSubmitting = false
    
    // Стан для вкладок і зображення
    @State private var selectedTab = 0
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showImagePickerDialog = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    init(viewModel: MenuItemsViewModel, menuGroup: MenuGroup, menuItem: MenuItem) {
        self.viewModel = viewModel
        self.menuGroup = menuGroup
        self.menuItem = menuItem
        
        // Ініціалізуємо форму з існуючим меню-айтемом
        self._menuItemForm = State(initialValue: MenuItemFormModel(from: menuItem))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Вкладки для перемикання між розділами
            Picker("", selection: $selectedTab) {
                Text("Основне").tag(0)
                Text("Кастомізація").tag(1)
                Text("Зображення").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.top)
            
            ScrollView {
                VStack(spacing: 16) {
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
                    
                    // Кнопка збереження
                    Button(action: updateMenuItem) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Зберегти зміни")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(menuItemForm.name.isEmpty || menuItemForm.price.isEmpty ? Color.gray : Color("primary"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .disabled(menuItemForm.name.isEmpty || menuItemForm.price.isEmpty || isSubmitting)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Редагування \(menuItem.name)")
        .navigationBarTitleDisplayMode(.inline)
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
        .onAppear {
            // Завантажуємо найсвіжіші дані при появі екрану
            Task {
                do {
                    let freshMenuItem = try await viewModel.getMenuItem(groupId: menuGroup.id, itemId: menuItem.id)
                    // Оновлюємо форму з новими даними
                    menuItemForm = MenuItemFormModel(from: freshMenuItem)
                } catch {
                    print("Помилка при завантаженні свіжих даних: \(error)")
                }
            }
        }
    }
    
    // MARK: - Секції інтерфейсу (аналогічно з вашого модального редактора)
    var basicInfoSection: some View {
        // Код секції основної інформації (скопіюйте з вашого модального редактора)
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
    }
    
    var imageSection: some View {
        // Код секції зображення (скопіюйте з вашого модального редактора)
        VStack(alignment: .leading, spacing: 8) {
            Text("Зображення пункту меню")
                .font(.subheadline)
                .foregroundColor(Color("secondaryText"))
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
                } else if let imageUrl = menuItem.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(12)
                        case .failure(_), .empty:
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(Color("secondaryText"))
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(Color("secondaryText"))
                        Text("Немає зображення")
                            .foregroundColor(Color("secondaryText"))
                    }
                }
            }
            .padding(.horizontal)
            
            Button(action: { showImagePickerDialog = true }) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Змінити зображення")
                }
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color("primary"))
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Функція оновлення меню-айтема
    private func updateMenuItem() {
        guard let priceDecimal = Decimal(string: menuItemForm.price.replacingOccurrences(of: ",", with: ".")) else {
            viewModel.error = "Вкажіть коректну ціну"
            return
        }
        
        isSubmitting = true
        
        Task {
            // Збираємо оновлення для пункту меню
            var updates: [String: Any] = [
                "name": menuItemForm.name,
                "price": priceDecimal,
                "isAvailable": menuItemForm.isAvailable
            ]
            
            // Додаємо опис, якщо він не порожній
            if !menuItemForm.description.isEmpty {
                updates["description"] = menuItemForm.description
            } else if menuItem.description != nil {
                updates["description"] = NSNull()
            }
            
            // Обробка кастомізації - важливо завжди додавати інгредієнти та опції
            if menuItemForm.isCustomizable {
                // Якщо кастомізація увімкнена, зберігаємо інгредієнти та опції
                updates["ingredients"] = menuItemForm.ingredients
                updates["customizationOptions"] = menuItemForm.customizationOptions
            } else {
                // Якщо кастомізація вимкнена, видаляємо інгредієнти та опції
                updates["ingredients"] = NSNull()
                updates["customizationOptions"] = NSNull()
            }
            
            // Логуємо дані для дебагу
            print("Дані для оновлення: \(updates)")
            
            do {
                // Оновлення пункту меню
                let updatedItem = try await viewModel.updateMenuItem(
                    groupId: menuGroup.id,
                    itemId: menuItem.id,
                    updates: updates
                )
                
                print("Пункт меню успішно оновлено з ID: \(updatedItem.id)")
                
                // Якщо є нове зображення, завантажуємо його
                if let selectedImage = selectedImage {
                    if let compressedImageData = NetworkService.shared.compressImage(selectedImage, format: .jpeg, compressionQuality: 0.7) {
                        print("Зображення успішно стиснуто: \(compressedImageData.count) байт")
                        
                        let uploadRequest = ImageUploadRequest(
                            imageData: compressedImageData,
                            fileName: "menu_item_\(menuItem.id).jpg",
                            mimeType: "image/jpeg"
                        )
                        
                        // Додаємо затримку у 0.5 секунди, щоб переконатися, що запис у БД завершився
                        try await Task.sleep(nanoseconds: 500_000_000)
                        
                        try await viewModel.uploadMenuItemImage(
                            groupId: menuGroup.id,
                            itemId: menuItem.id,
                            imageRequest: uploadRequest
                        )
                        
                        print("Зображення успішно завантажено")
                    } else {
                        print("Помилка стиснення зображення")
                        viewModel.error = "Помилка при підготовці зображення для завантаження"
                    }
                }
                
                // Показуємо успішне повідомлення та оновлюємо список
                viewModel.showSuccessMessage("Пункт меню успішно оновлено")
                
                // Оновлюємо список пунктів меню
                await viewModel.loadMenuItems(groupId: menuGroup.id)
                
                // Повертаємось назад
                presentationMode.wrappedValue.dismiss()
                
            } catch {
                print("Помилка при оновленні пункту меню: \(error)")
                viewModel.error = error.localizedDescription
            }
            
            isSubmitting = false
        }
    }
}
