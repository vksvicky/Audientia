//
//  AudioFileDialog.swift
//  AppKitBridge
//
//  File dialog for selecting audio files
//

import AppKit
import Foundation
import Shared
import UniformTypeIdentifiers

/// File dialog for selecting audio files
@MainActor
public final class AudioFileDialog {
    /// Show open panel for audio files
    /// - Parameter allowsMultipleSelection: Whether to allow multiple file selection
    /// - Returns: Array of selected file URLs, or empty array if cancelled
    public static func showOpenPanel(allowsMultipleSelection: Bool = true) -> [URL] {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = allowsMultipleSelection
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = AudioFormats.allSupportedExtensions.compactMap { ext in
            UTType(filenameExtension: ext)
        }

        let response = panel.runModal()
        if response == .OK {
            return panel.urls
        }
        return []
    }
}

