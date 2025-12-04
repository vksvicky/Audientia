//
//  LocalisationManager.swift
//  Shared
//
//  Manages localisation and translations for the application
//  Uses JSON files for scalable multi-language support
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

/// Manages localisation and provides translated strings
@MainActor
public final class LocalisationManager: ObservableObject {
    /// Shared singleton instance
    public static let shared = LocalisationManager()
    
    /// Currently selected language
    @Published public var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "AppLanguage")
            loadTranslations()
        }
    }
    
    /// Loaded translations for current language
    private var translations: [String: Any] = [:]
    
    private init() {
        // Load saved language or use default (British English)
        if let savedLang = UserDefaults.standard.string(forKey: "AppLanguage"),
           let language = Language(rawValue: savedLang) {
            self.currentLanguage = language
        } else {
            self.currentLanguage = .default
        }
        loadTranslations()
    }
    
    /// Load translations from JSON file for current language
    private func loadTranslations() {
        // Try main bundle first
        var url = Bundle.main.url(
            forResource: currentLanguage.code,
            withExtension: "json",
            subdirectory: "Localisation"
        )
        
        // Fallback: try without subdirectory (for test bundles)
        if url == nil {
            url = Bundle.main.url(
                forResource: currentLanguage.code,
                withExtension: "json"
            )
        }
        
        guard let fileURL = url,
              let data = try? Data(contentsOf: fileURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // Only log warning if not in test environment
            #if !DEBUG
            print("⚠️ Failed to load translations for \(currentLanguage.code)")
            #endif
            translations = [:] // Use empty translations as fallback
            return
        }
        translations = json
    }
    
    /// Get localized string using dot-notation key path (e.g., "visualiser.title")
    public func string(forKey keyPath: String) -> String {
        let components = keyPath.split(separator: ".").map(String.init)
        var current: Any? = translations
        
        for component in components {
            guard let dict = current as? [String: Any] else {
                return keyPath // Return key if path not found
            }
            current = dict[component]
        }
        
        return (current as? String) ?? keyPath
    }
    
    /// Convenience subscript for accessing translations
    public subscript(keyPath: String) -> String {
        string(forKey: keyPath)
    }
}

/// Extension for common localisation key paths as static properties
extension LocalisationManager {
    // Visualiser keys
    public static let visualiserTitle = "visualiser.title"
    public static let audioVisualiser = "visualiser.audioVisualiser"
    public static let visualiserSettings = "visualiser.settings"
    
    // Visualisation mode keys
    public static let discreteFrequencies = "visualisation.modes.discreteFrequencies"
    public static let radialSpectrum = "visualisation.modes.radialSpectrum"
    public static let dualChannelGraph = "visualisation.modes.dualChannelGraph"
    public static let ledBars = "visualisation.modes.ledBars"
    public static let lumiBars = "visualisation.modes.lumiBars"
    public static let roundBarsReflex = "visualisation.modes.roundBarsReflex"
    
    // Player control keys
    public static let play = "player.controls.play"
    public static let pause = "player.controls.pause"
    public static let stop = "player.controls.stop"
    public static let previous = "player.controls.previous"
    public static let next = "player.controls.next"
    public static let shuffle = "player.controls.shuffle"
    public static let `repeat` = "player.controls.repeat"
    public static let repeatOne = "player.controls.repeatOne"
    public static let repeatAll = "player.controls.repeatAll"
    public static let volume = "player.controls.volume"
    public static let mute = "player.controls.mute"
    public static let unmute = "player.controls.unmute"
    
    // Track info keys
    public static let noTrackSelected = "player.track.noTrackSelected"
    public static let nowPlaying = "player.track.nowPlaying"
    public static let currentTrack = "player.track.currentTrack"
    public static let trackTitle = "player.track.title"
    public static let artist = "player.track.artist"
    public static let album = "player.track.album"
    public static let duration = "player.track.duration"
    
    // Settings keys
    public static let settings = "settings.title"
    public static let general = "settings.categories.general"
    public static let audio = "settings.categories.audio"
    public static let playback = "settings.categories.playback"
    public static let appearance = "settings.categories.appearance"
    public static let advanced = "settings.categories.advanced"
    public static let language = "settings.categories.language"
    public static let theme = "settings.theme"
    public static let scrollSpeed = "settings.scrollSpeed"
    public static let trackInfoScrollSpeed = "settings.trackInfoScrollSpeed"
    
    // Action keys
    public static let minimise = "actions.minimise"
    public static let restore = "actions.restore"
    public static let close = "actions.close"
    public static let save = "actions.save"
    public static let cancel = "actions.cancel"
    public static let reset = "actions.reset"
    public static let apply = "actions.apply"
    
    // Message keys
    public static let loading = "messages.loading"
    public static let error = "messages.error"
    public static let success = "messages.success"
    public static let warning = "messages.warning"
    
    // Playlist keys
    public static let newPlaylist = "playlist.newPlaylist"
    public static let newSmartPlaylist = "playlist.newSmartPlaylist"
    public static let playlistName = "playlist.playlistName"
    public static let enterPlaylistName = "playlist.enterPlaylistName"
    public static let create = "playlist.create"
    public static let createSmartPlaylist = "playlist.createSmartPlaylist"
    public static let rules = "playlist.rules"
    public static let addRule = "playlist.addRule"
    public static let editRule = "playlist.editRule"
    public static let noRules = "playlist.noRules"
    public static let addRulesToCreateSmartPlaylist = "playlist.addRulesToCreateSmartPlaylist"
    public static let playlistCreationError = "playlist.creationError"
    public static let smartPlaylistCreationError = "playlist.smartPlaylistCreationError"
}
