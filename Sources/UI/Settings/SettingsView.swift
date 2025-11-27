//
//  SettingsView.swift
//  Audientia
//
//  Comprehensive Settings/Preferences UI
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Shared
import SwiftUI

/// Main settings view with categories: General, Library, Playback, Audio/DSP, Appearance, Advanced
/// BDD: As a user, I want to access all application settings in one place
@MainActor
public struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @State private var selectedCategory: SettingsCategory = .general
    
    public init(viewModel: SettingsViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: SettingsViewModel())
        }
    }
    
    public var body: some View {
        NavigationSplitView {
            // Sidebar with categories
            List(selection: $selectedCategory) {
                ForEach(SettingsCategory.allCases, id: \.self) { category in
                    NavigationLink(value: category) {
                        Label(category.displayName, systemImage: category.iconName)
                    }
                }
            }
            .navigationTitle("Settings")
            .frame(minWidth: 200)
        } detail: {
            // Detail view for selected category
            settingsDetailView
                .navigationTitle(selectedCategory.displayName)
        }
        .frame(minWidth: 800, minHeight: 600)
        .task {
            await viewModel.loadSettings()
        }
    }
    
    @ViewBuilder
    private var settingsDetailView: some View {
        switch selectedCategory {
        case .general:
            GeneralSettingsView(viewModel: viewModel)
        case .library:
            LibrarySettingsView(viewModel: viewModel)
        case .playback:
            PlaybackSettingsView()
        case .audio:
            AudioSettingsView() // Already exists in UI/Settings
        case .appearance:
            AppearanceSettingsView(viewModel: viewModel)
        case .advanced:
            AdvancedSettingsView(viewModel: viewModel)
        }
    }
}

/// Settings categories
enum SettingsCategory: String, CaseIterable {
    case general
    case library
    case playback
    case audio
    case appearance
    case advanced
    
    var displayName: String {
        switch self {
        case .general: return "General"
        case .library: return "Library"
        case .playback: return "Playback"
        case .audio: return "Audio/DSP"
        case .appearance: return "Appearance"
        case .advanced: return "Advanced"
        }
    }
    
    var iconName: String {
        switch self {
        case .general: return "gearshape"
        case .library: return "music.note.list"
        case .playback: return "play.circle"
        case .audio: return "waveform"
        case .appearance: return "paintbrush"
        case .advanced: return "wrench.and.screwdriver"
        }
    }
}

/// General settings view
@MainActor
private struct GeneralSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var settings: AppSettings
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        self.settings = AppSettings.shared
    }
    
    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Show splash screen on startup", isOn: $settings.showSplashScreen)
                    .help("Display the splash screen when the application launches")
            }
            
            Section("Window") {
                // Window settings will go here
                Text("Window management settings")
            }
        }
        .padding()
    }
}

/// Library settings view
@MainActor
private struct LibrarySettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section("Library View") {
                // Library view configuration will go here
                Text("Library view settings")
            }
        }
        .padding()
    }
}

/// Playback settings view
@MainActor
private struct PlaybackSettingsView: View {
    var body: some View {
        Form {
            Section("Playback") {
                Text("Playback settings")
            }
        }
        .padding()
    }
}

/// Appearance settings view
@MainActor
private struct AppearanceSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section("Theme") {
                // Theme selector will be integrated here
                Text("Theme settings")
            }
        }
        .padding()
    }
}

/// Advanced settings view
@MainActor
private struct AdvancedSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section("Reset") {
                Button("Reset All Settings to Defaults") {
                    Task {
                        try? await viewModel.resetToDefaults()
                    }
                }
            }
        }
        .padding()
    }
}
