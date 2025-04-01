//
//  Toast.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/31/25.
//

import SwiftUI

struct Toast: View {
    var message: String
    var isShowing: Binding<Bool>
    var duration: Double = 2.0
    
    var body: some View {
        VStack {
            Spacer()
            if isShowing.wrappedValue {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(message)
                        .foregroundColor(Color("primaryText"))
                    Spacer()
                }
                .padding()
                .background(Color("cardColor"))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation {
                            isShowing.wrappedValue = false
                        }
                    }
                }
                .transition(.move(edge: .bottom))
            }
        }
    }
}
