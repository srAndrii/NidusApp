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
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(Color("secondaryText"))
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
        .background(Color("inputField"))
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
