@testable import AudioCore
import XCTest

/// TDD tests for the AudioVisualiser FFT feed
final class AudioVisualiserTests: XCTestCase {
    private var visualiser: AudioVisualiser!
    private var smoothingVisualizer: AudioVisualiser!
    private var historyVisualizer: AudioVisualiser!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        visualiser = AudioVisualiser(
            config: AudioVisualiserConfig(
                fftSize: 1024,
                smoothingFactor: 0.0,
                historyLength: 8
            )
        )
        smoothingVisualizer = AudioVisualiser(
            config: AudioVisualiserConfig(
                fftSize: 1024,
                smoothingFactor: 0.5,
                historyLength: 4
            )
        )
        historyVisualizer = AudioVisualiser(
            config: AudioVisualiserConfig(
                fftSize: 512,
                smoothingFactor: 0.0,
                historyLength: 3
            )
        )
    }
    
    override func tearDownWithError() throws {
        visualiser = nil
        smoothingVisualizer = nil
        historyVisualizer = nil
        try super.tearDownWithError()
    }
    
    /// TDD: Given a sine wave input, when I process it, then the dominant frequency bin should match the sine frequency
    func testProcessSineWaveProducesDominantFrequencyBin() async throws {
        // Given
        let sampleRate = 44_100
        let frequency: Float = 440.0
        let fftSize = 1024
        let audioData = Self.makeSineWave(
            frequency: frequency,
            sampleRate: sampleRate,
            frameCount: fftSize
        )
        let expectedBin = Int(round(frequency * Float(fftSize) / Float(sampleRate)))
        
        // When
        let frame = try await visualiser.process(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: 1
        )
        
        // Then
        XCTAssertEqual(frame.magnitudes.count, fftSize / 2, "FFT magnitudes should have half the fftSize bins")
        guard let dominantBin = frame.magnitudes.indices.max(by: { frame.magnitudes[$0] < frame.magnitudes[$1] }) else {
            return XCTFail("Expected a dominant frequency bin")
        }
        
        XCTAssertTrue(abs(dominantBin - expectedBin) <= 1, "Dominant bin (\(dominantBin)) should be near expected bin (\(expectedBin))")
        
        // Ensure energy outside the dominant bin range is significantly lower
        let dominantMagnitude = frame.magnitudes[dominantBin]
        for (index, magnitude) in frame.magnitudes.enumerated() where abs(index - expectedBin) > 2 {
            XCTAssertLessThan(magnitude, dominantMagnitude * 0.25, "Energy outside dominant region should be low")
        }
    }
    
    /// TDD: Given stereo audio, when I process it, then channels should be averaged to mono before FFT
    func testProcessAveragesStereoChannels() async throws {
        // Given
        let sampleRate = 44_100
        let fftSize = 1024
        var stereoAudio: [Float] = []
        var monoAverage: [Float] = []
        for sampleIndex in 0..<fftSize {
            let left = sin(2.0 * .pi * 220.0 * Float(sampleIndex) / Float(sampleRate))
            let right = sin(2.0 * .pi * 880.0 * Float(sampleIndex) / Float(sampleRate)) * 0.5
            stereoAudio.append(contentsOf: [left, right])
            monoAverage.append((left + right) / 2.0)
        }
        let stereoVisualizer = AudioVisualiser(
            config: AudioVisualiserConfig(
                fftSize: fftSize,
                smoothingFactor: 0.0,
                historyLength: 4
            )
        )
        let monoVisualizer = AudioVisualiser(
            config: AudioVisualiserConfig(
                fftSize: fftSize,
                smoothingFactor: 0.0,
                historyLength: 4
            )
        )
        
        // When
        let stereoFrame = try await stereoVisualizer.process(
            audioData: stereoAudio,
            sampleRate: sampleRate,
            channels: 2
        )
        let monoFrame = try await monoVisualizer.process(
            audioData: monoAverage,
            sampleRate: sampleRate,
            channels: 1
        )
        
        // Then - magnitudes should match the manually averaged mono reference
        XCTAssertEqual(stereoFrame.magnitudes.count, monoFrame.magnitudes.count)
        for (stereoMagnitude, monoMagnitude) in zip(stereoFrame.magnitudes, monoFrame.magnitudes) {
            XCTAssertEqual(stereoMagnitude, monoMagnitude, accuracy: 1e-3)
        }
    }
    
    /// TDD: Given smoothing enabled, when I process successive frames, then magnitudes should blend over time
    func testProcessAppliesSmoothingBetweenFrames() async throws {
        // Given
        let sampleRate = 44_100
        let fftSize = 1024
        let strongSignal = Self.makeSineWave(
            frequency: 440.0,
            sampleRate: sampleRate,
            frameCount: fftSize
        )
        let silence = [Float](repeating: 0.0, count: fftSize)
        
        // When
        let firstFrame = try await smoothingVisualizer.process(
            audioData: strongSignal,
            sampleRate: sampleRate,
            channels: 1
        )
        let secondFrame = try await smoothingVisualizer.process(
            audioData: silence,
            sampleRate: sampleRate,
            channels: 1
        )
        
        // Then - smoothing should retain part of the original magnitude
        let dominantIndex = try XCTUnwrap(firstFrame.magnitudes.indices.max(by: { firstFrame.magnitudes[$0] < firstFrame.magnitudes[$1] }))
        let firstMagnitude = firstFrame.magnitudes[dominantIndex]
        let secondMagnitude = secondFrame.magnitudes[dominantIndex]
        XCTAssertGreaterThan(secondMagnitude, firstMagnitude * 0.4, "Smoothing should retain energy from previous frame")
        XCTAssertLessThan(secondMagnitude, firstMagnitude * 0.7, "Smoothing should decay energy over time")
    }
    
    /// TDD: Given invalid inputs, when I process audio, then it should throw descriptive errors
    func testProcessValidatesInputs() async {
        await XCTAssertThrowsErrorAsync(
            try await visualiser.process(
                audioData: [],
                sampleRate: 44_100,
                channels: 1
            )
        ) { error in
            guard let visualiserError = error as? AudioVisualiserError else {
                return XCTFail("Expected AudioVisualiserError, got \(error)")
            }
            XCTAssertEqual(visualiserError, .invalidAudioData)
        }
        
        await XCTAssertThrowsErrorAsync(
            try await visualiser.process(
                audioData: [0.1, 0.2, 0.3],
                sampleRate: 0,
                channels: 1
            )
        ) { error in
            guard let visualiserError = error as? AudioVisualiserError else {
                return XCTFail("Expected AudioVisualiserError, got \(error)")
            }
            XCTAssertEqual(visualiserError, .invalidSampleRate)
        }
        
        await XCTAssertThrowsErrorAsync(
            try await visualiser.process(
                audioData: [0.1, 0.2, 0.3],
                sampleRate: 44_100,
                channels: 0
            )
        ) { error in
            guard let visualiserError = error as? AudioVisualiserError else {
                return XCTFail("Expected AudioVisualiserError, got \(error)")
            }
            XCTAssertEqual(visualiserError, .invalidChannelCount)
        }
    }
    
    /// TDD: Given history length, when I process multiple frames, then recentFrames should respect capacity
    func testRecentFramesRespectsHistoryLength() async throws {
        // Given
        let sampleRate = 44_100
        let fftSize = 512
        let frameCount = 5
        for i in 0..<frameCount {
            let audioData = Self.makeSineWave(
                frequency: 100.0 + Float(i) * 100.0,
                sampleRate: sampleRate,
                frameCount: fftSize
            )
            _ = try await historyVisualizer.process(
                audioData: audioData,
                sampleRate: sampleRate,
                channels: 1
            )
        }
        
        // When
        let recentFrames = await historyVisualizer.recentFrames(limit: 10)
        
        // Then
        XCTAssertEqual(recentFrames.count, 3, "History should be capped to configured length")
        let frequencies = recentFrames.map { $0.dominantFrequency }
        let expectedFrequencies: [Float] = [300.0, 400.0, 500.0]
        for (actual, expected) in zip(frequencies, expectedFrequencies) {
            XCTAssertEqual(actual, expected, accuracy: 80.0, "Dominant frequency should track recent frames (expected \(expected), got \(actual))")
        }
        XCTAssertTrue(recentFrames[0].timestamp <= recentFrames[1].timestamp)
        XCTAssertTrue(recentFrames[1].timestamp <= recentFrames[2].timestamp)
    }
    
    // MARK: - Helpers
    
    private static func makeSineWave(frequency: Float, sampleRate: Int, frameCount: Int) -> [Float] {
        (0..<frameCount).map { index in
            sin(2.0 * .pi * frequency * Float(index) / Float(sampleRate))
        }
    }
}

private extension XCTestCase {
    /// Helper to assert async throws
    func XCTAssertThrowsErrorAsync<T>(
        _ expression: @autoclosure () async throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line,
        _ errorHandler: @escaping (Error) -> Void
    ) async {
        do {
            _ = try await expression()
            let failureMessage = message()
            let composedMessage = failureMessage.isEmpty ? "Expected expression to throw" : failureMessage
            XCTFail(composedMessage, file: file, line: line)
        } catch {
            errorHandler(error)
        }
    }
}
