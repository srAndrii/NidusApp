//
//  ProfileMenuRow.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/30/25.
//

import SwiftUI

struct ProfileMenuRow: View {
    let icon: String
    let title: String
    let action: (() -> Void)?
    let isNavigationRow: Bool
    
    init(icon: String, title: String, action: (() -> Void)? = nil, isNavigationRow: Bool = false) {
        self.icon = icon
        self.title = title
        self.action = action
        self.isNavigationRow = isNavigationRow
    }
    
    var body: some View {
        Group {
            if isNavigationRow {
                // Для NavigationLink не використовуємо Button
                rowContent
            } else {
                // Для звичайних action використовуємо Button
                Button(action: {
                    if let action = action {
                        action()
                    }
                }) {
                    rowContent
                }
            }
        }
    }
    
    private var rowContent: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color("primary"))
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(Color("secondaryText"))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Color("secondary"))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.clear)
    }
}

struct ProfileMenuRow_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color("backgroundColor")
                .edgesIgnoringSafeArea(.all)
            
        ProfileMenuRow(icon: "person.fill", title: "Особисті дані")
            .previewLayout(.sizeThatFits)
                .background(BlurView(style: .systemMaterialDark, opacity: 0.95))
                .cornerRadius(12)
                .padding()
        }
    }
}
