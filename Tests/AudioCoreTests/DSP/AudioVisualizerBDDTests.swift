@testable import AudioCore
import XCTest

/// BDD scenarios for the audio visualizer feed
final class AudioVisualizerBDDTests: XCTestCase {
    private var visualizer: AudioVisualizer!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        visualizer = AudioVisualizer(
            config: AudioVisualizerConfig(
                fftSize: 1024,
                smoothingFactor: 0.0,
                historyLength: 5
            )
        )
    }
    
    override func tearDownWithError() throws {
        visualizer = nil
        try super.tearDownWithError()
    }
    
    /// BDD: Given a bass-heavy track, when I view the visualizer, then low-frequency bands should dominate
    func testBassHeavyTrackShowsLowFrequencyEnergy() async throws {
        // Given - A simulated bass-heavy signal (80 Hz sine wave)
        let sampleRate = 44_100
        let audioData = Self.makeSineWave(
            frequency: 80.0,
            sampleRate: sampleRate,
            frameCount: 1024
        )
        
        // When - I process the visualizer frame
        let frame = try await visualizer.process(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: 1
        )
        
        // Then - Energy in the first quarter of bins should be significantly higher than upper bins
        let lowBand = frame.magnitudes.prefix(frame.magnitudes.count / 4)
        let highBand = frame.magnitudes.suffix(frame.magnitudes.count / 4)
        let lowAverage = lowBand.reduce(0, +) / Float(lowBand.count)
        let highAverage = highBand.reduce(0, +) / Float(highBand.count)
        XCTAssertGreaterThan(lowAverage, highAverage * 3.0, "Low frequency energy should dominate for bass-heavy content")
    }
    
    /// BDD: Given a playing track, when a frame is emitted, then it should be timestamped for the UI
    func testVisualizerFramesAreTimestamped() async throws {
        // Given - An audio buffer
        let sampleRate = 44_100
        let audioData = Self.makeSineWave(
            frequency: 440.0,
            sampleRate: sampleRate,
            frameCount: 1024
        )
        
        // When
        let before = Date()
        let frame = try await visualizer.process(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: 1
        )
        let after = Date()
        
        // Then
        XCTAssertLessThanOrEqual(before, frame.timestamp)
        XCTAssertGreaterThanOrEqual(after, frame.timestamp)
        XCTAssertGreaterThan(frame.maxMagnitude, 0.0, "Frame should capture non-zero energy")
    }
    
    /// BDD: Given multiple frames, when I request recent frames, then they should be capped and ordered for UI rendering
    func testRecentFramesOrderedAndCapped() async throws {
        // Given - Multiple frames with distinct frequencies
        let sampleRate = 44_100
        let frequencies: [Float] = [120.0, 440.0, 880.0, 1760.0, 3520.0]
        for frequency in frequencies {
            let audioData = Self.makeSineWave(
                frequency: frequency,
                sampleRate: sampleRate,
                frameCount: 1024
            )
            _ = try await visualizer.process(
                audioData: audioData,
                sampleRate: sampleRate,
                channels: 1
            )
        }
        
        // When - Request recent frames with higher limit than history length
        let recentFrames = await visualizer.recentFrames(limit: 10)
        
        // Then - Should be capped to history length (5) and preserve chronological order
        XCTAssertEqual(recentFrames.count, 5, "History length should match configured limit")
        let dominantFrequencies = recentFrames.map { $0.dominantFrequency }
        for (actual, expected) in zip(dominantFrequencies, frequencies) {
            XCTAssertEqual(actual, expected, accuracy: 80.0, "Dominant frequency should track processed frames")
        }
    }
    
    // MARK: - Helpers
    
    private static func makeSineWave(frequency: Float, sampleRate: Int, frameCount: Int) -> [Float] {
        (0..<frameCount).map { index in
            sin(2.0 * .pi * frequency * Float(index) / Float(sampleRate))
        }
    }
}
