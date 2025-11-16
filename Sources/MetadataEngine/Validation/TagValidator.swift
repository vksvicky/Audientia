//
//  TagValidator.swift
//  MetadataEngine
//
//  Validates tag metadata before writing
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Validation result for tag metadata
public struct TagValidationResult: Sendable {
    /// Whether the track passes all validation rules
    public let isValid: Bool
    
    /// List of validation errors (empty if valid)
    public let errors: [TagValidationError]
    
    public init(isValid: Bool, errors: [TagValidationError]) {
        self.isValid = isValid
        self.errors = errors
    }
}

/// Validation errors for tag metadata
public enum TagValidationError: Error, Sendable, Equatable {
    /// Year is outside valid range (1888 to current year + 1)
    case invalidYear(Int)
    
    /// Track number is outside valid range (1 to 9999)
    case invalidTrackNumber(Int)
    
    /// Disc number is outside valid range (1 to 99)
    case invalidDiscNumber(Int)
}

/// Validates tag metadata before writing
public final class TagValidator: @unchecked Sendable {
    
    /// Minimum valid year (1888 - first recorded music)
    private let minimumYear = 1888
    
    /// Maximum valid year (current year + 1 for pre-releases)
    private var maximumYear: Int {
        Calendar.current.component(.year, from: Date()) + 1
    }
    
    /// Minimum valid track number
    private let minimumTrackNumber = 1
    
    /// Maximum valid track number
    private let maximumTrackNumber = 9999
    
    /// Minimum valid disc number
    private let minimumDiscNumber = 1
    
    /// Maximum valid disc number
    private let maximumDiscNumber = 99
    
    public init() {}
    
    /// Validate a track's metadata
    /// - Parameter track: The track to validate
    /// - Returns: Validation result with isValid flag and list of errors
    public func validate(track: Track) -> TagValidationResult {
        var errors: [TagValidationError] = []
        
        // Validate year if present
        if let year = track.year {
            if year < minimumYear || year > maximumYear {
                errors.append(.invalidYear(year))
            }
        }
        
        // Validate track number if present
        if let trackNumber = track.trackNumber {
            if trackNumber < minimumTrackNumber || trackNumber > maximumTrackNumber {
                errors.append(.invalidTrackNumber(trackNumber))
            }
        }
        
        // Validate disc number if present
        if let discNumber = track.discNumber {
            if discNumber < minimumDiscNumber || discNumber > maximumDiscNumber {
                errors.append(.invalidDiscNumber(discNumber))
            }
        }
        
        // Text fields (title, artist, album, genre) are allowed to be:
        // - Empty (may fall back to filename or defaults)
        // - Very long (may be truncated by some formats)
        // - Contain special characters or Unicode (handled by encoding)
        // No validation needed for text fields
        
        return TagValidationResult(
            isValid: errors.isEmpty,
            errors: errors
        )
    }
}
