//
//  SettingsView.swift
//  Audientia
//
//  Comprehensive Settings/Preferences UI
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import Shared
import SwiftUI

// Force compiler to see NotificationPermissionManager type
// This helps resolve build order issues
private let _notificationManagerTypeCheck: NotificationPermissionManager.Type =
    NotificationPermissionManager.self

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
        HSplitView {
            // Sidebar with categories
            List(selection: $selectedCategory) {
                ForEach(SettingsCategory.allCases, id: \.self) { category in
                    HStack {
                        Image(systemName: category.iconName)
                            .frame(width: 20)
                        Text(category.displayName)
                    }
                    .tag(category)
                }
            }
            .frame(minWidth: 200, idealWidth: 250)
            .listStyle(.sidebar)
            
            // Detail view for selected category
            VStack(spacing: 0) {
                // Title bar
                HStack {
                    Text(selectedCategory.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                // Content
                ScrollView {
                    settingsDetailView
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        case .language:
            LanguageSettingsView()
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
    case language
    case advanced
    
    @MainActor
    var displayName: String {
        let localisation = LocalisationManager.shared
        switch self {
        case .general: return localisation[LocalisationManager.general]
        case .library: return localisation[LocalisationManager.library]
        case .playback: return localisation[LocalisationManager.playback]
        case .audio: return localisation[LocalisationManager.audio]
        case .appearance: return localisation[LocalisationManager.appearance]
        case .language: return localisation[LocalisationManager.language]
        case .advanced: return localisation[LocalisationManager.advanced]
        }
    }
    
    var iconName: String {
        switch self {
        case .general: return "gearshape"
        case .library: return "music.note.list"
        case .playback: return "play.circle"
        case .audio: return "waveform"
        case .appearance: return "paintbrush"
        case .language: return "globe"
        case .advanced: return "wrench.and.screwdriver"
        }
    }
}

/// General settings view
@MainActor
private struct GeneralSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var settings: AppSettings
    // Use type inference to avoid explicit type annotation that causes build issues
    @ObservedObject private var notificationManager =
        NotificationPermissionManager.shared
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        self.settings = AppSettings.shared
    }
    
    var body: some View {
        Form {
            Section(LocalisationManager.shared[LocalisationManager.startup]) {
                Toggle(
                    LocalisationManager.shared[LocalisationManager.showSplashScreen],
                    isOn: $settings.showSplashScreen
                )
                    .help(LocalisationManager.shared[LocalisationManager.showSplashScreenHelp])
            }
            
            Section(LocalisationManager.shared[LocalisationManager.notifications]) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        "\(LocalisationManager.shared[LocalisationManager.notificationStatus]) "
                        + "\(notificationManager.statusDescription)"
                    )
                        .fontWeight(.semibold)
                    Text(LocalisationManager.shared[LocalisationManager.notificationDescription])
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Button(LocalisationManager.shared[LocalisationManager.requestPermission]) {
                        Task { await notificationManager.requestPermissionFromSettings() }
                    }
                    Button(LocalisationManager.shared[LocalisationManager.openSystemSettings]) {
                        notificationManager.openSystemSettings()
                    }
                }
            }
            
            Section(LocalisationManager.shared[LocalisationManager.window]) {
                // Window settings will go here
                Text(LocalisationManager.shared[LocalisationManager.windowManagementSettings])
            }
        }
        .task {
            await notificationManager.refreshAuthorizationStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await notificationManager.refreshAuthorizationStatus() }
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
            Section(LocalisationManager.shared[LocalisationManager.library]) {
                // Library view configuration will go here
                Text(LocalisationManager.shared[LocalisationManager.libraryViewSettings])
            }
        }
        .padding()
    }
}

/// Playback settings view
@MainActor
private struct PlaybackSettingsView: View {
    @ObservedObject private var appSettings = AppSettings.shared
    
    var body: some View {
        Form {
            Section(LocalisationManager.shared[LocalisationManager.trackInfoDisplay]) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalisationManager.shared[LocalisationManager.scrollSpeed])
                        .font(.headline)
                    
                    HStack {
                        Slider(
                            value: $appSettings.trackInfoScrollSpeed,
                            in: 10...100,
                            step: 5
                        )
                        Text(
                            "\(Int(appSettings.trackInfoScrollSpeed)) "
                            + "\(LocalisationManager.shared[LocalisationManager.pxPerSecond])"
                        )
                            .frame(width: 60, alignment: .trailing)
                            .monospacedDigit()
                    }
                    
                    Text(LocalisationManager.shared[LocalisationManager.longTrackTitlesScroll])
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(LocalisationManager.shared[LocalisationManager.adjustScrollSpeed])
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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
            Section(LocalisationManager.shared[LocalisationManager.themeTheme]) {
                // Theme selector will be integrated here
                Text(LocalisationManager.shared[LocalisationManager.themeSettings])
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
            Section(LocalisationManager.shared[LocalisationManager.reset]) {
                Button(LocalisationManager.shared[LocalisationManager.resetAllSettings]) {
                    Task {
                        try? await viewModel.resetToDefaults()
                    }
                }
            }
        }
        .padding()
    }
}
