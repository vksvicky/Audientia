//
//  TabItem.swift
//  Audientia
//
//  Tab items for the main window navigation tabs
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import SwiftUI

/// Represents the main navigation tabs in the application
public enum TabItem: String, CaseIterable, Identifiable, Hashable {
    case home
    case library
    case playlists
    case devices
    case visualiser
    
    public var id: String { rawValue }
    
    /// Display name shown in the tab bar
    public var displayName: String {
        switch self {
        case .home: return "Home"
        case .library: return "Library"
        case .playlists: return "Playlists"
        case .devices: return "Devices"
        case .visualiser: return "Visualiser"
        }
    }
    
    /// SF Symbol icon name for the tab
    public var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .library: return "books.vertical.fill"
        case .playlists: return "list.bullet.rectangle.fill"
        case .devices: return "iphone"
        case .visualiser: return "waveform"
        }
    }
    
    /// Keyboard shortcut number (⌘1, ⌘2, etc.)
    public var keyboardShortcutNumber: Int {
        switch self {
        case .home: return 1
        case .library: return 2
        case .playlists: return 3
        case .devices: return 4
        case .visualiser: return 5
        }
    }
    
    /// Keyboard shortcut key equivalent
    public var keyEquivalent: KeyEquivalent {
        KeyEquivalent(Character("\(keyboardShortcutNumber)"))
    }
    
    /// Search placeholder text for the contextual sidebar
    public var searchPlaceholder: String {
        switch self {
        case .home: return "Search..."
        case .library: return "Search library..."
        case .playlists: return "Search playlists..."
        case .devices: return "Search devices..."
        case .visualiser: return "Search..."
        }
    }
}
