//
//  SmartPlaylistRules.swift
//  DataLayer
//
//  Smart playlist rule definitions
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Represents a smart playlist rule
public struct SmartPlaylistRule: Codable, Equatable, Sendable {
    /// Field to match against
    public enum Field: String, Codable, Sendable {
        case title
        case artist
        case album
        case genre
        case year
        case rating
        case playCount
        case dateAdded
        case duration
    }
    
    /// Comparison operator
    public enum Operator: String, Codable, Sendable {
        case equals
        case contains
        case startsWith
        case endsWith
        case greaterThan
        case lessThan
        case greaterThanOrEqual
        case lessThanOrEqual
        case notEquals
    }
    
    /// Logical operator for combining rules
    public enum LogicalOperator: String, Codable, Sendable {
        case and
        case or
    }
    
    public let field: Field
    public let `operator`: Operator
    public let value: String
    public let logicalOperator: LogicalOperator?
    
    public init(
        field: Field,
        operator: Operator,
        value: String,
        logicalOperator: LogicalOperator? = nil
    ) {
        self.field = field
        self.operator = `operator`
        self.value = value
        self.logicalOperator = logicalOperator
    }
}

/// Represents a set of smart playlist rules
public struct SmartPlaylistRules: Codable, Equatable, Sendable {
    public let rules: [SmartPlaylistRule]
    
    public init(rules: [SmartPlaylistRule]) {
        self.rules = rules
    }
    
    /// Check if rules are valid
    public var isValid: Bool {
        !rules.isEmpty
    }
}
