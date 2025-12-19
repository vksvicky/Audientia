//
//  MockAudioNormaliser.swift
//  AudioCoreTests
//
//  Mock implementation of AudioNormalisationProtocol for testing
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
import Foundation

/// Mock implementation of AudioNormalisationProtocol for testing
public final class MockAudioNormaliser: AudioNormalisationProtocol, @unchecked Sendable {
    /// Structure to track analyzeNormalization calls
    public struct AnalyzeNormalizationCall {
        let audioData: [Float]
        let sampleRate: Int
        let channels: Int
        let mode: NormalizationMode
        let targetLevel: Float
    }
    
    /// Structure to track calculateLoudness calls
    public struct CalculateLoudnessCall {
        let audioData: [Float]
        let sampleRate: Int
        let channels: Int
    }
    
    /// Call tracking
    public var analyzeNormalizationCallCount = 0
    public var applyNormalizationCallCount = 0
    public var calculatePeakLevelCallCount = 0
    public var calculateRMSLevelCallCount = 0
    public var calculateLoudnessCallCount = 0
    
    /// Tracks which methods were called
    public var analyzeNormalizationCalls: [AnalyzeNormalizationCall] = []
    public var applyNormalizationCalls: [(audioData: [Float], gainDB: Float)] = []
    public var calculatePeakLevelCalls: [(audioData: [Float], channels: Int)] = []
    public var calculateRMSLevelCalls: [(audioData: [Float], channels: Int)] = []
    public var calculateLoudnessCalls: [CalculateLoudnessCall] = []
    
    /// Configurable return values
    public var mockNormalizationGain: Float = 0.0
    public var mockPeakLevel: Float = 0.0
    public var mockRMSLevel: Float = -20.0
    public var mockLoudness: Float = -23.0
    
    /// Configurable behavior
    public var shouldFailAnalysis = false
    public var shouldFailApplication = false
    public var shouldFailLoudness = false
    public var errorToThrow: AudioNormalisationError?
    
    public init() {}
    
    public func analyzeNormalization(
        audioData: [Float],
        sampleRate: Int,
        channels: Int,
        mode: NormalizationMode,
        targetLevel: Float
    ) async throws -> Float {
        analyzeNormalizationCallCount += 1
        analyzeNormalizationCalls.append(AnalyzeNormalizationCall(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels,
            mode: mode,
            targetLevel: targetLevel
        ))
        
        if shouldFailAnalysis {
            throw errorToThrow ?? AudioNormalisationError.analysisFailed("Mock analysis failure")
        }
        
        // Simulate the real implementation: call the appropriate calculation method
        // This ensures call counts are tracked correctly
        switch mode {
        case .peak:
            _ = await calculatePeakLevel(audioData: audioData, channels: channels)
        case .rms:
            _ = await calculateRMSLevel(audioData: audioData, channels: channels)
        case .loudness:
            _ = try await calculateLoudness(
                audioData: audioData,
                sampleRate: sampleRate,
                channels: channels
            )
        }
        
        // If mockNormalizationGain is explicitly set, use it (for backward compatibility)
        // Otherwise, calculate from current level and target level
        if mockNormalizationGain != 0.0 {
            return mockNormalizationGain
        } else {
            // Calculate gain from current level (using mock values)
            let currentLevel: Float
            switch mode {
            case .peak:
                currentLevel = mockPeakLevel
            case .rms:
                currentLevel = mockRMSLevel
            case .loudness:
                currentLevel = mockLoudness
            }
            return targetLevel - currentLevel
        }
    }
    
    public func applyNormalization(
        audioData: [Float],
        gainDB: Float
    ) async throws -> [Float] {
        applyNormalizationCallCount += 1
        applyNormalizationCalls.append((audioData: audioData, gainDB: gainDB))
        
        if shouldFailApplication {
            throw errorToThrow ?? AudioNormalisationError.normalizationFailed("Mock application failure")
        }
        
        // Apply gain to audio data
        let linearGain = pow(10.0, gainDB / 20.0)
        return audioData.map { $0 * linearGain }
    }
    
    public func calculatePeakLevel(
        audioData: [Float],
        channels: Int
    ) async -> Float {
        calculatePeakLevelCallCount += 1
        calculatePeakLevelCalls.append((audioData: audioData, channels: channels))
        return mockPeakLevel
    }
    
    public func calculateRMSLevel(
        audioData: [Float],
        channels: Int
    ) async -> Float {
        calculateRMSLevelCallCount += 1
        calculateRMSLevelCalls.append((audioData: audioData, channels: channels))
        return mockRMSLevel
    }
    
    public func calculateLoudness(
        audioData: [Float],
        sampleRate: Int,
        channels: Int
    ) async throws -> Float {
        calculateLoudnessCallCount += 1
        calculateLoudnessCalls.append(CalculateLoudnessCall(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        ))
        
        if shouldFailLoudness {
            throw errorToThrow ?? AudioNormalisationError.analysisFailed("Mock loudness calculation failure")
        }
        
        return mockLoudness
    }
    
    /// Reset mock state
    public func reset() {
        analyzeNormalizationCallCount = 0
        applyNormalizationCallCount = 0
        calculatePeakLevelCallCount = 0
        calculateRMSLevelCallCount = 0
        calculateLoudnessCallCount = 0
        analyzeNormalizationCalls.removeAll()
        applyNormalizationCalls.removeAll()
        calculatePeakLevelCalls.removeAll()
        calculateRMSLevelCalls.removeAll()
        calculateLoudnessCalls.removeAll()
        mockNormalizationGain = 0.0
        mockPeakLevel = 0.0
        mockRMSLevel = -20.0
        mockLoudness = -23.0
        shouldFailAnalysis = false
        shouldFailApplication = false
        shouldFailLoudness = false
        errorToThrow = nil
    }
}
