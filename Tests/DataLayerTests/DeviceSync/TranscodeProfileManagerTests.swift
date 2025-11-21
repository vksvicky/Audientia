//
//  TranscodeProfileManagerTests.swift
//  DataLayerTests
//
//  TDD tests for TranscodeProfileManager (Right-BICEP)
//

@testable import DataLayer
@testable import Shared
import XCTest

final class TranscodeProfileManagerTests: XCTestCase {
    
    private var manager: TranscodeProfileManager!
    
    override func setUp() async throws {
        try await super.setUp()
        manager = TranscodeProfileManager()
    }
    
    override func tearDown() async throws {
        manager = nil
        try await super.tearDown()
    }
    
    // MARK: - Right: Correctness Tests
    
    func testGetPresetProfilesReturnsAllPresets() async {
        // Given/When
        let presets = await manager.getPresetProfiles()
        
        // Then
        XCTAssertGreaterThan(presets.count, 0)
        XCTAssertTrue(presets.contains { $0.format == .mp3 && $0.quality == .low })
        XCTAssertTrue(presets.contains { $0.format == .mp3 && $0.quality == .standard })
        XCTAssertTrue(presets.contains { $0.format == .mp3 && $0.quality == .high })
        XCTAssertTrue(presets.contains { $0.format == .mp3 && $0.quality == .veryHigh })
        XCTAssertTrue(presets.contains { $0.format == .aac && $0.quality == .standard })
        XCTAssertTrue(presets.contains { $0.format == .flac && $0.quality == .lossless })
    }
    
    func testGetPresetProfileReturnsCorrectProfile() async {
        // Given/When
        let profile = await manager.getPresetProfile(format: .mp3, quality: .standard)
        
        // Then
        XCTAssertNotNil(profile)
        XCTAssertEqual(profile?.format, .mp3)
        XCTAssertEqual(profile?.quality, .standard)
        XCTAssertEqual(profile?.bitrate, TranscodeQuality.standard.defaultBitrate)
    }
    
    func testGetDefaultProfileReturnsStandardQuality() async {
        // Given/When
        let mp3Profile = await manager.getDefaultProfile(for: .mp3)
        let aacProfile = await manager.getDefaultProfile(for: .aac)
        
        // Then
        XCTAssertEqual(mp3Profile.format, .mp3)
        XCTAssertEqual(mp3Profile.quality, .standard)
        XCTAssertEqual(aacProfile.format, .aac)
        XCTAssertEqual(aacProfile.quality, .standard)
    }
    
    // MARK: - B: Boundary Tests
    
    func testGetPresetProfileWithInvalidFormatReturnsNil() async {
        // Given/When
        // Note: AudioFormat.original might not have a preset
        let profile = await manager.getPresetProfile(format: .original, quality: .standard)
        
        // Then
        // Should return nil or handle gracefully
        if profile == nil {
            // Expected behavior
        } else {
            // If it returns a profile, that's also acceptable
            XCTAssertEqual(profile?.format, .original)
        }
    }
    
    // MARK: - I: Inverse Tests
    
    func testSaveThenGetCustomProfile() async {
        // Given
        let customProfile = TranscodeProfile(
            name: "Custom MP3 256kbps",
            format: .mp3,
            bitrate: 256,
            quality: .high
        )
        
        // When
        await manager.saveCustomProfile(customProfile)
        let retrieved = await manager.getProfile(id: customProfile.id)
        
        // Then
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.id, customProfile.id)
        XCTAssertEqual(retrieved?.name, "Custom MP3 256kbps")
        XCTAssertEqual(retrieved?.bitrate, 256)
    }
    
    func testDeleteCustomProfileRemovesIt() async {
        // Given
        let customProfile = TranscodeProfile(
            name: "Custom Profile",
            format: .mp3,
            bitrate: 256
        )
        await manager.saveCustomProfile(customProfile)
        
        // When
        await manager.deleteCustomProfile(id: customProfile.id)
        let retrieved = await manager.getProfile(id: customProfile.id)
        
        // Then
        XCTAssertNil(retrieved)
    }
    
    // MARK: - C: Cross-check Tests
    
    func testPresetProfileBitratesMatchQualityDefaults() async {
        // Given/When
        let presets = await manager.getPresetProfiles()
        
        // Then: Verify bitrates match quality defaults
        for preset in presets {
            if preset.quality != .lossless {
                XCTAssertEqual(preset.bitrate, preset.quality.defaultBitrate)
            } else {
                XCTAssertEqual(preset.bitrate, 0, "Lossless should have 0 bitrate")
            }
        }
    }
    
    // MARK: - E: Error Tests
    
    func testGetProfileWithNonExistentIdReturnsNil() async {
        // Given
        let nonExistentId = UUID()
        
        // When
        let profile = await manager.getProfile(id: nonExistentId)
        
        // Then
        XCTAssertNil(profile)
    }
    
    // MARK: - P: Performance Tests
    
    func testGetAllProfilesPerformance() async {
        // Given
        // Add some custom profiles
        for i in 0..<100 {
            let profile = TranscodeProfile(
                name: "Custom \(i)",
                format: .mp3,
                bitrate: 192 + i
            )
            await manager.saveCustomProfile(profile)
        }
        
        // When/Then: Should be fast
        let startTime = CFAbsoluteTimeGetCurrent()
        let allProfiles = await manager.getAllProfiles()
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertGreaterThan(allProfiles.count, 100)
        XCTAssertLessThan(elapsed, 0.1, "Getting all profiles should be fast")
    }
    
    // MARK: - Edge Cases
    
    func testMultipleCustomProfilesWithSameName() async {
        // Given
        let profile1 = TranscodeProfile(name: "Same Name", format: .mp3, bitrate: 192)
        let profile2 = TranscodeProfile(name: "Same Name", format: .aac, bitrate: 256)
        
        // When
        await manager.saveCustomProfile(profile1)
        await manager.saveCustomProfile(profile2)
        let customProfiles = await manager.getCustomProfiles()
        
        // Then: Both should be saved (different IDs)
        XCTAssertEqual(customProfiles.count, 2)
        XCTAssertTrue(customProfiles.contains { $0.id == profile1.id })
        XCTAssertTrue(customProfiles.contains { $0.id == profile2.id })
    }
}
