//
//  ImagePickerDialog.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/31/25.
//

import SwiftUI
import UIKit

struct ImagePickerDialog: View {
    @Binding var isPresented: Bool
    @Binding var showImagePicker: Bool
    @Binding var sourceType: UIImagePickerController.SourceType
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture { isPresented = false }
            
            VStack(spacing: 0) {
                Text("Джерело зображення")
                    .font(.headline)
                    .padding(.vertical, 16)
                
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
                    .padding(.vertical, 14)
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
                    .padding(.vertical, 14)
                }
                
                Divider()
                
                Button(action: { isPresented = false }) {
                    Text("Скасувати")
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
            .background(Color("cardColor"))
            .cornerRadius(12)
            .padding(.horizontal, 40)
            .frame(maxWidth: 350)
        }
    }
}

struct ImagePickerDialog_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color("backgroundColor").ignoresSafeArea()
            ImagePickerDialog(
                isPresented: .constant(true),
                showImagePicker: .constant(false),
                sourceType: .constant(.photoLibrary)
            )
        }
        .preferredColorScheme(.dark)
    }
}
