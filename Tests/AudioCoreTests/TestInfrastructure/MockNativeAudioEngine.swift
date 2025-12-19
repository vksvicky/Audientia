//
//  MockNativeAudioEngine.swift
//  AudioCoreTests
//
//  Test double for the native audio bridge (CAudioEngine).
//

@testable import AudioCore
import Foundation

@MainActor
final class MockNativeAudioEngine: NativeAudioEngineProtocol {
    var loadFileCalls: [String] = []
    var playCallCount = 0
    var pauseCallCount = 0
    var stopCallCount = 0
    var seekCalls: [TimeInterval] = []
    var volumeValues: [Float] = []
    
    // Alias for test compatibility - returns Double array from Float array
    var setVolumeCalls: [Double] {
        volumeValues.map { Double($0) }
    }

    var loadResult = true
    var playResult = true
    var seekResult = true
    var shouldPlaySucceed: Bool {
        get { playResult }
        set { playResult = newValue }
    }

    var currentPosition: TimeInterval = 0.0
    var duration: TimeInterval = 2.0
    var nextLoadDuration: TimeInterval?
    var lastSetRate: Float = 1.0

    func loadFile(_ path: String) async -> Bool {
        loadFileCalls.append(path)
        currentPosition = 0.0
        if let override = nextLoadDuration {
            duration = override
            nextLoadDuration = nil
        }
        return loadResult
    }

    func play() async -> Bool {
        playCallCount += 1
        return playResult
    }

    func pause() {
        pauseCallCount += 1
    }

    func stop() {
        stopCallCount += 1
        currentPosition = 0.0
    }

    func seek(to position: TimeInterval) async -> Bool {
        seekCalls.append(position)
        currentPosition = position
        return seekResult
    }

    func setVolume(_ volume: Float) {
        volumeValues.append(volume)
    }
    
    func setRate(_ rate: Float) {
        lastSetRate = rate
    }
    
    func getRate() -> Float {
        lastSetRate
    }
}
