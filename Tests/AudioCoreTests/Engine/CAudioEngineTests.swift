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
    func testPlayWithoutFileReturnsFalse() async {
        // Given
        let engine = CAudioEngine()
        
        // When
        let result = await engine.play()
        
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
    
    // MARK: - Concurrency Tests
    
    /// BDD: Given a C++ audio engine, when I call play concurrently, then it should handle race conditions safely
    func testConcurrentPlayOperations() async {
        // Given
        let engine = CAudioEngine()
        
        // When - Call play from multiple tasks concurrently
        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await engine.play()
                }
            }
        }
        
        // Then - Engine should be in a valid state (no crashes)
        // Note: Since no file is loaded, all should return false, but state should be consistent
        XCTAssertTrue(engine.state == .stopped || engine.state == .playing || engine.state == .paused,
                      "Engine should be in a valid state after concurrent operations")
    }
    
    /// BDD: Given a C++ audio engine, when I cancel during loadFile, then it should handle cancellation gracefully
    func testLoadFileCancellation() async {
        // Given
        let engine = CAudioEngine()
        let nonExistentFile = "/tmp/nonexistent-\(UUID().uuidString).mp3"
        
        // When - Start loading and immediately cancel
        let task = Task {
            await engine.loadFile(nonExistentFile)
        }
        
        // Cancel immediately
        task.cancel()
        
        // Then - Task should complete (either successfully or with cancellation)
        let result = await task.value
        // Result can be false (file doesn't exist) or the task might have been cancelled
        // The important thing is no crash occurred
        XCTAssertFalse(result, "Loading non-existent file should return false")
    }
    
    /// BDD: Given a C++ audio engine, when I perform multiple async operations in parallel, then all should complete
    func testMultipleAsyncOperationsInParallel() async {
        // Given
        let engine = CAudioEngine()
        
        // When - Perform multiple async operations concurrently
        await withTaskGroup(of: Void.self) { group in
            // Multiple play calls
            for _ in 0..<5 {
                group.addTask {
                    _ = await engine.play()
                }
            }
            
            // Multiple seek calls
            for i in 0..<5 {
                group.addTask {
                    _ = await engine.seek(to: Double(i))
                }
            }
        }
        
        // Then - Engine should be in a valid state
        XCTAssertTrue(engine.state == .stopped || engine.state == .playing || engine.state == .paused,
                      "Engine should handle parallel async operations safely")
    }
    
    /// BDD: Given a C++ audio engine, when I call play and pause concurrently, then state should be consistent
    func testConcurrentPlayPause() async {
        // Given
        let engine = CAudioEngine()
        
        // When - Call play and pause concurrently
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                _ = await engine.play()
            }
            group.addTask {
                await engine.pause()
            }
        }
        
        // Then - State should be either playing or paused (not both)
        let state = engine.state
        XCTAssertTrue(state == .playing || state == .paused || state == .stopped,
                      "Engine state should be consistent after concurrent play/pause")
    }
    
    /// BDD: Given a C++ audio engine, when I seek to multiple positions concurrently, then final position should be valid
    func testConcurrentSeekOperations() async {
        // Given
        let engine = CAudioEngine()
        
        // When - Seek to multiple positions concurrently
        await withTaskGroup(of: Bool.self) { group in
            for position in stride(from: 0.0, through: 10.0, by: 0.5) {
                group.addTask {
                    await engine.seek(to: position)
                }
            }
        }
        
        // Then - Final position should be within valid range
        XCTAssertGreaterThanOrEqual(engine.currentPosition, 0.0,
                                    "Position should not be negative after concurrent seeks")
    }
}
