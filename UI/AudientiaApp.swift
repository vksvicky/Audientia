//
//  AudientiaApp.swift
//  Audientia
//
//  Main application entry point
//

import SwiftUI
import Shared

@main
struct AudientiaApp: App {
    @StateObject private var settings = AppSettings.shared
    
    init() {
        // Update versions on app launch
        updateAppVersionFromBuild()
        scanAndRegisterModules()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
        .commands {
            // Add menu commands here
        }
    }
}

