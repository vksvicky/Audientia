//
//  Language.swift
//  Shared
//
//  Supported languages for the application
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

/// Supported languages in the application
public enum Language: String, CaseIterable, Codable {
    case britishEnglish = "en_GB"
    case americanEnglish = "en_US"
    
    /// Display name for the language
    public var displayName: String {
        switch self {
        case .britishEnglish:
            "British English"
        case .americanEnglish:
            "American English"
        }
    }
    
    /// Short code for the language
    public var code: String {
        rawValue
    }
    
    /// Default language (British English)
    public static var `default`: Language {
        .britishEnglish
    }
}
