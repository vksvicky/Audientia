//
//  MockFFmpegWrapper.swift
//  DataLayerTests
//
//  Mock implementation of FFmpegWrapperProtocol for testing
//

import Foundation

@testable import DataLayer
@testable import Shared

actor MockFFmpegWrapper: FFmpegWrapperProtocol {
    var shouldSucceed = true
    var mockError: TranscodeError?
    var mockIsAvailable = true
    var mockVersion: String? = "ffmpeg version 6.0"
    
    private(set) var transcodeCalled = false
    private(set) var lastInputPath: String?
    private(set) var lastOutputPath: String?
    private(set) var lastFormat: AudioFormat?
    private(set) var lastBitrate: Int?
    private(set) var progressCallbacks: [Double] = []
    
    func transcode(
        params: TranscodeParams,
        progress: @escaping (Double) -> Void
    ) async throws {
        transcodeCalled = true
        lastInputPath = params.inputPath
        lastOutputPath = params.outputPath
        lastFormat = params.format
        lastBitrate = params.bitrate
        
        if !shouldSucceed {
            throw mockError ?? .transcodingFailed("Mock error")
        }
        
        // Simulate progress
        for progressValue in stride(from: 0.0, through: 1.0, by: 0.1) {
            progress(progressValue)
            progressCallbacks.append(progressValue)
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        // Create output file
        FileManager.default.createFile(atPath: params.outputPath, contents: Data(), attributes: nil)
    }
    
    func isAvailable() async -> Bool {
        mockIsAvailable
    }
    
    func getVersion() async -> String? {
        mockVersion
    }
    
    func setShouldSucceed(_ value: Bool) {
        shouldSucceed = value
    }
    
    func setMockError(_ error: TranscodeError) {
        mockError = error
        shouldSucceed = false
    }
    
    func setMockIsAvailable(_ value: Bool) {
        mockIsAvailable = value
    }
    
    func reset() {
        shouldSucceed = true
        mockError = nil
        mockIsAvailable = true
        mockVersion = "ffmpeg version 6.0"
        transcodeCalled = false
        lastInputPath = nil
        lastOutputPath = nil
        lastFormat = nil
        lastBitrate = nil
        progressCallbacks.removeAll()
    }
}
