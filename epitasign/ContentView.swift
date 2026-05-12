//
//  ContentView.swift
//  epitasign
//
//  Created by Guest User on 24/04/2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @AppStorage("usesDarkMode") private var usesDarkMode = false
    @State private var isAuthenticated = false

    var body: some View {
        Group {
            if isAuthenticated {
                MainShellView {
                    try? environment.authService.signOut()
                    isAuthenticated = false
                }
            } else {
                LoginView {
                    isAuthenticated = true
                }
            }
        }
        .preferredColorScheme(usesDarkMode ? .dark : nil)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppEnvironment())
}
