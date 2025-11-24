//
//  LibraryViewConfiguration.swift
//  Audientia
//
//  Library view configuration models
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

/// Library view mode
public enum LibraryViewMode: String, Codable, CaseIterable, Sendable {
    case list
    case grid
    case compact
}

/// Library grouping option
public enum LibraryGrouping: String, Codable, CaseIterable, Sendable {
    case none
    case artist
    case album
    case genre
    case year
    case rating
}

/// Library sort order
public enum LibrarySortOrder: String, Codable, CaseIterable, Sendable {
    case title
    case artist
    case album
    case year
    case rating
    case duration
    case dateAdded
}

/// Library sort direction
public enum LibrarySortDirection: String, Codable, Sendable {
    case ascending
    case descending
}

/// Library view configuration
public struct LibraryViewConfiguration: Codable, Equatable, Sendable {
    public var viewMode: LibraryViewMode
    public var grouping: LibraryGrouping
    public var sortOrder: LibrarySortOrder
    public var sortDirection: LibrarySortDirection
    public var visibleColumns: Set<String>
    
    public static let `default` = LibraryViewConfiguration(
        viewMode: .list,
        grouping: .none,
        sortOrder: .title,
        sortDirection: .ascending,
        visibleColumns: ["title", "artist", "album", "duration"]
    )
    
    public init(
        viewMode: LibraryViewMode = .list,
        grouping: LibraryGrouping = .none,
        sortOrder: LibrarySortOrder = .title,
        sortDirection: LibrarySortDirection = .ascending,
        visibleColumns: Set<String> = ["title", "artist", "album", "duration"]
    ) {
        self.viewMode = viewMode
        self.grouping = grouping
        self.sortOrder = sortOrder
        self.sortDirection = sortDirection
        self.visibleColumns = visibleColumns
    }
}

/// Library view configuration manager protocol
public protocol LibraryViewConfigurationManagerProtocol: Sendable {
    func saveConfiguration(_ config: LibraryViewConfiguration) async throws
    func loadConfiguration() async -> LibraryViewConfiguration
    func resetToDefault() async throws
}

/// Library view configuration manager with persistence
public actor LibraryViewConfigurationManager: LibraryViewConfigurationManagerProtocol {
    private let storage: any SettingsStorageProtocol
    private let configKey = "library.view.configuration"
    
    public init(storage: any SettingsStorageProtocol = UserDefaultsSettingsStorage()) {
        self.storage = storage
    }
    
    public func saveConfiguration(_ config: LibraryViewConfiguration) async throws {
        try await storage.save(config, forKey: configKey)
    }
    
    public func loadConfiguration() async -> LibraryViewConfiguration {
        guard let config = try? await storage.load(LibraryViewConfiguration.self, forKey: configKey) else {
            return LibraryViewConfiguration.default
        }
        return config
    }
    
    public func resetToDefault() async throws {
        try await saveConfiguration(.default)
    }
}
