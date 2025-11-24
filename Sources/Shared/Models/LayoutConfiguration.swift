//
//  LayoutConfiguration.swift
//  Audientia
//
//  Layout configuration models for multi-pane UI
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import CoreGraphics
import Foundation

/// Layout panel identifier
public enum LayoutPanel: String, Codable, CaseIterable, Hashable, Sendable {
    case libraryBrowser
    case playlistPanel
    case nowPlaying
    case trackDetails
}

/// Layout configuration for multi-pane interface
public struct LayoutConfiguration: Codable, Equatable, Sendable {
    /// Panel visibility
    public var panelVisibility: [LayoutPanel: Bool]
    
    /// Panel sizes (width or height in points)
    public var panelSizes: [LayoutPanel: CGFloat]
    
    /// Panel positions (for floating panels)
    public var panelPositions: [LayoutPanel: CGPoint]
    
    /// Layout mode (horizontal split, vertical split, etc.)
    public var layoutMode: LayoutMode
    
    /// Default layout configuration
    public static let `default` = LayoutConfiguration(
        panelVisibility: [
            .libraryBrowser: true,
            .playlistPanel: true,
            .nowPlaying: true,
            .trackDetails: false
        ],
        panelSizes: [
            .libraryBrowser: 300,
            .playlistPanel: 250,
            .nowPlaying: 200,
            .trackDetails: 300
        ],
        panelPositions: [:],
        layoutMode: .horizontalSplit
    )
    
    public init(
        panelVisibility: [LayoutPanel: Bool] = LayoutConfiguration.default.panelVisibility,
        panelSizes: [LayoutPanel: CGFloat] = LayoutConfiguration.default.panelSizes,
        panelPositions: [LayoutPanel: CGPoint] = [:],
        layoutMode: LayoutMode = .horizontalSplit
    ) {
        self.panelVisibility = panelVisibility
        self.panelSizes = panelSizes
        self.panelPositions = panelPositions
        self.layoutMode = layoutMode
    }
}

/// Layout mode for panel arrangement
public enum LayoutMode: String, Codable, CaseIterable, Sendable {
    case horizontalSplit
    case verticalSplit
    case tabbed
    case floating
}

public extension LayoutPanel {
    var displayName: String {
        switch self {
        case .libraryBrowser:
            return "Library Browser"
        case .playlistPanel:
            return "Playlist Panel"
        case .nowPlaying:
            return "Now Playing"
        case .trackDetails:
            return "Track Details"
        }
    }
}
