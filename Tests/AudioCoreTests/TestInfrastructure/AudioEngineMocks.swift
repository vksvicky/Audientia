// AudioEngineMocks.swift
// Audientia - Test Infrastructure for AudioCore Mocking
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

@testable import AudioCore
import Foundation
@testable import Shared
import XCTest

// Note: PlaybackState and AudioEngineError are now defined in AudioCore module

// MARK: - Audio Format

/// Audio format information
struct AudioFormat: Equatable {
    let sampleRate: Int
    let channels: Int
    let bitDepth: Int
    let format: String // "MP3", "FLAC", "AAC", etc.
}

// MARK: - Mock Audio Decoder Protocol

/// Protocol for audio decoders (to enable mocking)
protocol AudioDecoderProtocol {
    func detectFormat(from filePath: String) throws -> AudioFormat
    func decode(filePath: String, startTime: TimeInterval, duration: TimeInterval?) throws -> Data
    func getDuration(filePath: String) throws -> TimeInterval
}

// MARK: - Mock Audio Decoder

/// Mock implementation of audio decoder for testing
final class MockAudioDecoder: AudioDecoderProtocol {
    var detectFormatCallCount = 0
    var decodeCallCount = 0
    var getDurationCallCount = 0
    
    var mockFormat: AudioFormat?
    var mockDuration: TimeInterval?
    var mockDecodeData: Data?
    
    var shouldThrowError = false
    var errorToThrow: Error?
    
    func detectFormat(from filePath: String) throws -> AudioFormat {
        detectFormatCallCount += 1
        if shouldThrowError {
            throw errorToThrow ?? AudioEngineError.formatDetectionFailed
        }
        return mockFormat ?? AudioFormat(sampleRate: 44100, channels: 2, bitDepth: 16, format: "MP3")
    }
    
    func decode(filePath: String, startTime: TimeInterval, duration: TimeInterval?) throws -> Data {
        decodeCallCount += 1
        if shouldThrowError {
            throw errorToThrow ?? AudioEngineError.decodingFailed
        }
        return mockDecodeData ?? Data(count: 1024)
    }
    
    func getDuration(filePath: String) throws -> TimeInterval {
        getDurationCallCount += 1
        if shouldThrowError {
            throw errorToThrow ?? AudioEngineError.durationDetectionFailed
        }
        return mockDuration ?? 180.0
    }
}

// MARK: - Mock Audio Output Protocol

/// Protocol for audio output (to enable mocking)
protocol AudioOutputProtocol {
    func start() throws
    func stop()
    func pause()
    func resume()
    func setVolume(_ volume: Float)
    func getVolume() -> Float
    func write(_ data: Data) throws
}

// MARK: - Mock Audio Output

/// Mock implementation of audio output for testing
final class MockAudioOutput: AudioOutputProtocol {
    var startCallCount = 0
    var stopCallCount = 0
    var pauseCallCount = 0
    var resumeCallCount = 0
    var setVolumeCallCount = 0
    var writeCallCount = 0
    
    var currentVolume: Float = 1.0
    var isPlaying = false
    var isPaused = false
    
    var shouldThrowError = false
    var errorToThrow: Error?
    
    func start() throws {
        startCallCount += 1
        if shouldThrowError {
            throw errorToThrow ?? AudioEngineError.outputInitializationFailed
        }
        isPlaying = true
        isPaused = false
    }
    
    func stop() {
        stopCallCount += 1
        isPlaying = false
        isPaused = false
    }
    
    func pause() {
        pauseCallCount += 1
        isPaused = true
    }
    
    func resume() {
        resumeCallCount += 1
        isPaused = false
    }
    
    func setVolume(_ volume: Float) {
        setVolumeCallCount += 1
        currentVolume = max(0.0, min(1.0, volume))
    }
    
    func getVolume() -> Float {
        currentVolume
    }
    
    func write(_ data: Data) throws {
        writeCallCount += 1
        if shouldThrowError {
            throw errorToThrow ?? AudioEngineError.outputWriteFailed
        }
    }
}

// Note: AudioEngineError is now defined in AudioCore module

// MARK: - Mock File System

/// Mock file system for testing AudioEngine without real files
/// Conforms to FileSystemProtocol from AudioCore module
final class MockFileSystem: FileSystemProtocol {
    var existingFiles: Set<String> = []
    var fileSizes: [String: Int64] = [:]
    var shouldFail = false
    
    func fileExists(atPath path: String) -> Bool {
        if shouldFail {
            return false
        }
        return existingFiles.contains(path)
    }
    
    /// Add a file path to the mock file system
    /// - Parameters:
    ///   - path: File path to add
    ///   - size: File size in bytes (default: 1MB). If nil, attempts to get real file size
    func addFile(_ path: String, size: Int64? = nil) {
        existingFiles.insert(path)
        
        // If size not provided, try to get real file size
        if let size = size {
            fileSizes[path] = size
        } else {
            // Try to get actual file size from real file system
            if FileManager.default.fileExists(atPath: path),
               let attributes = try? FileManager.default.attributesOfItem(atPath: path),
               let realSize = attributes[.size] as? Int64 {
                fileSizes[path] = realSize
            } else {
                // Default size if file doesn't exist or can't get size
                fileSizes[path] = 1_000_000
            }
        }
    }
    
    /// Remove a file path from the mock file system
    func removeFile(_ path: String) {
        existingFiles.remove(path)
        fileSizes.removeValue(forKey: path)
    }
    
    /// Clear all files
    func clear() {
        existingFiles.removeAll()
        fileSizes.removeAll()
    }
}

// MARK: - Mock Format Decoding Coordinator

/// Mock coordinator for format decoding to keep unit tests deterministic
final class MockFormatDecodingCoordinator: FormatDecodingCoordinating {
    var decodeCalls: [String] = []
    var result: DecodedAudioFormat?
    var error: Error?
    var shouldFail = false
    var failureReason: String = "Decode failed"
    
    /// Supported extensions for validation (matches real decoders)
    var supportedExtensions: Set<String> = [
        // AVFoundation supported
        "mp3", "aac", "m4a", "wav", "aiff", "caf", "mp4",
        // FFmpeg supported
        "flac", "ogg", "opus", "alac", "ape"
    ]
    
    /// Whether to validate extensions (default: false for backward compatibility)
    var validateExtensions = false
    
    func decodeFormat(for filePath: String) async throws -> DecodedAudioFormat {
        decodeCalls.append(filePath)
        
        // If extension validation is enabled, check if extension is supported
        if validateExtensions {
            let fileExtension = URL(fileURLWithPath: filePath).pathExtension.lowercased()
            if fileExtension.isEmpty {
                throw FormatDecoderError.unsupportedFormat("")
            }
            if !supportedExtensions.contains(fileExtension) {
                throw FormatDecoderError.unsupportedFormat(fileExtension)
            }
        }
        
        if shouldFail {
            throw FormatDecoderError.decoderFailed(decoder: "Mock", reason: failureReason)
        }
        
        if let error {
            throw error
        }
        if let result {
            return result
        }
        return DecodedAudioFormat(
            codec: "Mock",
            sampleRate: 44_100,
            channelCount: 2,
            bitRate: 320,
            duration: 0
        )
    }
}
