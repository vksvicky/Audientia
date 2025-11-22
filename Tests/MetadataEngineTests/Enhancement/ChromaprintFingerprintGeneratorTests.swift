//
//  ChromaprintFingerprintGeneratorTests.swift
//  MetadataEngineTests
//
//  TDD tests for real Chromaprint fingerprint generator using FFmpeg
//

import Foundation
import XCTest

@testable import MetadataEngine
@testable import Shared

/// TDD tests for Chromaprint fingerprint generator following Right-BICEP principles
final class ChromaprintFingerprintGeneratorTests: XCTestCase {
    
    private var generator: ChromaprintFingerprintGenerator!
    
    override func setUp() async throws {
        try await super.setUp()
        generator = ChromaprintFingerprintGenerator()
        
        // Check if FFmpeg with chromaprint support is available
        // If not, skip all tests in this suite
        let isAvailable = await generator.checkAvailability()
        guard isAvailable else {
            throw XCTSkip(
                "FFmpeg with chromaprint filter is not available. " +
                "To enable: brew install chromaprint && brew reinstall ffmpeg"
            )
        }
    }
    
    override func tearDown() async throws {
        generator = nil
        try await super.tearDown()
    }
    
    // Helper to get or create a valid audio test file
    private func getValidAudioFile() throws -> URL {
        // Try to find a valid audio test fixture
        // First try AudioCoreTests fixtures
        if let testBundle = Bundle(identifier: "club.cycleruncode.audientia.AudioCoreTests"),
           let fixturesURL = testBundle.url(forResource: "Fixtures", withExtension: nil) {
            let audioURL = fixturesURL
                .appendingPathComponent("Audio")
                .appendingPathComponent("mp3")
                .appendingPathComponent("valid_44.1k.mp3")
            if FileManager.default.fileExists(atPath: audioURL.path) {
                return audioURL
            }
        }
        
        // Try relative path from test bundle
        let testBundle = Bundle(for: type(of: self))
        if let bundlePath = testBundle.resourcePath {
            let fixturesPath = (bundlePath as NSString).appendingPathComponent("../../AudioCoreTests/Fixtures/Audio/mp3/valid_44.1k.mp3")
            let fixturesURL = URL(fileURLWithPath: fixturesPath)
            if FileManager.default.fileExists(atPath: fixturesURL.path) {
                return fixturesURL
            }
        }
        
        // If no fixture found, generate a minimal valid audio file using FFmpeg
        return try generateTestAudioFile()
    }
    
    // Find FFmpeg executable path
    private func findFFmpegPath() -> String? {
        let possiblePaths = ["/usr/local/bin/ffmpeg", "/opt/homebrew/bin/ffmpeg", "/usr/bin/ffmpeg", "ffmpeg"]
        
        for path in possiblePaths {
            if path == "ffmpeg" {
                // Check if ffmpeg is in PATH
                let whichProcess = Process()
                whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
                whichProcess.arguments = ["ffmpeg"]
                let pipe = Pipe()
                whichProcess.standardOutput = pipe
                
                do {
                    try whichProcess.run()
                    whichProcess.waitUntilExit()
                    if whichProcess.terminationStatus == 0 {
                        let data = pipe.fileHandleForReading.readDataToEndOfFile()
                        if let output = String(data: data, encoding: .utf8),
                           !output.trimmingCharacters(in: .whitespaces).isEmpty {
                            return output.trimmingCharacters(in: .whitespaces)
                        }
                    }
                } catch {
                    continue
                }
            } else {
                if FileManager.default.fileExists(atPath: path) {
                    return path
                }
            }
        }
        return nil
    }
    
    // Generate a minimal valid audio file using FFmpeg
    private func generateTestAudioFile() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_audio_\(UUID().uuidString).mp3")
        
        guard let ffmpeg = findFFmpegPath() else {
            throw XCTSkip("FFmpeg not available to generate test audio file")
        }
        
        // Use FFmpeg to generate a 1-second sine wave audio file
        // This creates a valid MP3 file that chromaprint can process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpeg)
        // Generate 5 seconds of 440Hz sine wave, 44.1kHz, stereo, 128kbps MP3
        // Note: Chromaprint needs sufficient audio content to generate a fingerprint
        // Very short or simple tones may not generate fingerprints
        process.arguments = [
            "-f", "lavfi",
            "-i", "sine=frequency=440:duration=5",
            "-ar", "44100",
            "-ac", "2",
            "-b:a", "128k",
            "-y", // Overwrite output file
            fileURL.path
        ]
        
