//
//  ImagePickerView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/31/25.
//

import SwiftUI
import UIKit
import PhotosUI

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate, PHPickerViewControllerDelegate {
        var parent: ImagePickerView
        
        init(parent: ImagePickerView) {
            self.parent = parent
        }
        
        // UIImagePickerController Delegate
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage {
                parent.selectedImage = image
            } else if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
        
        // PHPickerViewController Delegate
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        if let image = image as? UIImage {
                            self.parent.selectedImage = image
                        }
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        if sourceType == .camera || sourceType == .photoLibrary {
            let imagePicker = UIImagePickerController()
            imagePicker.allowsEditing = true
            imagePicker.sourceType = sourceType
            imagePicker.delegate = context.coordinator
            return imagePicker
        } else {
            // Використовуємо PHPickerViewController для iOS 14+
            var config = PHPickerConfiguration()
            config.filter = .images
            config.selectionLimit = 1
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = context.coordinator
            return picker
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Нічого не робимо
    }
}

struct ImageActionSheet: View {
    @Binding var isPresented: Bool
    @Binding var showImagePicker: Bool
    @Binding var sourceType: UIImagePickerController.SourceType
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 16) {
                Text("Оберіть джерело")
                    .font(.headline)
                    .foregroundColor(Color("primaryText"))
                    .padding(.top, 16)
                
                Divider()
                
                Button(action: {
                    sourceType = .camera
                    isPresented = false
                    showImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(Color("primary"))
                        Text("Камера")
                            .foregroundColor(Color("primaryText"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                
                Divider()
                
                Button(action: {
                    sourceType = .photoLibrary
                    isPresented = false
                    showImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.fill")
                            .foregroundColor(Color("primary"))
                        Text("Галерея")
                            .foregroundColor(Color("primaryText"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                
                Divider()
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Скасувати")
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .background(Color("cardColor"))
            .cornerRadius(12)
            .padding(.horizontal, 40)
        }
    }
}
