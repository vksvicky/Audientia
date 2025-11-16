//
//  TagValidatorBDDTests.swift
//  MetadataEngineTests
//
//  BDD tests for TagValidator
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// BDD tests for TagValidator
/// Scenarios: "As a user, I want to validate tag metadata before writing"
@MainActor
final class TagValidatorBDDTests: XCTestCase {
    
    var validator: TagValidator!
    
    override func setUp() async throws {
        try await super.setUp()
        validator = TagValidator()
    }
    
    override func tearDown() async throws {
        validator = nil
        try await super.tearDown()
    }
    
    // MARK: - Scenario: Valid Track
    
    /// Scenario: As a user, I want to validate a track with valid metadata
    /// Given: A track with valid title, artist, album, year, track number, and disc number
    /// When: I validate the track
    /// Then: The validation should pass with no errors
    func testUserValidatesTrackWithValidMetadata() {
        // Given - Track with valid metadata
        let track = Track(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100,
            year: 2023,
            trackNumber: 5,
            discNumber: 1,
            genre: "Rock"
        )
        
        // When - Validate the track
        let result = validator.validate(track: track)
        
        // Then - Validation should pass
        XCTAssertTrue(result.isValid, "Valid track should pass validation")
        XCTAssertTrue(result.errors.isEmpty, "Valid track should have no errors")
    }
    
    // MARK: - Scenario: Invalid Year
    
    /// Scenario: As a user, I want to be warned when I enter an invalid year
    /// Given: A track with a year before 1888 (first recorded music)
    /// When: I validate the track
    /// Then: The validation should fail with an invalidYear error
    func testUserEntersInvalidYearBefore1888() {
        // Given - Track with year before 1888
        let track = Track(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100,
            year: 1800,
            trackNumber: 1,
            discNumber: 1,
            genre: "Rock"
        )
        
        // When - Validate the track
        let result = validator.validate(track: track)
        
        // Then - Validation should fail with invalidYear error
        XCTAssertFalse(result.isValid, "Track with invalid year should fail validation")
        XCTAssertFalse(result.errors.isEmpty, "Should have validation errors")
        XCTAssertTrue(result.errors.contains { error in
            if case .invalidYear(1800) = error {
                return true
            }
            return false
        }, "Should have invalidYear error for year 1800")
    }
    
    /// Scenario: As a user, I want to be warned when I enter a year too far in the future
    /// Given: A track with a year far in the future (beyond current year + 1)
    /// When: I validate the track
    /// Then: The validation should fail with an invalidYear error
    func testUserEntersYearTooFarInFuture() {
        // Given - Track with year far in the future
        let currentYear = Calendar.current.component(.year, from: Date())
        let track = Track(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100,
            year: currentYear + 10, // Too far in the future
            trackNumber: 1,
            discNumber: 1,
            genre: "Rock"
        )
        
        // When - Validate the track
        let result = validator.validate(track: track)
        
        // Then - Validation should fail with invalidYear error
        XCTAssertFalse(result.isValid, "Track with year too far in future should fail validation")
        XCTAssertTrue(result.errors.contains { error in
            if case .invalidYear = error {
                return true
            }
            return false
        }, "Should have invalidYear error")
    }
    
    // MARK: - Scenario: Invalid Track Number
    
    /// Scenario: As a user, I want to be warned when I enter an invalid track number
    /// Given: A track with track number 0
    /// When: I validate the track
    /// Then: The validation should fail with an invalidTrackNumber error
    func testUserEntersInvalidTrackNumberZero() {
        // Given - Track with track number 0
        let track = Track(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100,
            year: 2023,
            trackNumber: 0, // Invalid: too low
            discNumber: 1,
            genre: "Rock"
        )
        
        // When - Validate the track
        let result = validator.validate(track: track)
        
        // Then - Validation should fail with invalidTrackNumber error
        XCTAssertFalse(result.isValid, "Track with track number 0 should fail validation")
        XCTAssertTrue(result.errors.contains { error in
            if case .invalidTrackNumber(0) = error {
                return true
            }
            return false
        }, "Should have invalidTrackNumber error for track number 0")
    }
    
    /// Scenario: As a user, I want to be warned when I enter a track number that's too high
    /// Given: A track with track number above 9999
    /// When: I validate the track
    /// Then: The validation should fail with an invalidTrackNumber error
    func testUserEntersTrackNumberTooHigh() {
        // Given - Track with track number above 9999
        let track = Track(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100,
            year: 2023,
            trackNumber: 10000, // Invalid: too high
            discNumber: 1,
            genre: "Rock"
        )
        
        // When - Validate the track
        let result = validator.validate(track: track)
        
        // Then - Validation should fail with invalidTrackNumber error
        XCTAssertFalse(result.isValid, "Track with track number above 9999 should fail validation")
        XCTAssertTrue(result.errors.contains { error in
            if case .invalidTrackNumber(10000) = error {
                return true
            }
            return false
        }, "Should have invalidTrackNumber error for track number 10000")
    }
    
    // MARK: - Scenario: Invalid Disc Number
    
