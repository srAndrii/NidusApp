import SwiftUI

struct CreateMenuItemView: View {
    @Environment(\.presentationMode) var presentationMode
    let menuGroup: MenuGroup
    @ObservedObject var viewModel: MenuItemsViewModel
    
    @State private var name = ""
    @State private var price = ""
    @State private var description = ""
    @State private var isAvailable = true
    @State private var isSubmitting = false
    
    // Стан для роботи з зображеннями
    @State private var selectedImage: UIImage?
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
                        Text("Інформація про пункт меню")
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
                            
                            // Додавання зображення
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Зображення пункту меню")
                                    .font(.subheadline)
                                    .foregroundColor(Color("secondaryText"))
                                
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
                            }
                            .padding()
                            .background(Color("cardColor"))
                            .cornerRadius(12)
                        }
                        .padding()
                        .background(Color("cardColor"))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
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
    
    private func createMenuItem() {
        guard let priceDecimal = Decimal(string: price.replacingOccurrences(of: ",", with: ".")) else {
            viewModel.error = "Вкажіть коректну ціну"
            return
        }
        
        isSubmitting = true
        
        Task {
            do {
                // Створення пункту меню
                let createdMenuItem = try await viewModel.createMenuItem(
                    groupId: menuGroup.id,
                    name: name,
                    price: priceDecimal,
                    description: description.isEmpty ? nil : description,
                    isAvailable: isAvailable
                )
                
                // Якщо є зображення, завантажуємо його
                if let selectedImage = selectedImage,
                   let compressedImageData = NetworkService.shared.compressImage(selectedImage, format: .jpeg, compressionQuality: 0.7) {
                    let uploadRequest = ImageUploadRequest(
                        imageData: compressedImageData,
                        fileName: "menu_item_\(createdMenuItem.id).jpg",
                        mimeType: "image/jpeg"
                    )
                    
                    try await viewModel.uploadMenuItemImage(
                        groupId: menuGroup.id,
                        itemId: createdMenuItem.id,
                        imageRequest: uploadRequest
                    )
                }
                
                isSubmitting = false
            } catch {
                viewModel.error = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}
