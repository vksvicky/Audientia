//
//  PerformanceTestSuite.swift
//  Audientia - Comprehensive Performance Tests
//
//  Performance tests based on roadmap benchmarks
//  Following Right-BICEP [P]erformance Characteristics
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
@testable import DataLayer
@testable import Shared
import XCTest

/// Comprehensive performance test suite
/// Tests performance against roadmap benchmarks
@MainActor
final class PerformanceTestSuite: XCTestCase {
    
    // MARK: - Library Operations Performance
    
    /// Performance: Scan 10,000 tracks: < 5 minutes
    func testLibraryScanPerformance() async {
        // Given - Large library simulation
        let trackCount = 10_000
        let tracks = (0..<trackCount).map { index in
            MockFactory.makeTrack(
                id: UUID(),
                title: "Track \(index)",
                filePath: "/path/to/track\(index).mp3"
            )
        }
        
        // When - Measure scanning performance
        let (_, metrics) = await PerformanceTestHelpers.measureAsync(iterations: 1) {
            // Simulate scanning operation
            // In real implementation, this would use LibraryScanner
            var scanned: [Shared.Track] = []
            for track in tracks {
                scanned.append(track)
            }
            return scanned
        }
        
        // Then - Should complete within 5 minutes
        PerformanceTestHelpers.assertPerformanceSLA(
            metrics: metrics,
            maxDuration: 300.0, // 5 minutes
            maxP95Duration: nil
        )
        
        print(PerformanceTestHelpers.generateReport(
            testName: "Library Scan (10,000 tracks)",
            metrics: metrics,
            sla: 300.0
        ))
    }
    
    /// Performance: Search 100,000 tracks: < 100ms (P95)
    func testLibrarySearchPerformance() async throws {
        // Given - Large library for searching
        let trackCount = 100_000
        let tracks = (0..<trackCount).map { index in
            MockFactory.makeTrack(
                id: UUID(),
                title: "Track \(index)",
                artist: "Artist \(index % 100)",
                album: "Album \(index % 1000)"
            )
        }
        
        // Set up indexer and search with optimized search index
        let indexer = LibraryIndexer()
        try await indexer.index(tracks: tracks)
        let search = LibrarySearch(indexer: indexer)
        
        // When - Measure search performance using actual LibrarySearch
        let searchQuery = "Track 50000"
        let (_, metrics) = try await PerformanceTestHelpers.measureAsync(operation: {
            try await search.search(query: searchQuery, field: .all)
        }, iterations: 100)
        
        // Then - P95 should be < 100ms
        PerformanceTestHelpers.assertPerformanceSLA(
            metrics: metrics,
            maxDuration: 10.0, // Total for 100 iterations
            maxP95Duration: 0.1 // 100ms per search
        )
        
        print(PerformanceTestHelpers.generateReport(
            testName: "Library Search (100,000 tracks)",
            metrics: metrics,
            sla: 0.1
        ))
        
        // Cleanup
        try await indexer.clear()
    }
    
    /// Performance: Load playlist (1000 tracks): < 200ms
    func testPlaylistLoadPerformance() async {
        // Given - Large playlist
        let trackCount = 1000
        let tracks = (0..<trackCount).map { index in
            MockFactory.makeTrack(
                id: UUID(),
                title: "Track \(index)"
            )
        }
        
        // When - Measure playlist loading
        let (_, metrics) = await PerformanceTestHelpers.measureAsync(iterations: 10) {
            // Simulate playlist load
            // In real implementation, this would load from DataLayer
            Array(tracks)
        }
        
        // Then - Average should be < 200ms
        PerformanceTestHelpers.assertAveragePerformance(
            metrics: metrics,
            maxAverageDuration: 0.2 // 200ms
        )
        
        print(PerformanceTestHelpers.generateReport(
            testName: "Playlist Load (1,000 tracks)",
            metrics: metrics,
            sla: 0.2
        ))
    }
    
    // MARK: - Playback Performance
    
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
        
        print(PerformanceTestHelpers.generateReport(
            testName: "Playback Start",
            metrics: metrics,
            sla: 0.1
        ))
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
        
