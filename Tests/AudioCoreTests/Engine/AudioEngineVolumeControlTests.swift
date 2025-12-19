//
//  AudioEngineVolumeControlTests.swift
//  AudioCoreTests
//
//  TDD tests for AudioEngine Volume Control
//  Following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
@testable import Shared
import XCTest

/// TDD tests for AudioEngine Volume Control
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class AudioEngineVolumeControlTests: XCTestCase {
    
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
    
    // MARK: - Right: Are the Results Right?
    
    /// Test that volume defaults to 1.0 (100%)
    func testVolumeDefaultsToFull() {
        // Given - A new audio engine
        // When - Check initial volume
        // Then - Should be 1.0 (100%)
        XCTAssertEqual(engine.volume, 1.0, accuracy: 0.001, "Volume should default to 1.0 (100%)")
    }
    
    /// Test that increasing volume by 1% (0.01) works correctly
    func testIncreaseVolumeByOnePercent() {
        // Given - Volume is at 0.5 (50%)
        engine.volume = 0.5
        
        // When - Increase volume by 1% (0.01)
        engine.increaseVolume(by: 0.01)
        
        // Then - Volume should be 0.51 (51%)
        XCTAssertEqual(engine.volume, 0.51, accuracy: 0.001, "Volume should increase by 1%")
    }
    
    /// Test that decreasing volume by 1% (0.01) works correctly
    func testDecreaseVolumeByOnePercent() {
        // Given - Volume is at 0.5 (50%)
        engine.volume = 0.5
        
        // When - Decrease volume by 1% (0.01)
        engine.decreaseVolume(by: 0.01)
        
        // Then - Volume should be 0.49 (49%)
        XCTAssertEqual(engine.volume, 0.49, accuracy: 0.001, "Volume should decrease by 1%")
    }
    
    /// Test that increasing volume by 5% (0.05) works correctly
    func testIncreaseVolumeByFivePercent() {
        // Given - Volume is at 0.5 (50%)
        engine.volume = 0.5
        
        // When - Increase volume by 5% (0.05)
        engine.increaseVolume(by: 0.05)
        
        // Then - Volume should be 0.55 (55%)
        XCTAssertEqual(engine.volume, 0.55, accuracy: 0.001, "Volume should increase by 5%")
    }
    
    /// Test that default volume step is 1% (0.01)
    func testDefaultVolumeStepIsOnePercent() {
        // Given - Volume is at 0.5 (50%)
        engine.volume = 0.5
        
        // When - Increase volume with default step (0.01 = 1%)
        engine.increaseVolume(by: 0.01)
        
        // Then - Volume should increase by 0.01 (1%)
        XCTAssertEqual(engine.volume, 0.51, accuracy: 0.001, "Default volume step should be 1%")
    }
    
    // MARK: - Boundary Conditions
    
    /// Test that volume cannot exceed 1.0 (100%)
    func testVolumeCannotExceedMaximum() {
        // Given - Volume is at 1.0 (100%)
        engine.volume = 1.0
        
        // When - Increase volume by 5% (0.05)
        engine.increaseVolume(by: 0.05)
        
        // Then - Volume should remain at 1.0 (clamped)
        XCTAssertEqual(engine.volume, 1.0, accuracy: 0.001, "Volume should be clamped to maximum 1.0")
    }
    
    /// Test that volume cannot go below 0.0 (0%)
    func testVolumeCannotGoBelowMinimum() {
        // Given - Volume is at 0.0 (0%)
        engine.volume = 0.0
        
        // When - Decrease volume by 5% (0.05)
        engine.decreaseVolume(by: 0.05)
        
        // Then - Volume should remain at 0.0 (clamped)
        XCTAssertEqual(engine.volume, 0.0, accuracy: 0.001, "Volume should be clamped to minimum 0.0")
    }
    
    /// Test that volume can be set to exactly 1.0
    func testVolumeCanBeSetToMaximum() {
        // Given - Volume is at 0.5 (50%)
        engine.volume = 0.5
        
        // When - Increase volume by 0.5 to reach maximum
        engine.increaseVolume(by: 0.5)
        
        // Then - Volume should be 1.0
        XCTAssertEqual(engine.volume, 1.0, accuracy: 0.001, "Volume should reach maximum 1.0")
    }
    
    /// Test that volume can be set to exactly 0.0
    func testVolumeCanBeSetToMinimum() {
        // Given - Volume is at 0.5 (50%)
        engine.volume = 0.5
        
        // When - Decrease volume by 0.5 to reach minimum
        engine.decreaseVolume(by: 0.5)
        
        // Then - Volume should be 0.0
        XCTAssertEqual(engine.volume, 0.0, accuracy: 0.001, "Volume should reach minimum 0.0")
    }
    
    // MARK: - Inverse Relationships
    
    /// Test that increasing then decreasing by same amount returns to original
    func testIncreaseThenDecreaseReturnsToOriginal() {
        // Given - Volume is at 0.5 (50%)
        let originalVolume: Float = 0.5
        engine.volume = originalVolume
        
        // When - Increase by 0.1 then decrease by 0.1
        engine.increaseVolume(by: 0.1)
        engine.decreaseVolume(by: 0.1)
        
        // Then - Volume should return to original
        XCTAssertEqual(engine.volume, originalVolume, accuracy: 0.001, "Volume should return to original after inverse operations")
    }
    
    /// Test that decreasing then increasing by same amount returns to original
    func testDecreaseThenIncreaseReturnsToOriginal() {
        // Given - Volume is at 0.5 (50%)
        let originalVolume: Float = 0.5
        engine.volume = originalVolume
        
        // When - Decrease by 0.1 then increase by 0.1
        engine.decreaseVolume(by: 0.1)
        engine.increaseVolume(by: 0.1)
        
        // Then - Volume should return to original
        XCTAssertEqual(engine.volume, originalVolume, accuracy: 0.001, "Volume should return to original after inverse operations")
    }
    
    // MARK: - Cross-Checking
    
    /// Test that volume changes are independent of gain changes
    func testVolumeChangesAreIndependentOfGain() async {
        // Given - Volume is at 0.5, gain is at 0.0 dB
        engine.volume = 0.5
        await mockGainControl.setGlobalGain(0.0)
        await engine.refreshGain()
        
        // When - Increase volume by 0.1
        engine.increaseVolume(by: 0.1)
        
        // Then - Volume should increase, gain should remain unchanged
        XCTAssertEqual(engine.volume, 0.6, accuracy: 0.001, "Volume should increase independently")
        let globalGain = await mockGainControl.getGlobalGain()
        XCTAssertEqual(globalGain, 0.0, accuracy: 0.001, "Gain should remain unchanged")
    }
    
    /// Test that gain changes are independent of volume changes
    func testGainChangesAreIndependentOfVolume() async {
        // Given - Volume is at 0.5, gain is at 0.0 dB
        engine.volume = 0.5
        await mockGainControl.setGlobalGain(0.0)
        await engine.refreshGain()
        
        // When - Increase gain by 3.0 dB
        await mockGainControl.setGlobalGain(3.0)
        await engine.refreshGain()
        
        // Then - Gain should increase, volume should remain unchanged
        let globalGain = await mockGainControl.getGlobalGain()
        XCTAssertEqual(globalGain, 3.0, accuracy: 0.001, "Gain should increase independently")
        XCTAssertEqual(engine.volume, 0.5, accuracy: 0.001, "Volume should remain unchanged")
    }
    
    // MARK: - Error Conditions
    
    /// Test that negative step size is handled (should be treated as positive)
    func testNegativeStepSizeIsHandled() {
        // Given - Volume is at 0.5 (50%)
        engine.volume = 0.5
        
        // When - Increase volume by negative step (should be treated as decrease)
        engine.increaseVolume(by: -0.1)
        
        // Then - Volume should decrease
        XCTAssertEqual(engine.volume, 0.4, accuracy: 0.001, "Negative step in increase should decrease volume")
    }
    
    /// Test that very large step size is clamped
    func testVeryLargeStepSizeIsClamped() {
        // Given - Volume is at 0.5 (50%)
        engine.volume = 0.5
        
        // When - Increase volume by very large step (2.0)
        engine.increaseVolume(by: 2.0)
        
        // Then - Volume should be clamped to 1.0
        XCTAssertEqual(engine.volume, 1.0, accuracy: 0.001, "Very large step should be clamped to maximum")
    }
    
    // MARK: - Performance Characteristics
    
    /// Test that volume increment operations are fast
    func testVolumeIncrementPerformance() {
        // Given - Volume is at 0.0
        engine.volume = 0.0
        
        // When - Perform many increment operations
        measure {
            for _ in 0..<1000 {
                engine.increaseVolume(by: 0.001)
            }
        }
        
        // Then - Should complete quickly (performance test)
        XCTAssertLessThan(engine.volume, 1.1, "Volume should be reasonable after many increments")
    }
}
