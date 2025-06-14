//
//  SupportView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 6/14/25.
//

import SwiftUI
import MessageUI

struct SupportView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var showingMailCompose = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let supportEmail = "nidus@gmail.com"
    
    var body: some View {
        ZStack {
            // Фон - такий же як у ProfileView
            Group {
                if colorScheme == .light {
                    ZStack {
                        // Основний горизонтальний градієнт з більшим акцентом на сірі відтінки
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
            .edgesIgnoringSafeArea(.all)
            
            // Логотип як фон
            Image("Logo")
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
                .frame(width: UIScreen.main.bounds.width * 0.7)
                .saturation(1.5)
                .opacity(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            ScrollView {
                VStack(spacing: 30) {
                    // Заголовок
                    VStack(spacing: 12) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color("primaryText"))
                        
                        Text("Підтримка")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color("primaryText"))
                        
                        Text("Ми завжди готові допомогти вам")
                            .font(.subheadline)
                            .foregroundColor(Color("secondary"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Інформаційна картка
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            Text("Є питання або потрібна допомога?")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("primaryText"))
                                .multilineTextAlignment(.center)
                            
                            Text("Наша команда підтримки готова відповісти на всі ваші запитання та допомогти вирішити будь-які проблеми з додатком.")
                                .font(.body)
                                .foregroundColor(Color("secondary"))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        
                        // Email контакт
                        VStack(spacing: 12) {
                            Text("Зв'яжіться з нами:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color("primaryText"))
                            
                            Button(action: {
                                openEmailClient()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 18))
                                    
                                    Text(supportEmail)
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue.opacity(0.8),
                                            Color.blue
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                        }
                        
                        // Додаткова інформація
                        VStack(spacing: 8) {
                            Text("Час відповіді:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color("primaryText"))
                            
                            Text("Зазвичай ми відповідаємо протягом 24 годин")
                                .font(.caption)
                                .foregroundColor(Color("secondary"))
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(
                        ZStack {
                            // Основний ефект скла
                            BlurView(
                                style: colorScheme == .light ? .systemThinMaterial : .systemMaterialDark,
                                opacity: colorScheme == .light ? 0.95 : 0.95
                            )
                            // Додатково тонуємо під кольори застосунку
                            Group {
                                if colorScheme == .light {
                                    // Тонування для світлої теми з новими кольорами
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
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("Підтримка")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingMailCompose) {
            MailComposeView(
                recipients: [supportEmail],
                subject: "Питання щодо Nidus",
                body: ""
            )
        }
        .alert("Інформація", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func openEmailClient() {
        // Спочатку спробуємо відкрити через URL схеми популярних email клієнтів
        let emailSubject = "Питання щодо Nidus".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Спробуємо Gmail
        if let gmailURL = URL(string: "googlegmail://co?to=\(supportEmail)&subject=\(emailSubject)") {
            if UIApplication.shared.canOpenURL(gmailURL) {
                UIApplication.shared.open(gmailURL)
                return
            }
        }
        
        // Спробуємо Outlook
        if let outlookURL = URL(string: "ms-outlook://compose?to=\(supportEmail)&subject=\(emailSubject)") {
            if UIApplication.shared.canOpenURL(outlookURL) {
                UIApplication.shared.open(outlookURL)
                return
            }
        }
        
        // Спробуємо стандартний mailto
        if let mailtoURL = URL(string: "mailto:\(supportEmail)?subject=\(emailSubject)") {
            if UIApplication.shared.canOpenURL(mailtoURL) {
                UIApplication.shared.open(mailtoURL)
                return
            }
        }
        
        // Якщо можемо відкрити нативний mail composer
        if MFMailComposeViewController.canSendMail() {
            showingMailCompose = true
            return
        }
        
        // Останній варіант - показати діалог з опціями
        UIPasteboard.general.string = supportEmail
        alertMessage = "Email скопійовано: \(supportEmail)\n\nВстановіть поштовий клієнт для зручного надсилання листів."
        showingAlert = true
    }
}

// Wrapper для MFMailComposeViewController
struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let body: String
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients(recipients)
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // Не потрібно оновлювати
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.dismiss()
        }
    }
}

struct SupportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SupportView()
        }
    }
}