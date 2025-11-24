//
//  ThemeConfiguration.swift
//  Audientia
//
//  Theme configuration models
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import SwiftUI

/// Theme identifier
public enum ThemeIdentifier: String, Codable, CaseIterable, Hashable, Sendable {
    case light
    case dark
    case auto
    case custom
}

/// Theme color scheme
public struct ThemeColorScheme: Codable, Equatable, Hashable, Sendable {
    public var primary: String // Hex color
    public var secondary: String
    public var background: String
    public var foreground: String
    public var accent: String
    
    public static let light = ThemeColorScheme(
        primary: "#000000",
        secondary: "#666666",
        background: "#FFFFFF",
        foreground: "#000000",
        accent: "#007AFF"
    )
    
    public static let dark = ThemeColorScheme(
        primary: "#FFFFFF",
        secondary: "#999999",
        background: "#1C1C1E",
        foreground: "#FFFFFF",
        accent: "#0A84FF"
    )
    
    public init(
        primary: String,
        secondary: String,
        background: String,
        foreground: String,
        accent: String
    ) {
        self.primary = primary
        self.secondary = secondary
        self.background = background
        self.foreground = foreground
        self.accent = accent
    }
}

/// Theme configuration
public struct ThemeConfiguration: Codable, Equatable, Hashable, Sendable {
    public var identifier: ThemeIdentifier
    public var colorScheme: ThemeColorScheme?
    public var name: String
    
    public static let light = ThemeConfiguration(
        identifier: .light,
        colorScheme: .light,
        name: "Light"
    )
    
    public static let dark = ThemeConfiguration(
        identifier: .dark,
        colorScheme: .dark,
        name: "Dark"
    )
    
    public static let auto = ThemeConfiguration(
        identifier: .auto,
        colorScheme: nil,
        name: "Auto"
    )
    
    public init(
        identifier: ThemeIdentifier,
        colorScheme: ThemeColorScheme? = nil,
        name: String
    ) {
        self.identifier = identifier
        self.colorScheme = colorScheme
        self.name = name
    }
}
