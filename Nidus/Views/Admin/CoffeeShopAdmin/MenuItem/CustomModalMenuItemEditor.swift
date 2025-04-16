//
//  CustomModalMenuItemEditor.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import SwiftUI

struct CustomModalMenuItemEditor: View {
    @Binding var isPresented: Bool
    @State private var offset: CGFloat = 1000
    
    // Зовнішні залежності
    private let menuGroup: MenuGroup
    private let menuItem: MenuItem
    @ObservedObject private var menuItemsViewModel: MenuItemsViewModel
    
    // Функція для оновлення батьківського компонента
    var onUpdate: ((MenuItem) -> Void)? = nil
    
    // Внутрішній стан
    @StateObject private var editorViewModel: MenuItemEditorViewModel
    @State private var showImagePicker = false
    @State private var showImagePickerDialog = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isSubmitting = false
    
    init(isPresented: Binding<Bool>, menuGroup: MenuGroup, menuItem: MenuItem, viewModel: MenuItemsViewModel, onUpdate: ((MenuItem) -> Void)? = nil) {
        self._isPresented = isPresented
        self.menuGroup = menuGroup
        self.menuItem = menuItem
        self.menuItemsViewModel = viewModel
        self.onUpdate = onUpdate
        
        // Створюємо StateObject для відстеження змін пункту меню
        _editorViewModel = StateObject(wrappedValue: MenuItemEditorViewModel(from: menuItem))
    }
    
    var body: some View {
        ZStack {
            // Напівпрозорий фон
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismissModal()
                }
            
            // Вміст модального вікна
            VStack {
                // Заголовок з кнопкою закриття
                HStack {
                    Text("Редагування пункту меню")
                        .font(.headline)
                        .foregroundColor(Color("primaryText"))
                    
                    Spacer()
                    
                    Button(action: {
                        dismissModal()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(Color("secondaryText"))
                    }
                }
                .padding(.top)
                .padding(.horizontal)
                
                // Вкладки для перемикання між розділами
                Picker("", selection: $editorViewModel.selectedTab) {
                    Text("Основне").tag(0)
                    Text("Кастомізація").tag(1)
                    Text("Зображення").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Вміст вкладок
                        if editorViewModel.selectedTab == 0 {
                            // Основна інформація
                            basicInfoSection
                        } else if editorViewModel.selectedTab == 1 {
                            // Кастомізація
                            MenuItemCustomizationEditor(viewModel: editorViewModel)
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
                        .background(editorViewModel.name.isEmpty || editorViewModel.price.isEmpty ? Color.gray : Color("primary"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                        .disabled(editorViewModel.name.isEmpty || editorViewModel.price.isEmpty || isSubmitting)
                    }
                    .padding(.vertical)
                }
            }
            .background(Color("backgroundColor"))
            .cornerRadius(16)
            .padding(.horizontal)
            .padding(.vertical, 40)
            .offset(y: offset)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    offset = 0
                }
            }
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
    }
    
    // MARK: - Actions
    
    private func dismissModal() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = 1000
        }
        
        // Даємо анімації час завершитись перед закриттям модального вікна
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
    
    private func updateMenuItem() {
        guard let updatedMenuItem = editorViewModel.toMenuItem(groupId: menuGroup.id, itemId: menuItem.id) else {
            editorViewModel.error = "Некоректні дані для оновлення"
            return
        }
        
        isSubmitting = true
        
        Task {
            do {
                // Підготовка даних для оновлення
                var updates: [String: Any] = [
                    "name": updatedMenuItem.name,
                    "price": updatedMenuItem.price,
                    "isAvailable": updatedMenuItem.isAvailable,
                    "hasMultipleSizes": updatedMenuItem.hasMultipleSizes ?? false
                ]
                
                // Додавання опису
                if let description = updatedMenuItem.description {
                    updates["description"] = description
                } else {
                    updates["description"] = NSNull()
                }
                
                // Обробка кастомізації
                if editorViewModel.isCustomizable {
                    updates["ingredients"] = updatedMenuItem.ingredients
                    updates["customizationOptions"] = updatedMenuItem.customizationOptions
                    
                    print("🚀 Додавання кастомізації в оновлення")
                    print("🚀 Опції: \(editorViewModel.customizationOptions.count)")
                    
                    for (i, option) in editorViewModel.customizationOptions.enumerated() {
                        print("🚀 Опція \(i): \(option.name), виборів: \(option.choices.count)")
                        for (j, choice) in option.choices.enumerated() {
                            print("🚀 -- Вибір \(j): \(choice.name)")
                        }
                    }
                } else {
                    updates["ingredients"] = NSNull()
                    updates["customizationOptions"] = NSNull()
                }
                
                // Обробка розмірів
                if editorViewModel.hasMultipleSizes && !editorViewModel.sizes.isEmpty {
                    updates["sizes"] = updatedMenuItem.sizes
                    
                    print("🚀 Додавання розмірів в оновлення")
                    print("🚀 Розміри: \(editorViewModel.sizes.count)")
                    
                    for (i, size) in editorViewModel.sizes.enumerated() {
                        print("🚀 Розмір \(i): \(size.name), додаткова ціна: \(size.additionalPrice), за замовчуванням: \(size.isDefault)")
                    }
                } else {
                    updates["sizes"] = NSNull()
                }
                
                // Відправка оновлення на сервер
                let updatedItem = try await menuItemsViewModel.updateMenuItem(
                    groupId: menuGroup.id,
                    itemId: menuItem.id,
                    updates: updates
                )
                
                print("✓ Пункт меню успішно оновлено")
                
                // Завантаження нового зображення, якщо воно було вибране
                if let selectedImage = editorViewModel.selectedImage {
                    if let compressedImageData = NetworkService.shared.compressImage(selectedImage, format: .jpeg, compressionQuality: 0.7) {
                        let uploadRequest = ImageUploadRequest(
                            imageData: compressedImageData,
                            fileName: "menu_item_\(menuItem.id).jpg",
                            mimeType: "image/jpeg"
                        )
                        
                        try await menuItemsViewModel.uploadMenuItemImage(
                            groupId: menuGroup.id,
                            itemId: menuItem.id,
                            imageRequest: uploadRequest
                        )
                        
                        print("✓ Зображення успішно завантажено")
                    }
                }
                
                // Викликаємо функцію оновлення з новими даними, якщо вона була передана
                if let onUpdate = onUpdate {
                    onUpdate(updatedItem)
                }
                
                // Показуємо успішне повідомлення
                menuItemsViewModel.showSuccessMessage("Пункт меню успішно оновлено")
                dismissModal()
                
            } catch {
                print("❌ Помилка при оновленні пункту меню: \(error)")
                editorViewModel.error = error.localizedDescription
            }
            
            isSubmitting = false
        }
    }
}
