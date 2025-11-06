//
//  CAudioEngineTests.swift
//  AudioCoreTests
//
//  TDD/BDD Tests for C++ Audio Engine Bridge
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
@testable import Shared
import XCTest

/// BDD-style test suite for C++ Audio Engine Bridge
/// Following Right-BICEP principles
@MainActor
final class CAudioEngineTests: XCTestCase {
    
    // MARK: - [Right] Tests: Are the Results Right?
    
    /// BDD: Given a C++ audio engine, when I initialize it, then it should be in stopped state
    func testInitialStateIsStopped() {
        // Given
        let engine = CAudioEngine()
        
        // When & Then
        XCTAssertEqual(engine.state, .stopped, "C++ engine should start in stopped state")
        XCTAssertFalse(engine.isPlaying, "C++ engine should not be playing initially")
    }
    
    /// BDD: Given a C++ audio engine, when I check initial volume, then it should be 1.0
    func testInitialVolumeIsOne() {
        // Given
        let engine = CAudioEngine()
        
        // When & Then
        XCTAssertEqual(engine.volume, 1.0, accuracy: 0.01, "Initial volume should be 1.0")
    }
    
    // MARK: - [B]oundary Conditions
    
    /// BDD: Given a C++ audio engine, when I set volume to 0.0, then it should be 0.0
    func testSetVolumeToZero() {
        // Given
        let engine = CAudioEngine()
        
        // When
        engine.setVolume(0.0)
        
        // Then
        XCTAssertEqual(engine.volume, 0.0, accuracy: 0.01, "Volume should be 0.0")
    }
    
    /// BDD: Given a C++ audio engine, when I set volume to 1.0, then it should be 1.0
    func testSetVolumeToOne() {
        // Given
        let engine = CAudioEngine()
        
        // When
        engine.setVolume(1.0)
        
        // Then
        XCTAssertEqual(engine.volume, 1.0, accuracy: 0.01, "Volume should be 1.0")
    }
    
    /// BDD: Given a C++ audio engine, when I set volume above 1.0, then it should clamp to 1.0
    func testSetVolumeAboveOneClamps() {
        // Given
        let engine = CAudioEngine()
        
        // When
        engine.setVolume(2.0)
        
        // Then
        XCTAssertEqual(engine.volume, 1.0, accuracy: 0.01, "Volume should clamp to 1.0")
    }
    
    /// BDD: Given a C++ audio engine, when I set volume below 0.0, then it should clamp to 0.0
    func testSetVolumeBelowZeroClamps() {
        // Given
        let engine = CAudioEngine()
        
        // When
        engine.setVolume(-1.0)
        
        // Then
        XCTAssertEqual(engine.volume, 0.0, accuracy: 0.01, "Volume should clamp to 0.0")
    }
    
    // MARK: - [E]rror Conditions
    
    /// BDD: Given a C++ audio engine, when I try to play without a file, then it should return false
    func testPlayWithoutFileReturnsFalse() {
        // Given
        let engine = CAudioEngine()
        
        // When
        let result = engine.play()
        
        // Then
        XCTAssertFalse(result, "Play should return false when no file is loaded")
    }
    
    // MARK: - [P]erformance Characteristics
    
    /// BDD: Given a C++ audio engine, when I set volume many times, then it should complete quickly
    func testVolumeSetPerformance() {
        // Given
        let engine = CAudioEngine()
        
        // When
        measure {
            for i in 0..<1000 {
                engine.setVolume(Float(i % 100) / 100.0)
            }
        }
        
        // Then - Performance verified by measure block
    }
}
