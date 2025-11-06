//
//  TestFixtures.swift
//  AudioCoreTests
//
//  Test fixtures and sample files for integration testing
//

import Foundation

/// Test fixtures for integration testing with real audio files
enum TestFixtures {
    /// Base directory for test fixtures
    static var fixturesDirectory: URL {
        let testBundle = Bundle(for: AudioCoreTestsBundle.self)
        guard let fixturesURL = testBundle.url(forResource: "Fixtures", withExtension: nil) else {
            fatalError("Test fixtures directory not found. Please add Fixtures directory to test bundle.")
        }
        return fixturesURL
    }
    
    /// Get path to a test audio file
    /// - Parameters:
    ///   - filename: Name of the audio file
    ///   - format: Audio format (mp3, flac, aac, etc.)
    /// - Returns: URL to the test file, or nil if not found
    static func audioFile(filename: String, format: String) -> URL? {
        let fileURL = fixturesDirectory
            .appendingPathComponent("Audio")
            .appendingPathComponent(format)
            .appendingPathComponent(filename)
        
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    
    /// Get path to a sample MP3 file
    static func sampleMP3() -> URL? {
        audioFile(filename: "sample.mp3", format: "mp3")
    }
    
    /// Get path to a sample FLAC file
    static func sampleFLAC() -> URL? {
        audioFile(filename: "sample.flac", format: "flac")
    }
    
    /// Get path to a sample AAC file
    static func sampleAAC() -> URL? {
        audioFile(filename: "sample.aac", format: "aac")
    }
    
    /// Get path to a sample WAV file
    static func sampleWAV() -> URL? {
        audioFile(filename: "sample.wav", format: "wav")
    }
    
    /// Check if a test file exists
    /// - Parameter url: URL to check
    /// - Returns: True if file exists
    static func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
}

/// Bundle marker class for finding test resources
private class AudioCoreTestsBundle {}
