import Foundation
import UIKit

@MainActor
class PersonalInfoViewModel: ObservableObject {
    @Published var isUploadingAvatar = false
    @Published var isUpdatingProfile = false
    
    private let networkService = NetworkService.shared
    private let userRepository = UserRepository()
    
    // MARK: - Update Profile
    func updateProfile(firstName: String?, lastName: String?, phone: String?) async throws -> User {
        isUpdatingProfile = true
        defer { isUpdatingProfile = false }
        
        // Validate phone format if provided
        if let phone = phone, !phone.isEmpty {
            let phoneRegex = "^380\\d{9}$"
            let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
            
            guard phonePredicate.evaluate(with: phone) else {
                throw APIError.simpleServerError(message: "Номер телефону має починатися з 380 та містити 9 цифр")
            }
        }
        
        return try await userRepository.updateProfile(
            firstName: firstName?.isEmpty == true ? nil : firstName,
            lastName: lastName?.isEmpty == true ? nil : lastName,
            phone: phone?.isEmpty == true ? nil : phone
        )
    }
    
    // MARK: - Upload Avatar
    func uploadAvatar(_ image: UIImage) async throws -> String {
        isUploadingAvatar = true
        defer { isUploadingAvatar = false }
        
        // Compress and prepare image
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw APIError.simpleServerError(message: "Не вдалося обробити зображення")
        }
        
        // Check file size (max 5MB)
        let maxSize = 5 * 1024 * 1024 // 5MB in bytes
        guard imageData.count <= maxSize else {
            throw APIError.simpleServerError(message: "Розмір зображення перевищує 5MB")
        }
        
        let url = URL(string: networkService.getBaseURL() + "/upload/user/avatar")!
        
        // Create multipart form data request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add auth header
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw APIError.unauthorized
        }
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Create body
        var body = Data()
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Check for successful status codes (200 or 201)
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            // Try to parse error message from response
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorData["message"] as? String {
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
            }
            
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: "Failed to upload avatar")
        }
        
        struct UploadResponse: Codable {
            let success: Bool
            let url: String
        }
        
        let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
        return uploadResponse.url
    }
    
    // MARK: - Delete Avatar
    func deleteAvatar() async throws -> String {
        isUploadingAvatar = true
        defer { isUploadingAvatar = false }
        
        struct DeleteResponse: Codable {
            let success: Bool
            let url: String
        }
        
        let deleteResponse: DeleteResponse = try await networkService.delete(endpoint: "/upload/user/avatar")
        return deleteResponse.url
    }
}