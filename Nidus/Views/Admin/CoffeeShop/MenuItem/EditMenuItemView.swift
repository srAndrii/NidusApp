//
//  EditMenuItemView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/5/25.
//

import SwiftUI

struct EditMenuItemView: View {
    @Environment(\.presentationMode) var presentationMode
    let menuGroup: MenuGroup
    let menuItem: MenuItem
    @ObservedObject var viewModel: MenuItemsViewModel
    
    // Використання @State(initialValue:) через проперті wrapper
    @State private var name: String
    @State private var price: String
    @State private var description: String
    @State private var isAvailable: Bool
    @State private var isSubmitting = false
    @State private var isViewReady = false
    
    // Стан для роботи з зображеннями
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showImagePickerDialog = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isUploadingImage = false
    
    init(menuGroup: MenuGroup, menuItem: MenuItem, viewModel: MenuItemsViewModel) {
        self.menuGroup = menuGroup
        self.menuItem = menuItem
        self.viewModel = viewModel
        
       
        _name = State(initialValue: menuItem.name)
        _price = State(initialValue: Self.formatPrice(menuItem.price))
        _description = State(initialValue: menuItem.description ?? "")
        _isAvailable = State(initialValue: menuItem.isAvailable)
    }
    
    var body: some View {
            ZStack {
                // Повне відображення UI лише коли isViewReady == true
                if isViewReady {
                    NavigationView {
                        ZStack {
                            Color("backgroundColor")
                                .edgesIgnoringSafeArea(.all)
                            
                            ScrollView {
                                VStack(alignment: .leading, spacing: 20) {
                                    Text("Редагувати пункт меню")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    VStack(spacing: 16) {
                                        CustomTextField(
                                            iconName: "cup.and.saucer",
                                            placeholder: "Назва",
                                            text: $name
                                        )
                                        
                                        CustomTextField(
                                            iconName: "hryvniasign.circle",
                                            placeholder: "Ціна (₴)",
                                            text: $price,
                                            keyboardType: .decimalPad
                                        )
                                        
                                        CustomTextField(
                                            iconName: "text.alignleft",
                                            placeholder: "Опис (необов'язково)",
                                            text: $description
                                        )
                                        
                                        // Перемикач доступності
                                        HStack {
                                            Text("Доступний для замовлення:")
                                                .foregroundColor(Color("primaryText"))
                                            
                                            Spacer()
                                            
                                            Toggle("", isOn: $isAvailable)
                                                .labelsHidden()
                                        }
                                        .padding(.horizontal)
                                        
                                        // Редагування зображення
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Зображення пункту меню")
                                                .font(.subheadline)
                                                .foregroundColor(Color("secondaryText"))
                                            
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color("inputField"))
                                                    .frame(height: 200)
                                                
                                                if let selectedImage = selectedImage {
                                                    // Показуємо обране зображення, якщо воно є
                                                    Image(uiImage: selectedImage)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(height: 200)
                                                        .cornerRadius(12)
                                                } else if let imageUrl = menuItem.imageUrl, let url = URL(string: imageUrl) {
                                                    // Показуємо існуюче зображення, якщо обраного немає
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
                                                    // Показуємо заглушку, якщо зображень немає
                                                    VStack {
                                                        Image(systemName: "photo")
                                                            .font(.system(size: 40))
                                                            .foregroundColor(Color("secondaryText"))
                                                        Text("Немає зображення")
                                                            .foregroundColor(Color("secondaryText"))
                                                    }
                                                }
                                            }
                                            
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
                                        }
                                        .padding()
                                        .background(Color("cardColor"))
                                        .cornerRadius(12)
                                    }
                                    .padding()
                                    .background(Color("cardColor"))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                    
                                    // Кнопка збереження змін
                                    Button(action: updateMenuItem) {
                                        if isSubmitting {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Text("Зберегти зміни")
                                                .font(.headline)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(name.isEmpty || price.isEmpty ? Color.gray : Color("primary"))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                    .disabled(name.isEmpty || price.isEmpty || isSubmitting)
                                    
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
                        .navigationTitle("Редагування пункту меню")
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarItems(trailing: Button("Скасувати") {
                            presentationMode.wrappedValue.dismiss()
                        })
                    }
                } else {
                    // Показуємо заглушку або індикатор завантаження, поки view не готовий до показу
                    Color("backgroundColor")
                        .edgesIgnoringSafeArea(.all)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color("primary")))
                        )
                }
            }
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
            .onAppear {
                // Додаємо невелику затримку перед показом UI,
                // щоб дати час на завантаження і коректну ініціалізацію NavigationView
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation {
                        isViewReady = true
                    }
                }
            }
        }
    
    private func updateMenuItem() {
        guard let priceDecimal = Decimal(string: price.replacingOccurrences(of: ",", with: ".")) else {
            viewModel.error = "Вкажіть коректну ціну"
            return
        }
        
        isSubmitting = true
        
        Task {
            // Збираємо оновлення для пункту меню
            var updates: [String: Any] = [
                "name": name,
                "price": priceDecimal,
                "isAvailable": isAvailable
            ]
            
            // Додаємо опис, якщо він не порожній
            if !description.isEmpty {
                updates["description"] = description
            } else {
                // Якщо опис порожній, але був раніше - встановлюємо null
                if menuItem.description != nil {
                    updates["description"] = NSNull()
                }
            }
            
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
                
                // Показуємо успішне повідомлення
                viewModel.showSuccessMessage("Пункт меню успішно оновлено")
                
            } catch {
                print("Помилка при оновленні пункту меню: \(error)")
                viewModel.error = error.localizedDescription
            }
            
            isSubmitting = false
        }
    }
    
    // Допоміжний статичний метод для форматування ціни
    private static func formatPrice(_ price: Decimal) -> String {
        return price.description.replacingOccurrences(of: ".", with: ",")
    }
}
