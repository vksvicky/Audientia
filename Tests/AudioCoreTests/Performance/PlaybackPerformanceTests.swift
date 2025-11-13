//
//  PlaybackPerformanceTests.swift
//  Audientia - Playback Performance Tests
//
//  Performance tests for audio playback operations
//  Following Right-BICEP [P]erformance Characteristics
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import os.log
import XCTest

@testable import AudioCore
@testable import Shared

/// Performance tests for playback operations
@MainActor
final class PlaybackPerformanceTests: XCTestCase {
    
    /// Performance: Start playback: < 100ms
    func testPlaybackStartPerformance() async throws {
        // Given - Audio engine with track
        let track = MockFactory.makeTrack()
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        
        // When - Measure playback start
        let (_, metrics) = try await PerformanceTestHelpers.measureAsync(iterations: 10) {
            try await engine.play()
            try await engine.pause()
        }
        
        // Then - Average should be < 100ms
        PerformanceTestHelpers.assertAveragePerformance(
            metrics: metrics,
            maxAverageDuration: 0.1 // 100ms
        )
        
        let report = PerformanceTestHelpers.generateReport(
            testName: "Playback Start",
            metrics: metrics,
            sla: 0.1,
            slaMetric: .average
        )
        Logger.testing.info("\(report)")
    }
    
    /// Performance: Seek accuracy: ±10ms
    func testSeekAccuracyPerformance() async throws {
        // Given - Audio engine with track
        let track = MockFactory.makeTrack(duration: 180.0)
        let engine = try await AudioEngineTestHelpers.createEngineWithTrack(track)
        try await engine.play()
        
        // When - Measure seek operations
        let seekTargets: [TimeInterval] = [30.0, 60.0, 90.0, 120.0, 150.0]
        var accuracies: [TimeInterval] = []
        
        for target in seekTargets {
            let startTime = Date()
            try await engine.seek(to: target)
            let seekDuration = Date().timeIntervalSince(startTime)
            
            let actualPosition = engine.currentPosition
            let accuracy = abs(actualPosition - target)
            accuracies.append(accuracy)
            
            // Seek itself should be fast
            XCTAssertLessThan(seekDuration, 0.1, "Seek operation should complete quickly")
        }
        
        // Then - Accuracy should be within ±10ms
        let maxAccuracy = accuracies.max() ?? 0
        XCTAssertLessThanOrEqual(maxAccuracy, 0.01, "Seek accuracy should be within ±10ms")
        
        Logger.testing.info("Seek Accuracy Test:")
        Logger.testing.info("  Max accuracy: \(String(format: "%.3f", maxAccuracy))s")
        Logger.testing.info("  Target: ±0.010s")
    }
}
