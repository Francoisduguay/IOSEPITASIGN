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
    @State private var currentUser: AuthUser?

    var body: some View {
        Group {
            if isAuthenticated {
                MainShellView(user: currentUser) {
                    try? environment.authService.signOut()
                    currentUser = nil
                    isAuthenticated = false
                }
            } else {
                LoginView { user in
                    currentUser = user
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
