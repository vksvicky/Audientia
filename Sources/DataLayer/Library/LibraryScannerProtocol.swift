//
//  LibraryScannerProtocol.swift
//  DataLayer
//
//  Protocol for library scanning functionality
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Protocol for scanning directories and finding audio files
public protocol LibraryScannerProtocol: Sendable {
    /// Scan a directory for audio files
    /// - Parameter directory: The directory to scan
    /// - Returns: Array of Track objects representing found audio files
    /// - Throws: Error if scanning fails
    func scan(directory: URL) async throws -> [Track]
}
