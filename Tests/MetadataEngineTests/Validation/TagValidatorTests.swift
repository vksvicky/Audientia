//
//  TagValidatorTests.swift
//  MetadataEngineTests
//
//  TDD tests for TagValidator following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for TagValidator
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class TagValidatorTests: XCTestCase {
    
    var validator: TagValidator!
    
    override func setUp() async throws {
        try await super.setUp()
        validator = TagValidator()
    }
    
    override func tearDown() async throws {
        validator = nil
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Creates a valid track for testing
    private func createValidTrack(
        title: String = "Test Title",
        artist: String = "Test Artist",
        album: String = "Test Album",
        year: Int? = 2023,
        trackNumber: Int? = 1,
        discNumber: Int? = 1,
        genre: String? = "Rock"
    ) -> Track {
        Track(
            title: title,
            artist: artist,
            album: album,
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100,
            year: year,
            trackNumber: trackNumber,
            discNumber: discNumber,
            genre: genre
        )
    }
    
    // MARK: - Right: Are the Results Right?
    
    /// Test that valid track passes validation
    func testValidTrackPassesValidation() {
        // Given - Valid track
        let track = createValidTrack()
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should pass validation
        XCTAssertTrue(result.isValid, "Valid track should pass validation")
        XCTAssertTrue(result.errors.isEmpty, "Valid track should have no errors")
    }
    
    /// Test that validation returns correct error types
    func testValidationReturnsCorrectErrorTypes() {
        // Given - Track with invalid year
        let track = createValidTrack(year: 1800) // Year too old
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should have year validation error
        XCTAssertFalse(result.isValid, "Track with invalid year should fail validation")
        XCTAssertTrue(result.errors.contains { error in
            if case .invalidYear = error {
                return true
            }
            return false
        }, "Should have invalidYear error")
    }
    
    // MARK: - Boundary Conditions
    
    /// Test validation with empty title
    func testValidationWithEmptyTitle() {
        // Given - Track with empty title
        let track = createValidTrack(title: "")
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should pass (empty title is allowed, may fall back to filename)
        XCTAssertTrue(result.isValid, "Empty title should be allowed")
    }
    
    /// Test validation with very long title
    func testValidationWithVeryLongTitle() {
        // Given - Track with very long title (1000 characters)
        let longTitle = String(repeating: "A", count: 1000)
        let track = createValidTrack(title: longTitle)
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should pass (long titles are allowed, though may be truncated by some formats)
        XCTAssertTrue(result.isValid, "Very long title should be allowed")
    }
    
    /// Test validation with year at minimum boundary (1888 - first recorded music)
    func testValidationWithMinimumYear() {
        // Given - Track with year 1888
        let track = createValidTrack(year: 1888)
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should pass
        XCTAssertTrue(result.isValid, "Year 1888 should be valid")
    }
    
    /// Test validation with year at maximum boundary (current year + 1)
    func testValidationWithMaximumYear() {
        // Given - Track with year in the future (current year + 1)
        let currentYear = Calendar.current.component(.year, from: Date())
        let track = createValidTrack(year: currentYear + 1)
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should pass (future year is allowed for pre-releases)
        XCTAssertTrue(result.isValid, "Future year should be allowed")
    }
    
    /// Test validation with year below minimum (before recorded music)
    func testValidationWithYearBelowMinimum() {
        // Given - Track with year before 1888
        let track = createValidTrack(year: 1887)
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should fail
        XCTAssertFalse(result.isValid, "Year before 1888 should fail validation")
        XCTAssertTrue(result.errors.contains { error in
            if case .invalidYear = error {
                return true
            }
            return false
        }, "Should have invalidYear error")
    }
    
    /// Test validation with track number at minimum (1)
    func testValidationWithMinimumTrackNumber() {
        // Given - Track with track number 1
        let track = createValidTrack(trackNumber: 1)
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should pass
        XCTAssertTrue(result.isValid, "Track number 1 should be valid")
    }
    
    /// Test validation with track number at maximum (9999)
    func testValidationWithMaximumTrackNumber() {
        // Given - Track with track number 9999
        let track = createValidTrack(trackNumber: 9999)
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should pass
        XCTAssertTrue(result.isValid, "Track number 9999 should be valid")
    }
    
    /// Test validation with track number below minimum (0)
    func testValidationWithTrackNumberBelowMinimum() {
        // Given - Track with track number 0
        let track = createValidTrack(trackNumber: 0)
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should fail
        XCTAssertFalse(result.isValid, "Track number 0 should fail validation")
        XCTAssertTrue(result.errors.contains { error in
            if case .invalidTrackNumber = error {
                return true
            }
            return false
        }, "Should have invalidTrackNumber error")
    }
    
    /// Test validation with track number above maximum (10000)
    func testValidationWithTrackNumberAboveMaximum() {
        // Given - Track with track number 10000
        let track = createValidTrack(trackNumber: 10000)
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should fail
        XCTAssertFalse(result.isValid, "Track number above 9999 should fail validation")
        XCTAssertTrue(result.errors.contains { error in
            if case .invalidTrackNumber = error {
                return true
            }
            return false
        }, "Should have invalidTrackNumber error")
    }
    
    /// Test validation with disc number at minimum (1)
    func testValidationWithMinimumDiscNumber() {
        // Given - Track with disc number 1
        let track = createValidTrack(discNumber: 1)
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should pass
        XCTAssertTrue(result.isValid, "Disc number 1 should be valid")
    }
    
    /// Test validation with disc number at maximum (99)
    func testValidationWithMaximumDiscNumber() {
        // Given - Track with disc number 99
        let track = createValidTrack(discNumber: 99)
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should pass
        XCTAssertTrue(result.isValid, "Disc number 99 should be valid")
    }
    
    /// Test validation with disc number below minimum (0)
    func testValidationWithDiscNumberBelowMinimum() {
        // Given - Track with disc number 0
        let track = createValidTrack(discNumber: 0)
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should fail
        XCTAssertFalse(result.isValid, "Disc number 0 should fail validation")
        XCTAssertTrue(result.errors.contains { error in
            if case .invalidDiscNumber = error {
                return true
            }
            return false
        }, "Should have invalidDiscNumber error")
    }
    
    /// Test validation with disc number above maximum (100)
    func testValidationWithDiscNumberAboveMaximum() {
        // Given - Track with disc number 100
        let track = createValidTrack(discNumber: 100)
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should fail
        XCTAssertFalse(result.isValid, "Disc number above 99 should fail validation")
        XCTAssertTrue(result.errors.contains { error in
            if case .invalidDiscNumber = error {
                return true
            }
            return false
        }, "Should have invalidDiscNumber error")
    }
    
    // MARK: - Inverse Relationships
    
    /// Test validation: valid → invalid → valid
    func testValidationInverseRelationship() {
        // Given - Valid track
        var track = createValidTrack()
        var result = validator.validate(track: track)
        XCTAssertTrue(result.isValid, "Initial track should be valid")
        
        // When - Make track invalid (invalid year)
        track = createValidTrack(year: 1800)
        result = validator.validate(track: track)
        
        // Then - Should be invalid
        XCTAssertFalse(result.isValid, "Track with invalid year should be invalid")
        
        // When - Make track valid again
        track = createValidTrack(year: 2023)
        result = validator.validate(track: track)
        
        // Then - Should be valid again
        XCTAssertTrue(result.isValid, "Track with valid year should be valid again")
    }
    
    // MARK: - Cross-Check Using Other Means
    
    /// Test validation results match manual validation
    func testValidationMatchesManualValidation() {
        // Given - Track with known invalid values
        let track = createValidTrack(
            year: 1800, // Invalid: too old
            trackNumber: 0, // Invalid: too low
            discNumber: 100 // Invalid: too high
        )
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should have exactly 3 errors (manual count)
        XCTAssertFalse(result.isValid, "Track should be invalid")
        XCTAssertEqual(result.errors.count, 3, "Should have exactly 3 validation errors")
        
        // Verify error types
        let errorTypes = Set(result.errors.map { error in
            switch error {
            case .invalidYear: return "invalidYear"
            case .invalidTrackNumber: return "invalidTrackNumber"
            case .invalidDiscNumber: return "invalidDiscNumber"
            }
        })
        XCTAssertEqual(errorTypes.count, 3, "Should have 3 different error types")
        XCTAssertTrue(errorTypes.contains("invalidYear"), "Should have invalidYear error")
        XCTAssertTrue(errorTypes.contains("invalidTrackNumber"), "Should have invalidTrackNumber error")
        XCTAssertTrue(errorTypes.contains("invalidDiscNumber"), "Should have invalidDiscNumber error")
    }
    
    // MARK: - Error Conditions
    
    /// Test validation with nil optional fields (should pass)
    func testValidationWithNilOptionalFields() {
        // Given - Track with nil optional fields
        let track = createValidTrack(
            year: nil,
            trackNumber: nil,
            discNumber: nil,
            genre: nil
        )
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should pass (nil optional fields are allowed)
        XCTAssertTrue(result.isValid, "Track with nil optional fields should pass validation")
        XCTAssertTrue(result.errors.isEmpty, "Should have no errors")
    }
    
    /// Test validation with special characters in text fields
    func testValidationWithSpecialCharacters() {
        // Given - Track with special characters
        let track = createValidTrack(
            title: "Test 🎵 Song",
            artist: "Artist & Band",
            album: "Album \"Title\"",
            genre: "Rock/Pop"
        )
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should pass (special characters are allowed)
        XCTAssertTrue(result.isValid, "Track with special characters should pass validation")
    }
    
    /// Test validation with Unicode characters
    func testValidationWithUnicodeCharacters() {
        // Given - Track with Unicode characters
        let track = createValidTrack(
            title: "テスト",
            artist: "艺术家",
            album: "Альбом"
        )
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should pass (Unicode characters are allowed)
        XCTAssertTrue(result.isValid, "Track with Unicode characters should pass validation")
    }
    
    // MARK: - Performance Characteristics
    
    /// Test validation performance
    func testValidationPerformance() {
        // Given - Valid track
        let track = createValidTrack()
        
        measure {
            // When - Validate track multiple times
            for _ in 0..<1000 {
                _ = validator.validate(track: track)
            }
        }
    }
    
    // MARK: - Edge Cases
    
    /// Test validation with whitespace-only strings
    func testValidationWithWhitespaceOnlyStrings() {
        // Given - Track with whitespace-only strings
        let track = createValidTrack(
            title: "   ",
            artist: "\t\t",
            album: "\n\n"
        )
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should pass (whitespace-only strings are allowed, may be trimmed later)
        XCTAssertTrue(result.isValid, "Track with whitespace-only strings should pass validation")
    }
    
    /// Test validation with negative year
    func testValidationWithNegativeYear() {
        // Given - Track with negative year
        let track = createValidTrack(year: -1)
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should fail
        XCTAssertFalse(result.isValid, "Track with negative year should fail validation")
        XCTAssertTrue(result.errors.contains { error in
            if case .invalidYear = error {
                return true
            }
            return false
        }, "Should have invalidYear error")
    }
    
    /// Test validation with very large year
    func testValidationWithVeryLargeYear() {
        // Given - Track with very large year
        let track = createValidTrack(year: 99999)
        
        // When - Validate track
        let result = validator.validate(track: track)
        
        // Then - Should fail
        XCTAssertFalse(result.isValid, "Track with very large year should fail validation")
        XCTAssertTrue(result.errors.contains { error in
            if case .invalidYear = error {
                return true
            }
            return false
        }, "Should have invalidYear error")
    }
}
