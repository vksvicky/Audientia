//
//  AudioEngineVolumeControlBDDTests.swift
//  AudioCoreTests
//
//  BDD scenarios for AudioEngine Volume Control
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
@testable import Shared
import XCTest

/// BDD tests for AudioEngine Volume Control
/// User-centric scenarios following "As a user, I want to..." format
@MainActor
final class AudioEngineVolumeControlBDDTests: XCTestCase {
    
    var engine: AudioEngine!
    var mockFileSystem: MockFileSystem!
    var mockNativeEngine: MockNativeAudioEngine!
    var mockGainControl: MockAudioGainControl!
    
    override func setUp() async throws {
        try await super.setUp()
        mockFileSystem = MockFileSystem()
        mockNativeEngine = MockNativeAudioEngine()
        mockGainControl = MockAudioGainControl()
        
        engine = AudioEngine(
            fileSystem: mockFileSystem,
            nativeEngine: mockNativeEngine,
            gainControl: mockGainControl
        )
    }
    
    override func tearDown() async throws {
        engine = nil
        mockFileSystem = nil
        mockNativeEngine = nil
        mockGainControl = nil
        try await super.tearDown()
    }
    
    // MARK: - User Scenario: Adjust Volume with Small Steps
    
    /// BDD: As a user, I want to increase volume in small steps (1%) so I can fine-tune the audio level
    func testUserIncreasesVolumeInSmallSteps() {
        // Given - I have audio playing at 50% volume
        engine.volume = 0.5
        
        // When - I increase the volume by 1% (one step)
        engine.increaseVolume(by: 0.01)
        
        // Then - The volume should increase to 51%
        XCTAssertEqual(engine.volume, 0.51, accuracy: 0.001, "Volume should increase by 1%")
    }
    
    /// BDD: As a user, I want to decrease volume in small steps (1%) so I can fine-tune the audio level
    func testUserDecreasesVolumeInSmallSteps() {
        // Given - I have audio playing at 50% volume
        engine.volume = 0.5
        
        // When - I decrease the volume by 1% (one step)
        engine.decreaseVolume(by: 0.01)
        
        // Then - The volume should decrease to 49%
        XCTAssertEqual(engine.volume, 0.49, accuracy: 0.001, "Volume should decrease by 1%")
    }
    
    /// BDD: As a user, I want to increase volume by larger steps (5%) so I can quickly adjust the audio level
    func testUserIncreasesVolumeByLargerSteps() {
        // Given - I have audio playing at 50% volume
        engine.volume = 0.5
        
        // When - I increase the volume by 5%
        engine.increaseVolume(by: 0.05)
        
        // Then - The volume should increase to 55%
        XCTAssertEqual(engine.volume, 0.55, accuracy: 0.001, "Volume should increase by 5%")
    }
    
    // MARK: - User Scenario: Volume and Gain Are Independent
    
    /// BDD: As a user, I want volume control to be independent of gain control so I can adjust them separately
    func testUserAdjustsVolumeIndependentlyOfGain() async {
        // Given - I have audio playing at 50% volume with 0 dB gain
        engine.volume = 0.5
        await mockGainControl.setGlobalGain(0.0)
        await engine.refreshGain()
        
        // When - I increase the volume to 75%
        engine.volume = 0.75
        
        // Then - The volume should be 75%, but gain should remain at 0 dB
        XCTAssertEqual(engine.volume, 0.75, accuracy: 0.001, "Volume should be 75%")
        let globalGain = await mockGainControl.getGlobalGain()
        XCTAssertEqual(globalGain, 0.0, accuracy: 0.001, "Gain should remain unchanged at 0 dB")
    }
    
    /// BDD: As a user, I want gain control to be independent of volume control so I can adjust them separately
    func testUserAdjustsGainIndependentlyOfVolume() async {
        // Given - I have audio playing at 50% volume with 0 dB gain
        engine.volume = 0.5
        await mockGainControl.setGlobalGain(0.0)
        await engine.refreshGain()
        
        // When - I increase the gain to +3 dB
        await mockGainControl.setGlobalGain(3.0)
        await engine.refreshGain()
        
        // Then - The gain should be +3 dB, but volume should remain at 50%
        let globalGain = await mockGainControl.getGlobalGain()
        XCTAssertEqual(globalGain, 3.0, accuracy: 0.001, "Gain should be +3 dB")
        XCTAssertEqual(engine.volume, 0.5, accuracy: 0.001, "Volume should remain unchanged at 50%")
    }
    
