//
//  MockAudioGainControl.swift
//  AudioCoreTests
//
//  Mock implementation of AudioGainControlProtocol for testing
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

@testable import AudioCore
@testable import Shared

/// Mock implementation of AudioGainControlProtocol for testing
public final class MockAudioGainControl: AudioGainControlProtocol, @unchecked Sendable {
    /// Track-specific gains indexed by track ID
    private var trackGains: [UUID: Float] = [:]
    
    /// Global gain in dB (default: 0.0)
    private var globalGain: Float = 0.0
    
    /// Call tracking
    public var getTrackGainCallCount = 0
    public var setTrackGainCallCount = 0
    public var removeTrackGainCallCount = 0
    public var getGlobalGainCallCount = 0
    public var setGlobalGainCallCount = 0
    public var getEffectiveGainCallCount = 0
    public var gainDBToLinearCallCount = 0
    public var linearToGainDBCallCount = 0
    
    /// Tracks which methods were called
    public var getTrackGainCalls: [UUID] = []
    public var setTrackGainCalls: [(gain: Float, trackID: UUID)] = []
    public var removeTrackGainCalls: [UUID] = []
    public var setGlobalGainCalls: [Float] = []
    
    /// Configurable behavior
    public var shouldFailGetTrackGain = false
    public var shouldFailSetTrackGain = false
    public var shouldFailGetEffectiveGain = false
    
    public init() {}
    
    public func getTrackGain(for track: Shared.Track) async -> Float? {
        getTrackGainCallCount += 1
        getTrackGainCalls.append(track.id)
        
        if shouldFailGetTrackGain {
            return nil
        }
        
        return trackGains[track.id]
    }
    
    public func setTrackGain(_ gain: Float, for track: Shared.Track) async {
        setTrackGainCallCount += 1
        setTrackGainCalls.append((gain: gain, trackID: track.id))
        
        if shouldFailSetTrackGain {
            return
        }
        
        trackGains[track.id] = gain
    }
    
    public func removeTrackGain(for track: Shared.Track) async {
        removeTrackGainCallCount += 1
        removeTrackGainCalls.append(track.id)
        trackGains.removeValue(forKey: track.id)
    }
    
    public func getGlobalGain() async -> Float {
        getGlobalGainCallCount += 1
        return globalGain
    }
    
    public func setGlobalGain(_ gain: Float) async {
        setGlobalGainCallCount += 1
        setGlobalGainCalls.append(gain)
        globalGain = gain
    }
    
    public func getEffectiveGain(for track: Shared.Track) async -> Float {
        getEffectiveGainCallCount += 1
        
        if shouldFailGetEffectiveGain {
            return 0.0
        }
        
        let trackGain = trackGains[track.id] ?? 0.0
        return globalGain + trackGain
    }
    
    public func gainDBToLinear(_ gainDB: Float) -> Float {
        gainDBToLinearCallCount += 1
        // Standard formula: linear = 10^(dB/20)
        if gainDB.isInfinite || gainDB.isNaN {
            return 1.0
        }
        return pow(10.0, gainDB / 20.0)
    }
    
    public func linearToGainDB(_ linear: Float) -> Float {
        linearToGainDBCallCount += 1
        // Standard formula: dB = 20 * log10(linear)
        if linear.isNaN || linear.isInfinite {
            return 0.0
        }
        if linear <= 0.0 {
            if linear == 0.0 {
                return -Float.infinity
            } else {
                return Float.nan
            }
        }
        return 20.0 * log10(linear)
    }
    
    /// Reset mock state
    public func reset() {
        trackGains.removeAll()
        globalGain = 0.0
        getTrackGainCallCount = 0
        setTrackGainCallCount = 0
        removeTrackGainCallCount = 0
        getGlobalGainCallCount = 0
        setGlobalGainCallCount = 0
        getEffectiveGainCallCount = 0
        gainDBToLinearCallCount = 0
        linearToGainDBCallCount = 0
        getTrackGainCalls.removeAll()
        setTrackGainCalls.removeAll()
        removeTrackGainCalls.removeAll()
        setGlobalGainCalls.removeAll()
        shouldFailGetTrackGain = false
        shouldFailSetTrackGain = false
        shouldFailGetEffectiveGain = false
    }
}
