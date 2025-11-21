//
//  TranscodeProfileManager.swift
//  DataLayer
//
//  Transcode profile management with quality presets
//

import Foundation
import Shared

/// Manages transcoding profiles and quality presets
public actor TranscodeProfileManager {
    
    private var customProfiles: [UUID: TranscodeProfile] = [:]
    
    public init() {}
    
    // MARK: - Preset Profiles
    
    /// Get all available preset profiles
    public func getPresetProfiles() -> [TranscodeProfile] {
        var profiles: [TranscodeProfile] = []
        profiles.append(contentsOf: getMP3Presets())
        profiles.append(contentsOf: getAACPresets())
        profiles.append(getFLACPreset())
        return profiles
    }
    
    private func getMP3Presets() -> [TranscodeProfile] {
        [
            TranscodeProfile(
                name: "MP3 - Low Quality",
                format: .mp3,
                bitrate: TranscodeQuality.low.defaultBitrate,
                quality: .low
            ),
            TranscodeProfile(
                name: "MP3 - Standard Quality",
                format: .mp3,
                bitrate: TranscodeQuality.standard.defaultBitrate,
                quality: .standard
            ),
            TranscodeProfile(
                name: "MP3 - High Quality",
                format: .mp3,
                bitrate: TranscodeQuality.high.defaultBitrate,
                quality: .high
            ),
            TranscodeProfile(
                name: "MP3 - Very High Quality",
                format: .mp3,
                bitrate: TranscodeQuality.veryHigh.defaultBitrate,
                quality: .veryHigh
            )
        ]
    }
    
    private func getAACPresets() -> [TranscodeProfile] {
        [
            TranscodeProfile(
                name: "AAC - Low Quality",
                format: .aac,
                bitrate: TranscodeQuality.low.defaultBitrate,
                quality: .low
            ),
            TranscodeProfile(
                name: "AAC - Standard Quality",
                format: .aac,
                bitrate: TranscodeQuality.standard.defaultBitrate,
                quality: .standard
            ),
            TranscodeProfile(
                name: "AAC - High Quality",
                format: .aac,
                bitrate: TranscodeQuality.high.defaultBitrate,
                quality: .high
            ),
            TranscodeProfile(
                name: "AAC - Very High Quality",
                format: .aac,
                bitrate: TranscodeQuality.veryHigh.defaultBitrate,
                quality: .veryHigh
            )
        ]
    }
    
    private func getFLACPreset() -> TranscodeProfile {
        TranscodeProfile(
            name: "FLAC - Lossless",
            format: .flac,
            bitrate: 0, // Lossless has no bitrate
            quality: .lossless
        )
    }
    
    /// Get preset profile by quality and format
    public func getPresetProfile(format: AudioFormat, quality: TranscodeQuality) -> TranscodeProfile? {
        getPresetProfiles().first { profile in
            profile.format == format && profile.quality == quality
        }
    }
    
    /// Get default profile for a format (standard quality)
    public func getDefaultProfile(for format: AudioFormat) -> TranscodeProfile {
        getPresetProfile(format: format, quality: .standard) ?? TranscodeProfile(
            name: "\(format.rawValue.uppercased()) - Standard",
            format: format,
            bitrate: TranscodeQuality.standard.defaultBitrate,
            quality: .standard
        )
    }
    
    // MARK: - Custom Profiles
    
    /// Save a custom profile
    public func saveCustomProfile(_ profile: TranscodeProfile) {
        customProfiles[profile.id] = profile
    }
    
    /// Get all custom profiles
    public func getCustomProfiles() -> [TranscodeProfile] {
        Array(customProfiles.values)
    }
    
    /// Get profile by ID (preset or custom)
    public func getProfile(id: UUID) -> TranscodeProfile? {
        // Check custom profiles first
        if let custom = customProfiles[id] {
            return custom
        }
        
        // Check preset profiles
        return getPresetProfiles().first { $0.id == id }
    }
    
    /// Delete a custom profile
    public func deleteCustomProfile(id: UUID) {
        customProfiles.removeValue(forKey: id)
    }
    
    /// Get all profiles (presets + custom)
    public func getAllProfiles() -> [TranscodeProfile] {
        getPresetProfiles() + getCustomProfiles()
    }
}
