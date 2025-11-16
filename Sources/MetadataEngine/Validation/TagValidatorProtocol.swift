//
//  TagValidatorProtocol.swift
//  MetadataEngine
//
//  Protocol for tag validation
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Protocol for tag validation
public protocol TagValidatorProtocol: Sendable {
    /// Validate a track's metadata
    /// - Parameter track: The track to validate
    /// - Returns: Validation result with isValid flag and list of errors
    func validate(track: Track) -> TagValidationResult
}

/// Extension to make TagValidator conform to TagValidatorProtocol
extension TagValidator: TagValidatorProtocol {}
