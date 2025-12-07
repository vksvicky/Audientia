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
    public static let playlistTitle = "playlist.title"
    public static let newPlaylist = "playlist.newPlaylist"
    public static let newSmartPlaylist = "playlist.newSmartPlaylist"
    public static let playlistName = "playlist.playlistName"
    public static let enterPlaylistName = "playlist.enterPlaylistName"
    public static let create = "playlist.create"
    public static let createPlaylist = "playlist.createPlaylist"
    public static let createSmartPlaylist = "playlist.createSmartPlaylist"
    public static let rules = "playlist.rules"
    public static let addRule = "playlist.addRule"
    public static let editRule = "playlist.editRule"
    public static let noRules = "playlist.noRules"
    public static let addRulesToCreate = "playlist.addRulesToCreate"
    public static let addRulesToCreateSmartPlaylist = "playlist.addRulesToCreateSmartPlaylist"
    public static let playlistCreationError = "playlist.creationError"
    public static let smartPlaylistCreationError = "playlist.smartPlaylistCreationError"
    public static let smartPlaylistRules = "playlist.smartPlaylistRules"
    public static let clearAll = "playlist.clearAll"
    public static let playlistLoading = "playlist.loading"
    public static let noPlaylists = "playlist.noPlaylists"
    public static let createFirstPlaylist = "playlist.createFirstPlaylist"
    public static let rename = "playlist.rename"
    public static let delete = "playlist.delete"
    public static let field = "playlist.field"
    public static let `operator` = "playlist.operator"
    public static let value = "playlist.value"
    public static let logicalOperator = "playlist.logicalOperator"
    public static let and = "playlist.and"
    public static let or = "playlist.or"
    public static let none = "playlist.none"
    public static let updateRule = "playlist.updateRule"
    public static let enterSmartPlaylistName = "playlist.enterSmartPlaylistName"
    public static let invalidPlaylistName = "playlist.errors.invalidPlaylistName"
    public static let duplicatePlaylist = "playlist.errors.duplicatePlaylist"
    public static let playlistNotFound = "playlist.errors.playlistNotFound"
    public static let trackNotFound = "playlist.errors.trackNotFound"
    public static let duplicateTrack = "playlist.errors.duplicateTrack"
    public static let invalidRules = "playlist.errors.invalidRules"
    public static let operationFailed = "playlist.errors.operationFailed"
    
    // Language keys
    public static let languageSelection = "language.selection"
    public static let languageDescription = "language.description"
    public static let languagePreview = "language.preview"
    
    // Home keys
    public static let welcome = "home.welcome"
    public static let subtitle = "home.subtitle"
    public static let getStarted = "home.getStarted"
    public static let whatsNew = "home.whatsNew"
    public static let introduction = "home.introduction"
    public static let addFiles = "home.addFiles"
    public static let playFiles = "home.playFiles"
    public static let updateFiles = "home.updateFiles"
    public static let syncFiles = "home.syncFiles"
    public static let recentlyPlayed = "home.recentlyPlayed"
    public static let noRecentlyPlayed = "home.noRecentlyPlayed"
    public static let recentlyAdded = "home.recentlyAdded"
    public static let noRecentlyAdded = "home.noRecentlyAdded"
    public static let mostPlayed = "home.mostPlayed"
    public static let noMostPlayed = "home.noMostPlayed"
    public static let favourites = "home.favourites"
    public static let noFavourites = "home.noFavourites"
    public static let homeAlbum = "home.album"
    
    // Track Details keys
    public static let selectTrack = "trackDetails.selectTrack"
    public static let chooseTrack = "trackDetails.chooseTrack"
    public static let summary = "trackDetails.summary"
    public static let trackDetailsAudio = "trackDetails.audio"
    public static let file = "trackDetails.file"
    public static let insights = "trackDetails.insights"
    public static let loadingMetadata = "trackDetails.loadingMetadata"
    
    // Metadata Lookup keys
    public static let metadataLookupTitle = "metadataLookup.title"
    public static let lookupMetadata = "metadataLookup.lookupMetadata"
    public static let applySelection = "metadataLookup.applySelection"
    public static let mergeStrategy = "metadataLookup.mergeStrategy"
    public static let fillMissing = "metadataLookup.fillMissing"
    public static let highestConfidence = "metadataLookup.highestConfidence"
    public static let mostComplete = "metadataLookup.mostComplete"
    public static let conservative = "metadataLookup.conservative"
    public static let matches = "metadataLookup.matches"
    public static let noMatches = "metadataLookup.noMatches"
    public static let confidence = "metadataLookup.confidence"
    
    // Settings keys (additional)
    public static let library = "settings.categories.library"
    public static let startup = "settings.startup.title"
    public static let showSplashScreen = "settings.startup.showSplashScreen"
    public static let showSplashScreenHelp = "settings.startup.showSplashScreenHelp"
    public static let notifications = "settings.notifications.title"
    public static let notificationStatus = "settings.notifications.status"
    public static let notificationDescription = "settings.notifications.description"
    public static let requestPermission = "settings.notifications.requestPermission"
    public static let openSystemSettings = "settings.notifications.openSystemSettings"
    public static let window = "settings.window.title"
    public static let windowManagementSettings = "settings.window.managementSettings"
    public static let libraryViewSettings = "settings.library.viewSettings"
    public static let trackInfoDisplay = "settings.playback.trackInfoDisplay"
    public static let longTrackTitlesScroll = "settings.playback.longTrackTitlesScroll"
    public static let adjustScrollSpeed = "settings.playback.adjustScrollSpeed"
    public static let pxPerSecond = "settings.playback.pxPerSecond"
    public static let themeSettings = "settings.appearance.themeSettings"
    public static let resetAllSettings = "settings.advanced.resetAllSettings"
    
    // About keys
    public static let modulesAndPlugins = "about.modulesAndPlugins"
    
    // Device Sync keys
    public static let startSync = "deviceSync.startSync"
    public static let transcodingSettings = "deviceSync.transcodingSettings"
    public static let transcodingProgress = "deviceSync.transcodingProgress"
    public static let reloadJobs = "deviceSync.reloadJobs"
    public static let reloadTracks = "deviceSync.reloadTracks"
    public static let loadingTracks = "deviceSync.loadingTracks"
    public static let noTracksAvailable = "deviceSync.noTracksAvailable"
    public static let tracksReadyForSync = "deviceSync.tracksReadyForSync"
    
    // Scan Results keys
    public static let scanResultsTitle = "scanResults.title"
    public static let searchAndUpdateTook = "scanResults.searchAndUpdateTook"
    public static let addedNewFiles = "scanResults.addedNewFiles"
    public static let newFiles = "scanResults.newFiles"
    public static let updatedFiles = "scanResults.updatedFiles"
    public static let files = "scanResults.files"
    public static let failedToAdd = "scanResults.failedToAdd"
    public static let skippedFiles = "scanResults.skippedFiles"
    public static let filesFilteredOrDisabled = "scanResults.filesFilteredOrDisabled"
    public static let librarySettings = "scanResults.librarySettings"
    public static let dontShowAgain = "scanResults.dontShowAgain"
    public static let scanResultsClose = "scanResults.close"
    
    // Layout keys
    public static let layoutMode = "layout.layoutMode"
    public static let panelVisibility = "layout.panelVisibility"
    public static let panelSizes = "layout.panelSizes"
    public static let points = "layout.points"
    public static let saveLayout = "layout.saveLayout"
    public static let resetToDefaults = "layout.resetToDefaults"
    public static let horizontalSplit = "layout.horizontalSplit"
    public static let verticalSplit = "layout.verticalSplit"
    public static let tabbed = "layout.tabbed"
    public static let floating = "layout.floating"
    public static let layoutSuccess = "layout.success"
    
    // Playlist additional keys (duplicates removed - using keys from above)
    public static let enterPlaylistNamePlaceholder = "playlist.enterPlaylistName"
    public static let deleteConfirmation = "playlist.deleteConfirmation"
    
    // Theme keys
    public static let themeTheme = "theme.theme"
    public static let resetToDefault = "theme.resetToDefault"
    
    // Batch Tag keys
    public static let batchTagOperations = "batchTag.title"
    
    // Dependencies keys
    public static let missingRequiredDependencies = "dependencies.missingRequired"
    public static let openInstallationInstructions = "dependencies.openInstallationInstructions"
    public static let installingDependencies = "dependencies.installingDependencies"
    
    // Smart Playlist keys
    public static let fieldTitle = "smartPlaylist.fieldTitle"
    public static let fieldArtist = "smartPlaylist.fieldArtist"
    public static let fieldAlbum = "smartPlaylist.fieldAlbum"
    public static let fieldGenre = "smartPlaylist.fieldGenre"
    public static let fieldYear = "smartPlaylist.fieldYear"
    public static let fieldRating = "smartPlaylist.fieldRating"
    public static let fieldPlayCount = "smartPlaylist.fieldPlayCount"
    public static let fieldDateAdded = "smartPlaylist.fieldDateAdded"
    public static let fieldDuration = "smartPlaylist.fieldDuration"
    public static let operatorEquals = "smartPlaylist.operatorEquals"
    public static let operatorContains = "smartPlaylist.operatorContains"
    public static let operatorStartsWith = "smartPlaylist.operatorStartsWith"
    public static let operatorEndsWith = "smartPlaylist.operatorEndsWith"
    public static let operatorGreaterThan = "smartPlaylist.operatorGreaterThan"
    public static let operatorLessThan = "smartPlaylist.operatorLessThan"
    public static let operatorGreaterThanOrEqual = "smartPlaylist.operatorGreaterThanOrEqual"
    public static let operatorLessThanOrEqual = "smartPlaylist.operatorLessThanOrEqual"
    public static let operatorNotEquals = "smartPlaylist.operatorNotEquals"
    public static let logicalAnd = "smartPlaylist.logicalAnd"
    public static let logicalOr = "smartPlaylist.logicalOr"
}