    /// Scenario: As a user, I want to be warned when I enter an invalid disc number
    /// Given: A track with disc number 0
    /// When: I validate the track
    /// Then: The validation should fail with an invalidDiscNumber error
    func testUserEntersInvalidDiscNumberZero() {
        // Given - Track with disc number 0
        let track = Track(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100,
            year: 2023,
            trackNumber: 1,
            discNumber: 0, // Invalid: too low
            genre: "Rock"
        )
        
        // When - Validate the track
        let result = validator.validate(track: track)
        
        // Then - Validation should fail with invalidDiscNumber error
        XCTAssertFalse(result.isValid, "Track with disc number 0 should fail validation")
        XCTAssertTrue(result.errors.contains { error in
            if case .invalidDiscNumber(0) = error {
                return true
            }
            return false
        }, "Should have invalidDiscNumber error for disc number 0")
    }
    
    /// Scenario: As a user, I want to be warned when I enter a disc number that's too high
    /// Given: A track with disc number above 99
    /// When: I validate the track
    /// Then: The validation should fail with an invalidDiscNumber error
    func testUserEntersDiscNumberTooHigh() {
        // Given - Track with disc number above 99
        let track = Track(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100,
            year: 2023,
            trackNumber: 1,
            discNumber: 100, // Invalid: too high
            genre: "Rock"
        )
        
        // When - Validate the track
        let result = validator.validate(track: track)
        
        // Then - Validation should fail with invalidDiscNumber error
        XCTAssertFalse(result.isValid, "Track with disc number above 99 should fail validation")
        XCTAssertTrue(result.errors.contains { error in
            if case .invalidDiscNumber(100) = error {
                return true
            }
            return false
        }, "Should have invalidDiscNumber error for disc number 100")
    }
    
    // MARK: - Scenario: Multiple Validation Errors
    
    /// Scenario: As a user, I want to see all validation errors at once
    /// Given: A track with multiple invalid fields (year, track number, disc number)
    /// When: I validate the track
    /// Then: The validation should fail with all relevant errors
    func testUserSeesAllValidationErrorsAtOnce() {
        // Given - Track with multiple invalid fields
        let track = Track(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100,
            year: 1800, // Invalid
            trackNumber: 0, // Invalid
            discNumber: 100, // Invalid
            genre: "Rock"
        )
        
        // When - Validate the track
        let result = validator.validate(track: track)
        
        // Then - Validation should fail with all three errors
        XCTAssertFalse(result.isValid, "Track with multiple invalid fields should fail validation")
        XCTAssertEqual(result.errors.count, 3, "Should have exactly 3 validation errors")
        
        // Verify all error types are present
        let hasInvalidYear = result.errors.contains { error in
            if case .invalidYear = error {
                return true
            }
            return false
        }
        let hasInvalidTrackNumber = result.errors.contains { error in
            if case .invalidTrackNumber = error {
                return true
            }
            return false
        }
        let hasInvalidDiscNumber = result.errors.contains { error in
            if case .invalidDiscNumber = error {
                return true
            }
            return false
        }
        
        XCTAssertTrue(hasInvalidYear, "Should have invalidYear error")
        XCTAssertTrue(hasInvalidTrackNumber, "Should have invalidTrackNumber error")
        XCTAssertTrue(hasInvalidDiscNumber, "Should have invalidDiscNumber error")
    }
    
    // MARK: - Scenario: Optional Fields
    
    /// Scenario: As a user, I want to leave optional fields empty without validation errors
    /// Given: A track with nil optional fields (year, track number, disc number, genre)
    /// When: I validate the track
    /// Then: The validation should pass (nil optional fields are allowed)
    func testUserLeavesOptionalFieldsEmpty() {
        // Given - Track with nil optional fields
        let track = Track(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100,
            year: nil,
            trackNumber: nil,
            discNumber: nil,
            genre: nil
        )
        
        // When - Validate the track
        let result = validator.validate(track: track)
        
        // Then - Validation should pass
        XCTAssertTrue(result.isValid, "Track with nil optional fields should pass validation")
        XCTAssertTrue(result.errors.isEmpty, "Should have no validation errors")
    }
    
    // MARK: - Scenario: Special Characters and Unicode
    
    /// Scenario: As a user, I want to use special characters and Unicode in tag fields
    /// Given: A track with special characters and Unicode in text fields
    /// When: I validate the track
    /// Then: The validation should pass (special characters and Unicode are allowed)
    func testUserUsesSpecialCharactersAndUnicode() {
        // Given - Track with special characters and Unicode
        let track = Track(
            title: "Test 🎵 Song",
            artist: "Artist & Band",
            album: "Альбом \"Title\"",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100,
            year: 2023,
            trackNumber: 1,
            discNumber: 1,
            genre: "Rock/Pop"
        )
        
        // When - Validate the track
        let result = validator.validate(track: track)
        
        // Then - Validation should pass
        XCTAssertTrue(result.isValid, "Track with special characters and Unicode should pass validation")
        XCTAssertTrue(result.errors.isEmpty, "Should have no validation errors")
    }
}