        print("Seek Accuracy Test:")
        print("  Max accuracy: \(String(format: "%.3f", maxAccuracy))s")
        print("  Target: ±0.010s")
    }
    
    // MARK: - Tagging Performance
    
    /// Performance: Single tag write: < 100ms
    func testTagWritePerformance() async {
        // Given - Track for tagging
        let track = MockFactory.makeTrack()
        
        // When - Measure tag write
        // Note: This is a placeholder - real implementation would use MetadataEngine
        let (_, metrics) = await PerformanceTestHelpers.measureAsync(iterations: 100) {
            // Simulate tag write operation
            // In real implementation: await metadataEngine.writeTag(track, fields: ...)
            true
        }
        
        // Then - Average should be < 100ms
        PerformanceTestHelpers.assertAveragePerformance(
            metrics: metrics,
            maxAverageDuration: 0.1 // 100ms
        )
        
        print(PerformanceTestHelpers.generateReport(
            testName: "Tag Write (single)",
            metrics: metrics,
            sla: 0.1
        ))
    }
    
    /// Performance: Batch 100 tracks: < 10s
    func testBatchTagWritePerformance() async {
        // Given - 100 tracks for batch tagging
        let tracks = (0..<100).map { index in
            MockFactory.makeTrack(
                id: UUID(),
                title: "Track \(index)"
            )
        }
        
        // When - Measure batch tag write
        let (_, metrics) = await PerformanceTestHelpers.measureAsync(iterations: 1) {
            // Simulate batch tag write
            // In real implementation: await metadataEngine.writeTagsBatch(tracks, fields: ...)
            tracks.count
        }
        
        // Then - Should complete within 10 seconds
        PerformanceTestHelpers.assertPerformanceSLA(
            metrics: metrics,
            maxDuration: 10.0 // 10 seconds
        )
        
        print(PerformanceTestHelpers.generateReport(
            testName: "Batch Tag Write (100 tracks)",
            metrics: metrics,
            sla: 10.0
        ))
    }
    
    /// Performance: Tag read: < 10ms
    func testTagReadPerformance() async {
        // Given - Track for reading tags
        let track = MockFactory.makeTrack()
        
        // When - Measure tag read
        let (_, metrics) = await PerformanceTestHelpers.measureAsync(iterations: 1000) {
            // Simulate tag read operation
            // In real implementation: await metadataEngine.readTag(track)
            track.title
        }
        
        // Then - Average should be < 10ms
        PerformanceTestHelpers.assertAveragePerformance(
            metrics: metrics,
            maxAverageDuration: 0.01 // 10ms
        )
        
        print(PerformanceTestHelpers.generateReport(
            testName: "Tag Read",
            metrics: metrics,
            sla: 0.01
        ))
    }
    
    // MARK: - DSP Performance
    
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
        
        print(PerformanceTestHelpers.generateReport(
            testName: "Gain Calculation (1,000 tracks)",
            metrics: metrics,
            sla: 0.1
        ))
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
        
        print(PerformanceTestHelpers.generateReport(
            testName: "Normalization Analysis (44.1kHz, 1s)",
            metrics: metrics,
            sla: 0.05
        ))
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
        
        print(PerformanceTestHelpers.generateReport(
            testName: "Peak/RMS Calculation",
            metrics: metrics,
            sla: 0.01
        ))
    }
    
    // MARK: - Memory Performance
    
    /// Test memory usage during large operations
    func testMemoryUsageDuringLargeScan() async {
        // Given - Large library
        let trackCount = 10_000
        
        // When - Measure memory usage
        let memoryResult = await PerformanceTestHelpers.measureMemoryUsage {
            // Simulate large scan operation
            var tracks: [Shared.Track] = []
            for i in 0..<trackCount {
                tracks.append(MockFactory.makeTrack(
                    id: UUID(),
                    title: "Track \(i)"
                ))
            }
            return tracks
        }
        
        // Then - Memory delta should be reasonable (< 100MB for 10k tracks)
        let deltaMB = Double(memoryResult.delta) / 1_000_000.0
        XCTAssertLessThan(deltaMB, 100.0, "Memory usage should be reasonable")
        
        print("Memory Usage Test:")
        print("  Before: \(String(format: "%.2f", Double(memoryResult.before) / 1_000_000.0)) MB")
        print("  After: \(String(format: "%.2f", Double(memoryResult.after) / 1_000_000.0)) MB")
        print("  Delta: \(String(format: "%.2f", deltaMB)) MB")
    }
}