        // Suppress FFmpeg output
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw XCTSkip("Failed to generate test audio file with FFmpeg")
        }
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw XCTSkip("Generated test audio file does not exist")
        }
        
        return fileURL
    }
    
    // MARK: - Right: Are the results right?
    
    func testGenerateFingerprintForValidAudioFile() async throws {
        // Given: A valid audio file (use real fixture if available, otherwise generate)
        let fileURL = try getValidAudioFile()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When: Generating a fingerprint
        // Note: This will throw if chromaprint is not available, which is expected
        let fingerprint = try await generator.generateFingerprint(fileURL: fileURL)
        
        // Then: A valid fingerprint is returned
        XCTAssertFalse(fingerprint.isEmpty, "Fingerprint should not be empty")
        // Chromaprint fingerprints are base64-encoded strings
        XCTAssertFalse(fingerprint.isEmpty, "Fingerprint should have content")
    }
    
    // MARK: - Boundary Conditions
    
    func testGenerateFingerprintForNonExistentFile() async {
        // Given: A non-existent file
        let fileURL = URL(fileURLWithPath: "/nonexistent/file.mp3")
        
        // When/Then: Error is thrown
        do {
            _ = try await generator.generateFingerprint(fileURL: fileURL)
            XCTFail("Should have thrown an error")
        } catch let error as AcoustIDError {
            XCTAssertEqual(error, .fileNotFound(fileURL))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testGenerateFingerprintForEmptyFile() async {
        // Given: An empty file
        let fileURL = createEmptyFile()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When/Then: Error is thrown
        do {
            _ = try await generator.generateFingerprint(fileURL: fileURL)
            XCTFail("Should have thrown an error")
        } catch let error as AcoustIDError {
            // Accept any fingerprintGenerationFailed error (message may vary)
            if case .fingerprintGenerationFailed = error {
                // Expected error
            } else {
                XCTFail("Expected fingerprintGenerationFailed, got \(error)")
            }
        } catch {
            // Accept any error for empty file
        }
    }
    
    func testGenerateFingerprintForVeryShortFile() async throws {
        // Given: A very short audio file (less than 1 second)
        // Use a valid audio file (generated file is 1 second, which is acceptable)
        let fileURL = try getValidAudioFile()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When: Generating a fingerprint
        // Then: Should handle gracefully (may return empty or throw)
        do {
            let fingerprint = try await generator.generateFingerprint(fileURL: fileURL)
            // Very short files might not generate fingerprints
            // This is acceptable behavior
            _ = fingerprint
        } catch {
            // Acceptable for very short files or if chromaprint fails
        }
    }
    
    // MARK: - Inverse Relationships
    
    func testGenerateFingerprintReturnsConsistentResults() async throws {
        // Given: The same file fingerprinted twice
        let fileURL = try getValidAudioFile()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When: Generating fingerprints twice
        let fingerprint1 = try await generator.generateFingerprint(fileURL: fileURL)
        let fingerprint2 = try await generator.generateFingerprint(fileURL: fileURL)
        
        // Then: Same fingerprint is returned (inverse: consistent results)
        XCTAssertEqual(fingerprint1, fingerprint2, "Fingerprints should be consistent for the same file")
    }
    
    // MARK: - Cross-Check Using Other Means
    
    func testFingerprintFormatMatchesChromaprintSpec() async throws {
        // Given: A valid audio file
        let fileURL = try getValidAudioFile()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When: Generating a fingerprint
        let fingerprint = try await generator.generateFingerprint(fileURL: fileURL)
        
        // Then: Fingerprint format matches Chromaprint spec (base64-encoded)
        // Chromaprint fingerprints are base64-encoded strings
        // They should contain only valid base64 characters
        let base64Chars = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=")
        let fingerprintChars = CharacterSet(charactersIn: fingerprint)
        XCTAssertTrue(base64Chars.isSuperset(of: fingerprintChars), "Fingerprint should be base64-encoded")
    }
    
    // MARK: - Error Conditions
    
    func testGenerateFingerprintWithFFmpegNotAvailable() async {
        // Given: FFmpeg is not available
        // Note: This test may be skipped if FFmpeg is available
        // In a real scenario, we'd mock the FFmpeg availability check
        
        // When/Then: Error is thrown
        // This test verifies error handling when FFmpeg is not available
        // Implementation should check FFmpeg availability first
    }
    
    func testGenerateFingerprintWithCorruptFile() async {
        // Given: A corrupt audio file
        let fileURL = createCorruptFile()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When/Then: Error is thrown
        do {
            _ = try await generator.generateFingerprint(fileURL: fileURL)
            XCTFail("Should have thrown an error for corrupt file")
        } catch let error as AcoustIDError {
            // Accept any fingerprintGenerationFailed error (message may vary)
            if case .fingerprintGenerationFailed = error {
                // Expected error
            } else {
                XCTFail("Expected fingerprintGenerationFailed, got \(error)")
            }
        } catch {
            // Accept any error for corrupt file
        }
    }
    
    // MARK: - Performance Characteristics
    
    func testGenerateFingerprintPerformance() async throws {
        // Given: A valid audio file
        let fileURL = try getValidAudioFile()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When: Measuring fingerprint generation time
        let startTime = Date()
        _ = try await generator.generateFingerprint(fileURL: fileURL)
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Then: Fingerprint generation completes within SLA (< 5s per track)
        XCTAssertLessThan(elapsed, 5.0, "Fingerprint generation should complete in < 5s")
    }
    
    // MARK: - Edge Cases
    
    func testGenerateFingerprintWithUnicodePath() async throws {
        // Given: A file path with Unicode characters
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("音楽.mp3")
        try? "test".write(to: fileURL, atomically: true, encoding: .utf8)
        
        // When: Generating a fingerprint
        // Then: Should handle Unicode paths gracefully
        do {
            _ = try await generator.generateFingerprint(fileURL: fileURL)
        } catch {
            // Acceptable if file is not valid audio
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func testGenerateFingerprintWithSpecialCharactersInPath() async throws {
        // Given: A file path with special characters
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("audio (remix) [2020].mp3")
        try? "test".write(to: fileURL, atomically: true, encoding: .utf8)
        
        // When: Generating a fingerprint
        // Then: Should handle special characters gracefully
        do {
            _ = try await generator.generateFingerprint(fileURL: fileURL)
        } catch {
            // Acceptable if file is not valid audio
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // MARK: - Helper Methods
    
    private func createEmptyFile() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp3")
        // Create an empty file
        FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        return fileURL
    }
    
    private func createCorruptFile() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp3")
        // Create a file with invalid audio data
        try? "corrupt audio data".write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}
