//
//  QRCodeView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

//
//  QRCodeView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.colorScheme) private var colorScheme
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        ZStack {
            // Фон за аналогією з ProfileView
            Group {
                if colorScheme == .light {
                    // Для світлої теми використовуємо нові кольори: nidusCoolGray, nidusMistyBlue та nidusLightBlueGray
                    ZStack {
                        // Основний горизонтальний градієнт
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("nidusCoolGray").opacity(0.9),
                                Color("nidusLightBlueGray").opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        
                        // Додатковий вертикальний градієнт для текстури
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("nidusCoolGray").opacity(0.15),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        // Тонкий шар кольору для затінення в кутах
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
                    // Для темного режиму використовуємо існуючий колір
                    Color("backgroundColor")
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                VStack(spacing: 12) {
                    Text("Ваш QR-код")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color("primaryText"))
                    
                    Text("Покажіть цей код касиру")
                        .font(.subheadline)
                        .foregroundColor(Color("secondaryText"))
                }
                
                // Карточка з QR-кодом зі скляним ефектом
                VStack(spacing: 16) {
                    // QR-код
                    Image(uiImage: generateQRCode(from: getUserId()))
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(12)
                    
                    // ID користувача
                    Text("ID: \(getUserId())")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundColor(Color("primaryText"))
                }
                .padding(20)
                .background(
                    ZStack {
                        // Основний ефект скла
                        BlurView(
                            style: colorScheme == .light ? .systemThinMaterialDark : .systemMaterialDark,
                            opacity: colorScheme == .light ? 0.7 : 0.95
                        )
                        // Додатково тонуємо під кольори застосунку
                        Group {
                            if colorScheme == .light {
                                // Тонування для світлої теми
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color("nidusMistyBlue").opacity(0.25),
                                        Color("nidusCoolGray").opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                
                                // Додаткове тонування для ефекту глибини
                                Color("nidusLightBlueGray").opacity(0.12)
                            } else {
                                // Додатковий шар для глибини у темному режимі
                                Color.black.opacity(0.15)
                            }
                        }
                    }
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    colorScheme == .light 
                                        ? Color("nidusCoolGray").opacity(0.4)
                                        : Color.black.opacity(0.35),
                                    colorScheme == .light
                                        ? Color("nidusLightBlueGray").opacity(0.25)
                                        : Color.black.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                
                VStack(spacing: 8) {
                    Text("Нараховуйте бали")
                        .font(.headline)
                        .foregroundColor(Color("primaryText"))
                    
                    Text("При кожному замовленні через додаток або при скануванні QR-коду в кав'ярні")
                        .font(.subheadline)
                        .foregroundColor(Color("secondaryText"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Функція для отримання ID користувача
    private func getUserId() -> String {
        if let user = authManager.currentUser {
            return user.id
        } else {
            // Якщо користувач не авторизований або ID не доступний,
            // використовуйте унікальний ідентифікатор пристрою
            return UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        }
    }
    
    // Функція для генерації QR-коду
    private func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)
        
        // Встановлення корекції помилок
        filter.correctionLevel = "M"
        
        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        
        // Повернення заглушки, якщо не вдалося згенерувати QR-код
        return UIImage(systemName: "qrcode") ?? UIImage()
    }
}

struct QRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            QRCodeView()
                .environmentObject(AuthenticationManager())
        }
    }
}
