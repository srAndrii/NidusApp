import SwiftUI
import Kingfisher

struct EditCoffeeShopView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: CoffeeShopViewModel
    let coffeeShop: CoffeeShop
    
    // Стан форми
    @State private var name: String
    @State private var address: String
    @State private var allowScheduledOrders: Bool
    @State private var minPreorderTimeMinutes: Int
    @State private var maxPreorderTimeMinutes: Int
    @State private var workingHours: [String: WorkingHoursPeriod]
    
    // Стан для логотипу - зберігаємо простоту
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    
    // Стан для індикації процесів
    @State private var isSubmitting = false
    @State private var section: FormSection = .basicInfo
    
    enum FormSection {
        case basicInfo, logo, workingHours
    }
    
    init(viewModel: CoffeeShopViewModel, coffeeShop: CoffeeShop) {
        self.viewModel = viewModel
        self.coffeeShop = coffeeShop
        
        // Ініціалізуємо значення з існуючої кав'ярні
        _name = State(initialValue: coffeeShop.name)
        _address = State(initialValue: coffeeShop.address ?? "")
        _allowScheduledOrders = State(initialValue: coffeeShop.allowScheduledOrders)
        _minPreorderTimeMinutes = State(initialValue: coffeeShop.minPreorderTimeMinutes)
        _maxPreorderTimeMinutes = State(initialValue: coffeeShop.maxPreorderTimeMinutes)
        
        // Ініціалізуємо робочі години
        if let hours = coffeeShop.workingHours {
            _workingHours = State(initialValue: hours)
        } else {
            _workingHours = State(initialValue: WorkingHoursModel.createDefault())
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("backgroundColor").edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Перемикач секцій
                        segmentedControl
                        
                        // Вибрана секція форми
                        Group {
                            if section == .basicInfo {
                                basicInfoSection
                            } else if section == .logo {
                                logoSection
                            } else if section == .workingHours {
                                workingHoursSection
                            }
                        }
                        
                        // Кнопка збереження
                        Button(action: saveChanges) {
                            if isSubmitting {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    
                                    Text("Зберігаємо зміни...")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.leading, 8)
                                }
                            } else {
                                Text("Зберегти зміни")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(name.isEmpty || isSubmitting ? Color.gray : Color("primary"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .disabled(name.isEmpty || isSubmitting)
                        
                        // Повідомлення про помилки
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
            .navigationTitle("Редагування кав'ярні")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: cancelButton)
            .onChange(of: viewModel.showSuccess) { if $0 { presentationMode.wrappedValue.dismiss() } }
            // Використовуємо стандартний UIImagePickerController через обгортку
            .sheet(isPresented: $showImagePicker) {
                BasicImagePicker(selectedImage: $selectedImage, isPresented: $showImagePicker)
            }
        }
    }
    
    // MARK: - UI Components
    
    // Перемикач між секціями
    private var segmentedControl: some View {
        Picker("", selection: $section) {
            Text("Основна інф.").tag(FormSection.basicInfo)
            Text("Логотип").tag(FormSection.logo)
            Text("Години роботи").tag(FormSection.workingHours)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
    
    // Кнопка скасування
    private var cancelButton: some View {
        Button("Скасувати") { presentationMode.wrappedValue.dismiss() }
    }
    
    // Секція основної інформації про кав'ярню
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Інформація про кав'ярню")
                .font(.headline)
                .padding(.horizontal)
            
            CustomTextField(iconName: "building.2", placeholder: "Назва кав'ярні", text: $name)
                .padding(.horizontal)
            
            CustomTextField(iconName: "location", placeholder: "Адреса", text: $address)
                .padding(.horizontal)
            
            HStack {
                Text("Попередні замовлення")
                Spacer()
                Toggle("", isOn: $allowScheduledOrders).labelsHidden()
            }
            .padding(.horizontal)
            
            if allowScheduledOrders {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Мінімальний час наперед:")
                        .font(.caption)
                    
                    Picker("", selection: $minPreorderTimeMinutes) {
                        Text("15 хв").tag(15)
                        Text("30 хв").tag(30)
                        Text("1 год").tag(60)
                        Text("2 год").tag(120)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Text("Максимальний час наперед:")
                        .font(.caption)
                        .padding(.top, 8)
                    
                    Picker("", selection: $maxPreorderTimeMinutes) {
                        Text("6 год").tag(360)
                        Text("12 год").tag(720)
                        Text("24 год").tag(1440)
                        Text("48 год").tag(2880)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color("cardColor"))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // Секція логотипу
    private var logoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Логотип кав'ярні")
                .font(.headline)
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
                } else if let logoUrl = coffeeShop.logoUrl, let url = URL(string: logoUrl) {
                    KFImage(url)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                } else {
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(Color("secondaryText"))
                        Text("Немає логотипу")
                            .foregroundColor(Color("secondaryText"))
                    }
                }
            }
            .padding(.horizontal)
            
            HStack(spacing: 12) {
                Button(action: { showImagePicker = true }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("Вибрати зображення")
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color("primary"))
                    .cornerRadius(8)
                }
                .disabled(isSubmitting)
                
                Button(action: resetLogo) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Видалити")
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.red)
                    .cornerRadius(8)
                }
                .disabled(isSubmitting)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color("cardColor"))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // Секція робочих годин
    private var workingHoursSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            WorkingHoursEditorView(workingHours: $workingHours)
        }
        .padding()
        .background(Color("cardColor"))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    // Збереження змін
    private func saveChanges() {
        isSubmitting = true
        
        Task {
            // Валідація робочих годин перед збереженням
            let model = WorkingHoursModel(hours: workingHours)
            let (isValid, errorMessage) = model.validate()
            
            if !isValid {
                viewModel.error = errorMessage ?? "Невірний формат робочих годин"
                isSubmitting = false
                return
            }
            
            // Завантажуємо логотип, якщо він був вибраний
            if let imageToUpload = selectedImage {
                // Стиск зображення перед завантаженням
                if let compressedImage = compressImage(imageToUpload) {
                    do {
                        _ = try await viewModel.uploadLogo(for: coffeeShop.id, image: compressedImage)
                    } catch {
                        print("Помилка при завантаженні логотипу: \(error)")
                        viewModel.error = "Помилка при завантаженні логотипу: \(error.localizedDescription)"
                        isSubmitting = false
                        return
                    }
                } else {
                    viewModel.error = "Помилка при стисненні зображення"
                    isSubmitting = false
                    return
                }
            }
            
            // Оновлюємо базову інформацію про кав'ярню
            let params: [String: Any] = [
                "name": name,
                "address": address.isEmpty ? NSNull() : address,
                "allowScheduledOrders": allowScheduledOrders,
                "minPreorderTimeMinutes": minPreorderTimeMinutes,
                "maxPreorderTimeMinutes": maxPreorderTimeMinutes,
                "workingHours": workingHours
            ]
            
            await viewModel.updateCoffeeShop(id: coffeeShop.id, params: params)
            isSubmitting = false
        }
    }
    
    // Стиснення зображення - виконується ТІЛЬКИ при збереженні, не при виборі
    private func compressImage(_ image: UIImage) -> UIImage? {
        let maxSize: CGFloat = 800
        let originalSize = image.size
        
        // Зменшуємо зображення, якщо воно занадто велике
        var newSize = originalSize
        if originalSize.width > maxSize || originalSize.height > maxSize {
            if originalSize.width > originalSize.height {
                let ratio = maxSize / originalSize.width
                newSize = CGSize(width: maxSize, height: originalSize.height * ratio)
            } else {
                let ratio = maxSize / originalSize.height
                newSize = CGSize(width: originalSize.width * ratio, height: maxSize)
            }
        }
        
        // Стискаємо
        UIGraphicsBeginImageContext(newSize)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    // Скидання логотипу
    private func resetLogo() {
        selectedImage = nil
        
        Task {
            isSubmitting = true
            
            do {
                _ = try await viewModel.resetLogo(for: coffeeShop.id)
            } catch {
                print("Помилка при скиданні логотипу: \(error)")
                viewModel.error = "Помилка при скиданні логотипу: \(error.localizedDescription)"
            }
            
            isSubmitting = false
        }
    }
}

// MARK: - Найпростіший варіант вибору зображення
struct BasicImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: BasicImagePicker
        
        init(_ parent: BasicImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                DispatchQueue.main.async {
                    self.parent.selectedImage = image
                }
            }
            
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}


struct EditCoffeeShopView_Previews: PreviewProvider {
    static var previews: some View {
        let authManager = AuthenticationManager()
        let viewModel = CoffeeShopViewModel(authManager: authManager)
        let coffeeShop = CoffeeShop(
            id: "mock-1",
            name: "Тестова кав'ярня",
            address: "вул. Тестова 1, Київ",
            allowScheduledOrders: true,
            minPreorderTimeMinutes: 15,
            maxPreorderTimeMinutes: 1440,
            workingHours: WorkingHoursModel.createDefault(),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return EditCoffeeShopView(viewModel: viewModel, coffeeShop: coffeeShop)
            .preferredColorScheme(.dark)
    }
}
