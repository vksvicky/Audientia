//
//  DSPPerformanceTests.swift
//  Audientia - DSP Performance Tests
//
//  Performance tests for DSP (Digital Signal Processing) operations
//  Following Right-BICEP [P]erformance Characteristics
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import os.log
import XCTest

@testable import AudioCore
@testable import Shared

/// Performance tests for DSP operations
@MainActor
final class DSPPerformanceTests: XCTestCase {
    
    /// Performance: Gain calculation for 1000 tracks: < 100ms
    func testGainCalculationPerformance() async {
        // Given - Gain control and many tracks
        let gainControl = AudioGainControl()
        let tracks = (0..<1000).map { index in
            MockFactory.makeTrack(id: UUID(), title: "Track \(index)")
        }
        
        // Set some track gains
        for i in 0..<100 {
            await gainControl.setTrackGain(Float(i % 20) - 10.0, for: tracks[i])
        }
        
        // When - Measure gain calculation
        let (_, metrics) = await PerformanceTestHelpers.measureAsync(iterations: 1) {
            for track in tracks {
                _ = await gainControl.getEffectiveGain(for: track)
            }
        }
        
        // Then - Should complete within 100ms
        PerformanceTestHelpers.assertPerformanceSLA(
            metrics: metrics,
            maxDuration: 0.1 // 100ms
        )
        
        let report = PerformanceTestHelpers.generateReport(
            testName: "Gain Calculation (1,000 tracks)",
            metrics: metrics,
            sla: 0.1
        )
        Logger.testing.info("\(report)")
    }
    
    /// Performance: Normalization analysis for 44.1kHz audio: < 50ms
    func testNormalizationAnalysisPerformance() async throws {
        // Given - Audio normalizer and audio data
        let normalizer = AudioNormalizer()
        let sampleRate = 44100
        let channels = 2
        let durationSeconds: Float = 1.0
        let sampleCount = Int(Float(sampleRate) * durationSeconds * Float(channels))
        let audioData = (0..<sampleCount).map { _ in Float.random(in: -1.0...1.0) }
        
        // When - Measure normalization analysis
        let (_, metrics) = try await PerformanceTestHelpers.measureAsync(iterations: 100) {
            try await normalizer.analyzeNormalization(
                audioData: audioData,
                sampleRate: sampleRate,
                channels: channels,
                mode: .peak,
                targetLevel: -3.0
            )
        }
        
        // Then - Average should be < 50ms
        PerformanceTestHelpers.assertAveragePerformance(
            metrics: metrics,
            maxAverageDuration: 0.05 // 50ms
        )
        
        let report = PerformanceTestHelpers.generateReport(
            testName: "Normalization Analysis (44.1kHz, 1s)",
            metrics: metrics,
            sla: 0.05,
            slaMetric: .average
        )
        Logger.testing.info("\(report)")
    }
    
    /// Performance: Peak/RMS calculations: < 10ms
    func testPeakRMSCalculationPerformance() async {
        // Given - Audio normalizer and audio data
        let normalizer = AudioNormalizer()
        let sampleRate = 44100
        let channels = 2
        let durationSeconds: Float = 0.1 // 100ms of audio
        let sampleCount = Int(Float(sampleRate) * durationSeconds * Float(channels))
        let audioData = (0..<sampleCount).map { _ in Float.random(in: -1.0...1.0) }
        
        // When - Measure peak/RMS calculations
        let (_, metrics) = await PerformanceTestHelpers.measureAsync(iterations: 1000) {
            await normalizer.calculatePeakLevel(
                audioData: audioData,
                channels: channels
            )
        }
        
        // Then - Average should be < 10ms
        PerformanceTestHelpers.assertAveragePerformance(
            metrics: metrics,
            maxAverageDuration: 0.01 // 10ms
        )
        
        let report = PerformanceTestHelpers.generateReport(
            testName: "Peak/RMS Calculation",
            metrics: metrics,
            sla: 0.01,
            slaMetric: .average
        )
        Logger.testing.info("\(report)")
    }
}
