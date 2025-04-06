import SwiftUI

struct CustomModalMenuItemEditor: View {
    @Binding var isPresented: Bool
    @State private var offset: CGFloat = 1000
    let menuGroup: MenuGroup
    let menuItem: MenuItem
    let viewModel: MenuItemsViewModel
    
    // Власні стани для форми
    @State private var name: String
    @State private var price: String
    @State private var description: String
    @State private var isAvailable: Bool
    @State private var isSubmitting = false
    
    // Стан для роботи з зображеннями
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showImagePickerDialog = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    init(isPresented: Binding<Bool>, menuGroup: MenuGroup, menuItem: MenuItem, viewModel: MenuItemsViewModel) {
        self._isPresented = isPresented
        self.menuGroup = menuGroup
        self.menuItem = menuItem
        self.viewModel = viewModel
        
        // Використовуємо статичний метод для форматування ціни
        self._name = State(initialValue: menuItem.name)
        self._price = State(initialValue: Self.formatPrice(menuItem.price))
        self._description = State(initialValue: menuItem.description ?? "")
        self._isAvailable = State(initialValue: menuItem.isAvailable)
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
                
                ScrollView {
                    VStack(spacing: 16) {
                        CustomTextField(
                            iconName: "cup.and.saucer",
                            placeholder: "Назва",
                            text: $name
                        )
                        .padding(.horizontal)
                        
                        CustomTextField(
                            iconName: "hryvniasign.circle",
                            placeholder: "Ціна (₴)",
                            text: $price,
                            keyboardType: .decimalPad
                        )
                        .padding(.horizontal)
                        
                        CustomTextField(
                            iconName: "text.alignleft",
                            placeholder: "Опис (необов'язково)",
                            text: $description
                        )
                        .padding(.horizontal)
                        
                        // Перемикач доступності
                        HStack {
                            Text("Доступний для замовлення:")
                                .foregroundColor(Color("primaryText"))
                            
                            Spacer()
                            
                            Toggle("", isOn: $isAvailable)
                                .labelsHidden()
                        }
                        .padding(.horizontal)
                        
                        // Зображення
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
                        
                        // Повідомлення про помилку
                        if let error = viewModel.error {
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
                        .background(name.isEmpty || price.isEmpty ? Color.gray : Color("primary"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                        .disabled(name.isEmpty || price.isEmpty || isSubmitting)
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
                dismissModal()
                
            } catch {
                print("Помилка при оновленні пункту меню: \(error)")
                viewModel.error = error.localizedDescription
            }
            
            isSubmitting = false
        }
    }
    
    // Статичний метод для форматування ціни,
    // щоб його можна було використати при ініціалізації
    private static func formatPrice(_ price: Decimal) -> String {
        return price.description.replacingOccurrences(of: ".", with: ",")
    }
}
