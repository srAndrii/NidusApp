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
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            // Виконується дія при натисканні
            action?()
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color("primary"))
                    .frame(width: 24, height: 24)
                    .padding(.trailing, 8)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(Color("primaryText"))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color("secondaryText"))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
        }
        .background(Color("cardColor"))
    }
}

struct ProfileMenuRow_Previews: PreviewProvider {
    static var previews: some View {
        ProfileMenuRow(icon: "person.fill", title: "Особисті дані")
            .previewLayout(.sizeThatFits)
            .background(Color("cardColor"))
            .preferredColorScheme(.dark)
    }
}
