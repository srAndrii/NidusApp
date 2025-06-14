import SwiftUI
import PhotosUI

struct PersonalInfoView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var viewModel = PersonalInfoViewModel()
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var phone: String = ""
    
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showDeleteAvatarAlert = false
    
    @State private var isSaving = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Background with logo
            backgroundView
            
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar section
                    avatarSection
                        .padding(.top, 20)
                    
                    // Form fields
                    VStack(spacing: 16) {
                        personalInfoCard
                    }
                    .padding(.horizontal)
                    
                    // Save button
                    saveButton
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Особисті дані")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("primaryText"))
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color("primaryText"))
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            loadUserData()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage {
                uploadAvatar(image)
            }
        }
        .alert("Помилка", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Видалити фото?", isPresented: $showDeleteAvatarAlert) {
            Button("Видалити", role: .destructive) {
                deleteAvatar()
            }
            Button("Скасувати", role: .cancel) { }
        } message: {
            Text("Ваше фото профілю буде замінено на стандартне")
        }
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        ZStack {
            // Background gradient same as ProfileView
            Group {
                if colorScheme == .light {
                    // For light theme using the same colors as ProfileView
                    ZStack {
                        // Main horizontal gradient
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("nidusCoolGray").opacity(0.9),
                                Color("nidusLightBlueGray").opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        
                        // Additional vertical gradient for texture
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("nidusCoolGray").opacity(0.15),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        // Thin layer for corner shading
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color("nidusCoolGray").opacity(0.2)
                            ]),
                            center: .bottomTrailing,
                            startRadius: UIScreen.main.bounds.width * 0.2,
                            endRadius: UIScreen.main.bounds.width
                        )
                    }
                } else {
                    // For dark mode use existing color
                    Color("backgroundColor")
                }
            }
            .edgesIgnoringSafeArea(.all)
            
            // Logo as background - same as ProfileView
            Image("Logo")
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
                .frame(width: UIScreen.main.bounds.width * 0.7)
                .saturation(1.5)
                .opacity(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Avatar Section
    private var avatarSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Avatar background using the same component as ProfileView
                AvatarBackground()
                    .frame(width: 120, height: 120)
                
                // Avatar image
                if let avatarUrl = authManager.currentUser?.avatarUrl,
                   let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        case .failure(_), .empty:
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color("secondaryText"))
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color("secondaryText"))
                }
                
                // Upload indicator
                if viewModel.isUploadingAvatar {
                    Circle()
                        .fill(Color.black.opacity(0.7))
                        .frame(width: 120, height: 120)
                        .overlay(
                            ProgressView()
                                .tint(.white)
                        )
                }
            }
            
            // Avatar action buttons
            HStack(spacing: 16) {
                Button(action: { showImagePicker = true }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Змінити")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color("nidusPrimary").opacity(0.2))
                    .foregroundColor(Color("nidusPrimary"))
                    .clipShape(Capsule())
                }
                .disabled(viewModel.isUploadingAvatar)
                
                if hasCustomAvatar {
                    Button(action: { showDeleteAvatarAlert = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Видалити")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color("red").opacity(0.2))
                        .foregroundColor(Color("red"))
                        .clipShape(Capsule())
                    }
                    .disabled(viewModel.isUploadingAvatar)
                }
            }
        }
    }
    
    // MARK: - Personal Info Card
    private var personalInfoCard: some View {
        VStack(spacing: 16) {
            // First Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Ім'я")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color("secondaryText"))
                
                TextField("Введіть ім'я", text: $firstName)
                    .textFieldStyle(GlassTextFieldStyle())
            }
            
            // Last Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Прізвище")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color("secondaryText"))
                
                TextField("Введіть прізвище", text: $lastName)
                    .textFieldStyle(GlassTextFieldStyle())
            }
            
            // Phone
            VStack(alignment: .leading, spacing: 8) {
                Text("Номер телефону")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color("secondaryText"))
                
                TextField("380XXXXXXXXX", text: $phone)
                    .textFieldStyle(GlassTextFieldStyle())
                    .keyboardType(.phonePad)
            }
            
            // Email (read-only)
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color("secondaryText"))
                
                HStack {
                    Text(authManager.currentUser?.email ?? "")
                        .foregroundColor(Color("primaryText"))
                    
                    Spacer()
                    
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(Color("secondaryText"))
                }
                .padding()
                .background(
                    BlurView(style: colorScheme == .light ? .systemUltraThinMaterialLight : .systemUltraThinMaterialDark, opacity: 0.8)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("nidusCoolGray").opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding(20)
        .background(
            BlurView(style: colorScheme == .light ? .systemThinMaterialLight : .systemThinMaterialDark, opacity: 0.9)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color("nidusCoolGray").opacity(0.4), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveChanges) {
            HStack {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Зберегти зміни")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(hasChanges ? Color("nidusPrimary") : Color("nidusGraphite").opacity(0.4))
            )
            .foregroundColor(.white)
        }
        .disabled(!hasChanges || isSaving)
    }
    
    // MARK: - Helper Properties
    private var hasChanges: Bool {
        let user = authManager.currentUser
        return firstName != (user?.firstName ?? "") ||
               lastName != (user?.lastName ?? "") ||
               phone != (user?.phone ?? "")
    }
    
    private var hasCustomAvatar: Bool {
        guard let avatarUrl = authManager.currentUser?.avatarUrl,
              !avatarUrl.isEmpty else {
            return false
        }
        
        // Check if it's not a default avatar URL
        let isDefaultAvatar = avatarUrl.contains("defaults/user.png") || 
                              avatarUrl.contains("demo/image/upload/v1/nidus/defaults") ||
                              avatarUrl.hasSuffix("user.png")
        
        return !isDefaultAvatar
    }
    
    // MARK: - Methods
    private func loadUserData() {
        if let user = authManager.currentUser {
            firstName = user.firstName ?? ""
            lastName = user.lastName ?? ""
            phone = user.phone ?? ""
        }
    }
    
    private func saveChanges() {
        isSaving = true
        
        Task {
            do {
                let updatedUser = try await viewModel.updateProfile(
                    firstName: firstName.isEmpty ? nil : firstName,
                    lastName: lastName.isEmpty ? nil : lastName,
                    phone: phone.isEmpty ? nil : phone
                )
                
                await MainActor.run {
                    authManager.currentUser = updatedUser
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func uploadAvatar(_ image: UIImage) {
        Task {
            do {
                let avatarUrl = try await viewModel.uploadAvatar(image)
                await MainActor.run {
                    // Update the avatar URL directly
                    if var user = authManager.currentUser {
                        user.avatarUrl = avatarUrl
                        authManager.currentUser = user
                    }
                }
            } catch {
                await MainActor.run {
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .serverError(let statusCode, let message):
                            errorMessage = "Помилка сервера (\(statusCode)): \(message ?? "Failed to upload avatar")"
                        default:
                            errorMessage = error.localizedDescription
                        }
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func deleteAvatar() {
        Task {
            do {
                let defaultAvatarUrl = try await viewModel.deleteAvatar()
                await MainActor.run {
                    // Update the avatar URL directly  
                    if var user = authManager.currentUser {
                        user.avatarUrl = defaultAvatarUrl
                        authManager.currentUser = user
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Glass Text Field Style
struct GlassTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .foregroundColor(Color("primaryText"))
            .padding()
            .background(
                BlurView(style: colorScheme == .light ? .systemUltraThinMaterialLight : .systemUltraThinMaterialDark, opacity: 0.8)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("nidusCoolGray").opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage {
                parent.image = image
            } else if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        PersonalInfoView()
            .environmentObject(AuthenticationManager())
    }
}