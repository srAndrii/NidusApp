//
//  FullScreenMenuItemEditor.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import SwiftUI

struct FullScreenMenuItemEditor: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Зовнішні залежності
    private let menuGroup: MenuGroup
    private let menuItem: MenuItem
    @ObservedObject private var menuItemsViewModel: MenuItemsViewModel
    
    // Внутрішній стан
    @StateObject private var editorViewModel: MenuItemEditorViewModel
    @State private var showImagePicker = false
    @State private var showImagePickerDialog = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isSaving = false
    
    init(viewModel: MenuItemsViewModel, menuGroup: MenuGroup, menuItem: MenuItem) {
        self.menuItemsViewModel = viewModel
        self.menuGroup = menuGroup
        self.menuItem = menuItem
        
        // Створюємо StateObject для відстеження змін пункту меню
        _editorViewModel = StateObject(wrappedValue: MenuItemEditorViewModel(from: menuItem))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Вкладки для перемикання між розділами
            Picker("", selection: $editorViewModel.selectedTab) {
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
                    
                    // Кнопка збереження
                    Button(action: updateMenuItem) {
                        if isSaving {
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
                    .disabled(editorViewModel.name.isEmpty || editorViewModel.price.isEmpty || isSaving)
                    
                    // Відображення помилки
                    if let error = editorViewModel.error {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Редагування \(menuItem.name)")
        .navigationBarTitleDisplayMode(.inline)
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
    
    private func updateMenuItem() {
        guard let updatedMenuItem = editorViewModel.toMenuItem(groupId: menuGroup.id, itemId: menuItem.id) else {
            editorViewModel.error = "Некоректні дані для оновлення"
            return
        }
        
        isSaving = true
        
        Task {
            do {
                // Підготовка даних для оновлення
                var updates: [String: Any] = [
                    "name": updatedMenuItem.name,
                    "price": updatedMenuItem.price,
                    "isAvailable": updatedMenuItem.isAvailable
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
                
                // Показуємо успішне повідомлення і оновлюємо список
                menuItemsViewModel.showSuccessMessage("Пункт меню успішно оновлено")
                await menuItemsViewModel.loadMenuItems(groupId: menuGroup.id)
                
                // Повертаємося назад
                presentationMode.wrappedValue.dismiss()
                
            } catch {
                print("❌ Помилка при оновленні пункту меню: \(error)")
                editorViewModel.error = error.localizedDescription
            }
            
            isSaving = false
        }
    }
}
