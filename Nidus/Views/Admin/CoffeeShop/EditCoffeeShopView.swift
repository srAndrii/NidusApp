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
    
    // Стан для логотипу
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
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
                        Button(action: { saveChanges() }) {
                            if isSubmitting {
                                ProgressView()
                            } else {
                                Text("Зберегти зміни").font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(name.isEmpty ? Color.gray : Color("primary"))
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
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(selectedImage: $selectedImage, isPresented: $showImagePicker, sourceType: sourceType)
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
                
                Button(action: { resetLogo() }) {
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
            // Завантажуємо логотип, якщо він був вибраний
            if let selectedImage = selectedImage {
                do {
                    _ = try await viewModel.uploadLogo(for: coffeeShop.id, image: selectedImage)
                } catch {
                    print("Помилка при завантаженні логотипу: \(error)")
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
    
    // Скидання логотипу
    private func resetLogo() {
        selectedImage = nil
        
        Task {
            do {
                _ = try await viewModel.resetLogo(for: coffeeShop.id)
            } catch {
                print("Помилка при скиданні логотипу: \(error)")
            }
        }
    }
}