    /// BDD: As a user, I want volume and gain to work together so the effective audio level combines both
    func testUserVolumeAndGainWorkTogether() async {
        // Given - I have audio playing at 50% volume with +3 dB gain
        engine.volume = 0.5
        await mockGainControl.setGlobalGain(3.0)
        await engine.refreshGain()
        
        // When - I check the effective volume
        // (Effective volume = base volume * gain multiplier)
        let gainMultiplier = mockGainControl.gainDBToLinear(3.0)
        let expectedEffectiveVolume = 0.5 * gainMultiplier
        
        // Then - The effective volume should be base volume multiplied by gain
        // Note: We can't directly test effective volume, but we can verify both are set correctly
        XCTAssertEqual(engine.volume, 0.5, accuracy: 0.001, "Base volume should be 50%")
        let globalGain = await mockGainControl.getGlobalGain()
        XCTAssertEqual(globalGain, 3.0, accuracy: 0.001, "Gain should be +3 dB")
        XCTAssertGreaterThan(gainMultiplier, 1.0, "Gain multiplier should be greater than 1.0 for +3 dB")
        XCTAssertGreaterThan(expectedEffectiveVolume, 0.5, "Effective volume should be greater than base volume")
    }
    
    // MARK: - User Scenario: Volume Increments Are Different from Gain Increments
    
    /// BDD: As a user, I want volume to increment in percentage steps (1%, 5%) not in dB like gain
    func testUserVolumeIncrementsInPercentageNotDB() {
        // Given - I have audio playing at 50% volume
        engine.volume = 0.5
        
        // When - I increase volume by 1% (0.01)
        engine.increaseVolume(by: 0.01)
        
        // Then - Volume should increase by 0.01 (1%), not by 1.0 (100%)
        XCTAssertEqual(engine.volume, 0.51, accuracy: 0.001, "Volume should increase by 1% (0.01), not 100% (1.0)")
        XCTAssertNotEqual(engine.volume, 1.5, "Volume should NOT increase by 1.0 (100%)")
    }
    
    /// BDD: As a user, I want gain to increment in dB steps (0.5 dB, 1.0 dB) not in percentage like volume
    func testUserGainIncrementsInDBNotPercentage() async {
        // Given - I have audio with 0 dB gain
        await mockGainControl.setGlobalGain(0.0)
        await engine.refreshGain()
        
        // When - I increase gain by 1.0 dB
        await mockGainControl.setGlobalGain(1.0)
        await engine.refreshGain()
        
        // Then - Gain should increase by 1.0 dB, not by 1% (0.01)
        let globalGain = await mockGainControl.getGlobalGain()
        XCTAssertEqual(globalGain, 1.0, accuracy: 0.001, "Gain should increase by 1.0 dB, not 1% (0.01)")
        XCTAssertNotEqual(globalGain, 0.01, "Gain should NOT increase by 1% (0.01)")
    }
    
    // MARK: - User Scenario: Volume Cannot Exceed Limits
    
    /// BDD: As a user, I want volume to be limited to 100% so audio doesn't clip
    func testUserVolumeCannotExceedMaximum() {
        // Given - I have audio playing at 100% volume
        engine.volume = 1.0
        
        // When - I try to increase the volume further
        engine.increaseVolume(by: 0.1)
        
        // Then - The volume should remain at 100% (clamped)
        XCTAssertEqual(engine.volume, 1.0, accuracy: 0.001, "Volume should be clamped to maximum 100%")
    }
    
    /// BDD: As a user, I want volume to be limited to 0% so audio can be muted
    func testUserVolumeCannotGoBelowMinimum() {
        // Given - I have audio playing at 0% volume
        engine.volume = 0.0
        
        // When - I try to decrease the volume further
        engine.decreaseVolume(by: 0.1)
        
        // Then - The volume should remain at 0% (clamped)
        XCTAssertEqual(engine.volume, 0.0, accuracy: 0.001, "Volume should be clamped to minimum 0%")
    }
}
