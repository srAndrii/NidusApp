
//
//  UploadModels.swift
//  Nidus
//
//  Created by Andrii Liakhovych
//

import Foundation

/// Модель відповіді при завантаженні файлів
struct UploadResponse: Codable {
    let success: Bool
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case url
    }
}

/// Модель для завантаження зображення
struct ImageUploadRequest {
    let imageData: Data
    let fileName: String
    let mimeType: String
    
    // Ініціалізатор з UIImage
    init(image: UIImage, fileName: String = "image.jpg", compressionQuality: CGFloat = 0.8) {
        if let data = image.jpegData(compressionQuality: compressionQuality) {
            self.imageData = data
            self.fileName = fileName
            self.mimeType = "image/jpeg"
        } else if let data = image.pngData() {
            self.imageData = data
            self.fileName = "image.png"
            self.mimeType = "image/png"
        } else {
            // Якось обробити ситуацію, коли неможливо конвертувати зображення
            self.imageData = Data()
            self.fileName = fileName
            self.mimeType = "application/octet-stream"
        }
    }
    
    // Ініціалізатор з готовими даними
    init(imageData: Data, fileName: String, mimeType: String) {
        self.imageData = imageData
        self.fileName = fileName
        self.mimeType = mimeType
    }
}
