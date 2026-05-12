//
//  epitasignApp.swift
//  epitasign
//
//  Created by Guest User on 24/04/2026.
//

import SwiftUI

@main
struct epitasignApp: App {
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(environment)
        }
    }
}
