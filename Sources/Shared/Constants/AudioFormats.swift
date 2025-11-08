//
//  AudioFormats.swift
//  Shared
//
//  Shared constants for supported audio file formats
//  This is the single source of truth for audio format definitions
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

/// Audio format constants - single source of truth for supported formats
public enum AudioFormats {
    
    /// All supported audio file extensions (complete list)
    /// Total: 20 formats
    public static let allSupportedExtensions: Set<String> = [
        "mp3", "flac", "aac", "wav", "m4a", "ogg", "opus", "alac", "ape",
        "aiff", "caf", "mp4", "wma", "webm", "flv", "ac3", "dts", "dsf", "dff", "wv"
    ]
    
    /// AVFoundation-supported audio file extensions
    /// Formats: MP3, AAC, M4A, MP4, WAV, AIFF, CAF, WMA
    public static let avFoundationSupportedExtensions: Set<String> = [
        "aac", "aiff", "caf", "m4a", "mp3", "mp4", "wav", "wma"
    ]
    
    /// FFmpeg-supported audio file extensions
    /// Formats: FLAC, OGG, Opus, ALAC, APE, WebM, FLV, AC3, DTS, WavPack, DSD
    public static let ffmpegSupportedExtensions: Set<String> = [
        "flac", "ogg", "opus", "alac", "ape", "webm", "flv", "ac3", "dts", "wv", "dsf", "dff"
    ]
    
    /// Array version of all supported extensions (for iteration in tests)
    public static let allSupportedExtensionsArray: [String] = Array(allSupportedExtensions).sorted()
    
    /// Check if a file extension is supported
    /// - Parameter extension: File extension (with or without leading dot)
    /// - Returns: True if the extension is supported
    public static func isSupported(_ extension: String) -> Bool {
        let ext = `extension`.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        return allSupportedExtensions.contains(ext)
    }
}
