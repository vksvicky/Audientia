// Logger.swift
// Audientia - Unified Logging System
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import Foundation
import os.log

/// Unified logging system for Audientia using Apple's OSLog
public extension Logger {
    private static var subsystem: String {
        Bundle.main.bundleIdentifier ?? "club.cycleruncode.audientia"
    }

    /// Audio engine and playback logging
    static let audio = Logger(subsystem: subsystem, category: "audio")

    /// Metadata parsing and tagging logging
    static let metadata = Logger(subsystem: subsystem, category: "metadata")

    /// Data layer and persistence logging
    static let dataLayer = Logger(subsystem: subsystem, category: "datalayer")

    /// UI and SwiftUI logging
    static let userInterface = Logger(subsystem: subsystem, category: "ui")

    /// Plugin system logging
    static let plugin = Logger(subsystem: subsystem, category: "plugin")

    /// Shared models and utilities logging
    static let shared = Logger(subsystem: subsystem, category: "shared")

    /// Testing and test infrastructure logging
    static let testing = Logger(subsystem: subsystem, category: "testing")
}
