import SwiftUI

struct ProfileMenuSection: View {
    let title: String
    let elements: [ProfileMenuElement]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(Color("secondaryText"))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .padding(.top, 16)
            
            VStack(spacing: 0) {
                ForEach(elements.indices, id: \.self) { index in
                    let element = elements[index]
                    
                    ProfileMenuRow(icon: element.icon, title: element.title, action: element.action)
                    
                    if index < elements.count - 1 {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("cardBackground"))
            )
            .padding(.horizontal, 16)
        }
    }
}

struct ProfileMenuElement {
    let icon: String
    let title: String
    let action: () -> Void
    
    init(icon: String, title: String, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.action = action
    }
} 