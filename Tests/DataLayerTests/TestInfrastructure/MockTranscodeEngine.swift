//
//  MockTranscodeEngine.swift
//  DataLayerTests
//
//  Mock implementation of TranscodeEngineProtocol for testing
//

import Foundation

@testable import DataLayer
@testable import Shared

actor MockTranscodeEngine: TranscodeEngineProtocol {
    var shouldSucceed = true
    var mockError: TranscodeError?
    var mockOutputPath: String?
    var mockNeedsTranscoding = false
    var shouldNeedTranscoding = false
    var mockEstimatedSize: Int64 = 0
    
    private(set) var transcodeCalled = false
    private(set) var transcodeCallCount = 0
    private(set) var needsTranscodingCalled = false
    private(set) var lastInputPath: String?
    private(set) var lastOutputPath: String?
    private(set) var lastProfile: TranscodeProfile?
    private(set) var progressCallbacks: [Double] = []
    
    func setMockError(_ error: TranscodeError) {
        mockError = error
        shouldSucceed = false
    }
    
    func setShouldSucceed(_ value: Bool) {
        shouldSucceed = value
    }
    
    func setMockOutputPath(_ path: String?) {
        mockOutputPath = path
    }
    
    func setMockNeedsTranscoding(_ value: Bool) {
        mockNeedsTranscoding = value
    }
    
    func setMockEstimatedSize(_ size: Int64) {
        mockEstimatedSize = size
    }
    
    func setShouldNeedTranscoding(_ value: Bool) {
        shouldNeedTranscoding = value
    }
    
    func transcode(
        inputPath: String,
        outputPath: String,
        profile: TranscodeProfile,
        progress: @escaping (Double) -> Void
    ) async throws -> String {
        transcodeCalled = true
        transcodeCallCount += 1
        lastInputPath = inputPath
        lastOutputPath = outputPath
        lastProfile = profile
        
        if !shouldSucceed {
            throw mockError ?? .transcodingFailed("Mock error")
        }
        
        // Simulate progress
        for progressValue in stride(from: 0.0, through: 1.0, by: 0.1) {
            progress(progressValue)
            progressCallbacks.append(progressValue)
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        return mockOutputPath ?? outputPath
    }
    
    func needsTranscoding(track: Track, profile: TranscodeProfile) async -> Bool {
        needsTranscodingCalled = true
        
        // Simple logic: check if format matches
        let trackExtension = (track.filePath as NSString).pathExtension.lowercased()
        let profileFormatExtension = profile.format.rawValue
        
        if shouldNeedTranscoding || mockNeedsTranscoding {
            return true
        }
        
        return trackExtension != profileFormatExtension
    }
    
    func estimateOutputSize(track: Track, profile: TranscodeProfile) async -> Int64 {
        if mockEstimatedSize > 0 {
            return mockEstimatedSize
        }
        
        // Simple estimation: bitrate * duration / 8 (bytes)
        let bitrateBytesPerSecond = Double(profile.bitrate * 1000) / 8.0
        return Int64(bitrateBytesPerSecond * track.duration)
    }
    
    func reset() {
        shouldSucceed = true
        mockError = nil
        mockOutputPath = nil
        mockNeedsTranscoding = false
        shouldNeedTranscoding = false
        mockEstimatedSize = 0
        transcodeCalled = false
        transcodeCallCount = 0
        needsTranscodingCalled = false
        lastInputPath = nil
        lastOutputPath = nil
        lastProfile = nil
        progressCallbacks.removeAll()
    }
}
