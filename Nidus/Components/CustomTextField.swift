//
//  CustomTextField.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import SwiftUI

struct CustomTextField: View {
    let iconName: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(Color("nidusPrimary")) 
                .padding(.leading, 15)
            
            if isSecure {
                SecureField("", text: $text)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(Color("secondaryText"))
                    }
                    .foregroundColor(Color("primaryText"))
                    .padding(.vertical, 15)
                    .padding(.leading, 5)
            } else {
                TextField("", text: $text)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(Color("secondaryText"))
                    }
                    .foregroundColor(Color("primaryText"))
                    .padding(.vertical, 15)
                    .padding(.leading, 5)
                    .autocapitalization(.none)
                    .keyboardType(keyboardType)
            }
        }
        .background(
            ZStack {
                // Фон з ефектом "втиснутого" елемента - ЗБІЛЬШЕНА НЕПРОЗОРІСТЬ
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        colorScheme == .light ?
                            Color.black.opacity(0.25) :
                            Color.black.opacity(0.75)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                colorScheme == .light ?
                                    Color.black.opacity(0.15) :
                                    Color.white.opacity(0.15),
                                lineWidth: 0.5
                            )
                    )
                    // Тіні для ефекту втиснутого елемента
                    .shadow(
                        color: colorScheme == .light ?
                            Color.white.opacity(0.5) :
                            Color.white.opacity(0.1),
                        radius: 1,
                        x: 0,
                        y: 1
                    )
                    .shadow(
                        color: colorScheme == .light ?
                            Color.black.opacity(0.25) :
                            Color.black.opacity(0.45),
                        radius: 1,
                        x: 0,
                        y: -1
                    )
            }
        )
        .cornerRadius(12)
    }
}



struct CustomTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CustomTextField(iconName: "envelope", placeholder: "Електронна пошта", text: .constant(""))
            CustomTextField(iconName: "lock", placeholder: "Пароль", text: .constant(""), isSecure: true)
        }
        .padding()
        .background(Color("backgroundColor"))
        .previewLayout(.sizeThatFits)
    }
}
