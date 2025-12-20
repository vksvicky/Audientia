//
//  KeyboardNavigationElement.swift
//  Audientia
//
//  Specific keyboard navigation elements within each section
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

// TabItem and Shared are in the same module, no import needed

/// Specific elements that can receive keyboard focus
public enum KeyboardNavigationElement: Hashable {
    // Toolbar elements
    case toolbarTab(TabItem)
    case toolbarCollapse
    
    // Sidebar elements
    case sidebarSearch
    case sidebarNavItem(String) // Navigation item identifier
    case sidebarAction(String) // Action button identifier
    case sidebarRadio(String) // Radio button identifier
    
    // Content elements
    case contentTrack(index: Int)
    case contentPlaylist(index: Int)
    case contentDevice(index: Int)
    case contentVisualisation
    
    // Player elements
    case playerPrevious
    case playerPlayPause
    case playerStop
    case playerNext
    case playerShuffle
    case playerLoop
    case playerVolume
    case playerCollapse
    
    /// The section this element belongs to
    public var section: KeyboardNavigationSection {
        switch self {
        case .toolbarTab, .toolbarCollapse:
            return .toolbar
        case .sidebarSearch, .sidebarNavItem, .sidebarAction, .sidebarRadio:
            return .sidebar
        case .contentTrack, .contentPlaylist, .contentDevice, .contentVisualisation:
            return .content
        case .playerPrevious, .playerPlayPause, .playerStop, .playerNext,
             .playerShuffle, .playerLoop, .playerVolume, .playerCollapse:
            return .player
        }
    }
}
