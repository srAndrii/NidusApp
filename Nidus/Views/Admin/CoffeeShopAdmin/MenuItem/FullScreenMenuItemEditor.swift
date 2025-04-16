//
//  FullScreenMenuItemEditor.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import SwiftUI

struct FullScreenMenuItemEditor: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Вхідні дані
    let groupId: String
    let item: MenuItem?
    
    // ViewModel
    @StateObject private var editorViewModel: MenuItemEditorViewModel
    @ObservedObject var menuItemsViewModel: MenuItemsViewModel
    
    // Внутрішній стан
    @State private var showImagePicker = false
    @State private var showImagePickerDialog = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isSubmitting = false
    
    init(groupId: String, item: MenuItem? = nil, menuItemsViewModel: MenuItemsViewModel) {
        self.groupId = groupId
        self.item = item
        self.menuItemsViewModel = menuItemsViewModel
        
        // Ініціалізація ViewModel
        if let existingItem = item {
            _editorViewModel = StateObject(wrappedValue: MenuItemEditorViewModel(from: existingItem))
        } else {
            // Створення нового пункту меню
            let placeholderItem = MenuItem(
                id: UUID().uuidString,
                name: "",
                price: 0,
                description: nil,
                imageUrl: nil,
                isAvailable: true,
                menuGroupId: groupId,
                createdAt: Date(),
                updatedAt: Date()
            )
            _editorViewModel = StateObject(wrappedValue: MenuItemEditorViewModel(from: placeholderItem))
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Вкладки
                Picker("", selection: $editorViewModel.selectedTab) {
                    Text("Основне").tag(0)
                    Text("Кастомізація").tag(1)
                    Text("Розміри").tag(2)
                    Text("Зображення").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top)
                
                // Вміст вкладок
                ScrollView {
                    VStack(spacing: 16) {
                        if editorViewModel.selectedTab == 0 {
                            // Основна інформація
                            basicInfoSection
                        } else if editorViewModel.selectedTab == 1 {
                            // Кастомізація
                            MenuItemCustomizationEditor(viewModel: editorViewModel)
                        } else if editorViewModel.selectedTab == 2 {
                            // Розміри
                            SizesEditorView(viewModel: editorViewModel)
                        } else {
                            // Зображення
                            imageSection
                        }
                        
                        // Повідомлення про помилку
                        if let error = editorViewModel.error {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                                .multilineTextAlignment(.center)
                        }
                        
                        // Відступ внизу сторінки
                        Color.clear.frame(height: 100)
                    }
                    .padding(.top)
                }
                
                // Кнопка збереження
                VStack {
                    Button(action: saveMenuItem) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(item == nil ? "Створити пункт меню" : "Зберегти зміни")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(editorViewModel.name.isEmpty || editorViewModel.price.isEmpty ? Color.gray : Color("primary"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .disabled(editorViewModel.name.isEmpty || editorViewModel.price.isEmpty || isSubmitting)
                }
                .background(Color("backgroundColor"))
            }
            .navigationBarTitle(item == nil ? "Новий пункт меню" : "Редагування", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Скасувати") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(
                selectedImage: $editorViewModel.selectedImage,
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
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - UI Sections
    
    private var basicInfoSection: some View {
        VStack(spacing: 16) {
            CustomTextField(
                iconName: "cup.and.saucer",
                placeholder: "Назва",
                text: $editorViewModel.name
            )
            .padding(.horizontal)
            
            CustomTextField(
                iconName: "hryvniasign.circle",
                placeholder: "Ціна (₴)",
                text: $editorViewModel.price,
                keyboardType: .decimalPad
            )
            .padding(.horizontal)
            
            CustomTextField(
                iconName: "text.alignleft",
                placeholder: "Опис (необов'язково)",
                text: $editorViewModel.description
            )
            .padding(.horizontal)
            
            // Перемикач доступності
            HStack {
                Text("Доступний для замовлення:")
                    .foregroundColor(Color("primaryText"))
                
                Spacer()
                
                Toggle("", isOn: $editorViewModel.isAvailable)
                    .labelsHidden()
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color("cardColor"))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Зображення пункту меню")
                .font(.subheadline)
                .foregroundColor(Color("secondaryText"))
                .padding(.horizontal)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("inputField"))
                    .frame(height: 200)
                
                if let selectedImage = editorViewModel.selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                } else if let imageUrl = editorViewModel.imageUrl, let url = URL(string: imageUrl) {
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
        .padding()
        .background(Color("cardColor"))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    private func saveMenuItem() {
        isSubmitting = true
        
        Task {
            do {
                // Перевірка наявності зображення
                if let selectedImage = editorViewModel.selectedImage {
                    if let compressedImageData = NetworkService.shared.compressImage(selectedImage, format: .jpeg, compressionQuality: 0.7) {
                        let uploadRequest = ImageUploadRequest(
                            imageData: compressedImageData,
                            fileName: "menu_item_\(item?.id ?? UUID().uuidString).jpg",
                            mimeType: "image/jpeg"
                        )
                        
                        try await menuItemsViewModel.uploadMenuItemImage(
                            groupId: groupId,
                            itemId: item?.id ?? "",
                            imageRequest: uploadRequest
                        )
                    }
                }
                
                // Підготовка оновлень
                var updates: [String: Any] = [
                    "name": editorViewModel.name,
                    "price": editorViewModel.price,
                    "isAvailable": editorViewModel.isAvailable,
                    "hasMultipleSizes": editorViewModel.hasMultipleSizes,
                    "description": editorViewModel.description.isEmpty ? NSNull() : editorViewModel.description
                ]
                
                // Обробка кастомізації
                if editorViewModel.isCustomizable {
                    updates["ingredients"] = editorViewModel.ingredients
                    updates["customizationOptions"] = editorViewModel.customizationOptions
                } else {
                    updates["ingredients"] = NSNull()
                    updates["customizationOptions"] = NSNull()
                }
                
                // Обробка розмірів
                if editorViewModel.hasMultipleSizes && !editorViewModel.sizes.isEmpty {
                    updates["sizes"] = editorViewModel.sizes
                } else {
                    updates["sizes"] = NSNull()
                }
                
                // Оновлення або створення пункту меню
                if let existingItem = item {
                    // Оновлення існуючого пункту меню
                    let updatedItem = try await menuItemsViewModel.updateMenuItem(
                        groupId: groupId,
                        itemId: existingItem.id,
                        updates: updates
                    )
                    
                    print("✓ Пункт меню успішно оновлено")
                    menuItemsViewModel.showSuccessMessage("Пункт меню успішно оновлено")
                } else {
                    // Створення нового пункту меню
                    guard let priceDecimal = Decimal(string: editorViewModel.price.replacingOccurrences(of: ",", with: ".")) else {
                        editorViewModel.error = "Неправильний формат ціни"
                        isSubmitting = false
                        return
                    }
                    
                    let _ = try await menuItemsViewModel.createMenuItem(
                        groupId: groupId,
                        name: editorViewModel.name,
                        price: priceDecimal,
                        description: editorViewModel.description.isEmpty ? nil : editorViewModel.description,
                        isAvailable: editorViewModel.isAvailable,
                        hasMultipleSizes: editorViewModel.hasMultipleSizes,
                        ingredients: editorViewModel.isCustomizable ? editorViewModel.ingredients : nil,
                        customizationOptions: editorViewModel.isCustomizable ? editorViewModel.customizationOptions : nil,
                        sizes: editorViewModel.hasMultipleSizes ? editorViewModel.sizes : nil
                    )
                    
                    print("✓ Пункт меню успішно створено")
                    menuItemsViewModel.showSuccessMessage("Пункт меню успішно створено")
                }
                
                // Оновлюємо список і повертаємося назад
                await menuItemsViewModel.loadMenuItems(groupId: groupId)
                presentationMode.wrappedValue.dismiss()
                
            } catch {
                print("❌ Помилка при збереженні пункту меню: \(error)")
                editorViewModel.error = error.localizedDescription
            }
            
            isSubmitting = false
        }
    }
}
