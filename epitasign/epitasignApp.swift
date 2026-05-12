//
//  epitasignApp.swift
//  epitasign
//
//  Created by Guest User on 24/04/2026.
//

import SwiftUI

#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct epitasignApp: App {
    @StateObject private var environment = AppEnvironment()

    init() {
        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(environment)
        }
    }
}
