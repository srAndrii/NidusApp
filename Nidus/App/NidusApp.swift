//
//  NidusApp.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//
// App/NidusApp.swift
import SwiftUI

@main
struct NidusApp: App {
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authManager.isAuthenticated {
                    MainView()
                        .environmentObject(DIContainer.shared.tabBarManager)
                } else {
                    AuthView()
                }
            }
            .environmentObject(authManager)
      
        }
    }
}
