//
//  NavigationItem.swift
//  Audientia
//
//  Navigation items for the main window sidebar
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

enum NavigationItem: String, CaseIterable {
    case home
    case playing
    case entireLibrary
    case music
    case playlists
    case devices
    case folders
    case web
    case pinned
    
    var displayName: String {
        switch self {
        case .home: return "Home"
        case .playing: return "Playing"
        case .entireLibrary: return "Entire Library"
        case .music: return "Music"
        case .playlists: return "Playlists"
        case .devices: return "Devices & Services"
        case .folders: return "Folders"
        case .web: return "Web"
        case .pinned: return "Pinned"
        }
    }
    
    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .playing: return "music.note"
        case .entireLibrary: return "building.2.fill"
        case .music: return "headphones"
        case .playlists: return "list.bullet"
        case .devices: return "iphone"
        case .folders: return "folder.fill"
        case .web: return "globe"
        case .pinned: return "pin.fill"
        }
    }
}
