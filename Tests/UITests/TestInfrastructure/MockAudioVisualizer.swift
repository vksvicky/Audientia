//
//  MockAudioVisualizer.swift
//  UITests
//
//  Mock implementation of AudioVisualizerProtocol for testing
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AudioCore
import Foundation

/// Mock implementation of AudioVisualizerProtocol for testing
public final class MockAudioVisualizer: AudioVisualizerProtocol, @unchecked Sendable {
    public var frames: [AudioVisualizerFrame] = []
    public var shouldThrowError = false
    public var errorToThrow: AudioVisualizerError = .invalidAudioData
    public var processCallCount = 0
    public var latestFrameCallCount = 0
    public var recentFramesCallCount = 0
    
    public init() {}
    
    public func process(
        audioData: [Float],
        sampleRate: Int,
        channels: Int
    ) async throws -> AudioVisualizerFrame {
        processCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Create a mock frame with simulated magnitudes
        let magnitudeCount = 512
        var magnitudes = [Float](repeating: 0.0, count: magnitudeCount)
        
        // Simulate some frequency content
        for i in 0..<magnitudeCount {
            let frequency = Float(i) * Float(sampleRate) / Float(2048) // Assuming 2048 FFT size
            magnitudes[i] = sin(Float(i) * 0.1) * 50.0 + 20.0
        }
        
        let frame = AudioVisualizerFrame(
            magnitudes: magnitudes,
            timestamp: Date(),
            sampleRate: sampleRate,
            fftSize: 2048
        )
        
        frames.append(frame)
        return frame
    }
    
    public func latestFrame() async -> AudioVisualizerFrame? {
        latestFrameCallCount += 1
        return frames.last
    }
    
    public func recentFrames(limit: Int) async -> [AudioVisualizerFrame] {
        recentFramesCallCount += 1
        guard limit > 0 else { return [] }
        let count = min(limit, frames.count)
        return Array(frames.suffix(count))
    }
    
    // MARK: - Test Helpers
    
    /// Add a pre-configured frame to the mock
    public func addFrame(_ frame: AudioVisualizerFrame) {
        frames.append(frame)
    }
    
    /// Clear all frames
    public func clearFrames() {
        frames.removeAll()
    }
    
    /// Create a frame with specific frequency content
    public func createFrameWithFrequency(
        _ frequency: Float,
        sampleRate: Int = 44100,
        fftSize: Int = 2048
    ) -> AudioVisualizerFrame {
        let magnitudeCount = fftSize / 2
        var magnitudes = [Float](repeating: 0.0, count: magnitudeCount)
        
        // Create energy at the specified frequency bin
        let binIndex = Int(frequency * Float(fftSize) / Float(sampleRate))
        if binIndex >= 0 && binIndex < magnitudeCount {
            magnitudes[binIndex] = 100.0
            // Add some energy to adjacent bins for realism
            if binIndex > 0 {
                magnitudes[binIndex - 1] = 50.0
            }
            if binIndex < magnitudeCount - 1 {
                magnitudes[binIndex + 1] = 50.0
            }
        }
        
        return AudioVisualizerFrame(
            magnitudes: magnitudes,
            timestamp: Date(),
            sampleRate: sampleRate,
            fftSize: fftSize
        )
    }
}
