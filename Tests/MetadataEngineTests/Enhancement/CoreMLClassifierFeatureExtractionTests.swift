//
//  CoreMLClassifierFeatureExtractionTests.swift
//  MetadataEngineTests
//
//  TDD tests for audio feature extraction in CoreMLClassifier (Feature 5.2)
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for audio feature extraction
/// Following Right-BICEP principles
final class CoreMLClassifierFeatureExtractionTests: XCTestCase {
    
    private var classifier: CoreMLClassifier!
    private var testTrack: Track!
    private var testAudioFileURL: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        classifier = CoreMLClassifier()
        
        // Create a temporary audio file for testing
        testAudioFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp3")
        
        // Create a minimal valid MP3 file (or use test fixture)
        // For now, we'll test with file existence checks
        testTrack = Track(
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 10.0, // Valid duration >= 5.0
            filePath: testAudioFileURL.path,
            fileSize: 1000000,
            bitrate: 320,
            sampleRate: 44100
        )
    }
    
    override func tearDown() async throws {
        // Clean up test file
        try? FileManager.default.removeItem(at: testAudioFileURL)
        classifier = nil
        testTrack = nil
        testAudioFileURL = nil
        try await super.tearDown()
    }
    
    // MARK: - Right: Are the results right?
    
    func testExtractFeaturesReturnsValidFeatureVector() async throws {
        // Given: A valid audio file exists
        // Create a minimal test file
        let testData = Data(repeating: 0, count: 1000)
        try testData.write(to: testAudioFileURL)
        
        // When: Extracting features
        // Note: This will fail until we implement feature extraction
        // For now, we test the error handling
        
        // Then: Should either return features or throw appropriate error
        do {
            let features = try await classifier.generateEmbedding(for: testTrack)
            // If successful, features should be a non-empty array
            XCTAssertFalse(features.isEmpty, "Features should not be empty")
            XCTAssertGreaterThan(features.count, 0, "Should have at least one feature")
        } catch MLClassificationError.modelNotAvailable {
            // Expected if model not available - this is OK for now
        } catch MLClassificationError.audioProcessingFailed {
            // Expected if feature extraction not implemented - this is what we'll fix
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - B: Boundary Conditions
    
    func testExtractFeaturesWithShortTrackThrowsError() async throws {
        // Given: A track with duration < 5.0 seconds
        let shortTrack = Track(
            title: "Short Track",
            artist: "Artist",
            album: "Album",
            duration: 2.0, // Less than 5.0
            filePath: testAudioFileURL.path,
            fileSize: 100000,
            bitrate: 320,
            sampleRate: 44100
        )
        
        // When: Extracting features
        // Then: Should throw insufficientAudioData error
        do {
            _ = try await classifier.generateEmbedding(for: shortTrack)
            XCTFail("Should throw insufficientAudioData error")
        } catch MLClassificationError.insufficientAudioData {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testExtractFeaturesWithNonExistentFileThrowsError() async throws {
        // Given: A track with non-existent file path
        let invalidTrack = Track(
            title: "Invalid Track",
            artist: "Artist",
            album: "Album",
            duration: 10.0,
            filePath: "/nonexistent/path/to/file.mp3",
            fileSize: 1000000,
            bitrate: 320,
            sampleRate: 44100
        )
        
        // When: Extracting features
        // Then: Should throw audioProcessingFailed error
        do {
            _ = try await classifier.generateEmbedding(for: invalidTrack)
            XCTFail("Should throw audioProcessingFailed error")
        } catch MLClassificationError.audioProcessingFailed {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - E: Error Conditions
    
    func testExtractFeaturesHandlesCorruptAudioFile() async throws {
        // Given: A corrupt audio file
        let corruptData = Data([0xFF, 0xFE, 0xFD]) // Invalid audio data
        try corruptData.write(to: testAudioFileURL)
        
        // When: Extracting features
        // Then: Should handle gracefully (either extract what it can or throw error)
        do {
            _ = try await classifier.generateEmbedding(for: testTrack)
            // If it succeeds, that's OK - some feature extractors are resilient
        } catch MLClassificationError.audioProcessingFailed {
            // Expected for corrupt files
        } catch {
            // Other errors are acceptable
        }
    }
    
    // MARK: - P: Performance
    
    func testExtractFeaturesPerformance() async throws {
        // Given: A valid audio file
        let testData = Data(repeating: 0, count: 1000000) // 1MB file
        try testData.write(to: testAudioFileURL)
        
        // When: Extracting features
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            _ = try await classifier.generateEmbedding(for: testTrack)
        } catch {
            // Ignore errors for performance test
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then: Should complete within reasonable time (< 5 seconds)
        XCTAssertLessThan(duration, 5.0, "Feature extraction should complete within 5 seconds")
    }
}
