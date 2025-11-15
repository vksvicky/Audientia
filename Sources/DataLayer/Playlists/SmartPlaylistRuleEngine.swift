//
//  SmartPlaylistRuleEngine.swift
//  DataLayer
//
//  Smart playlist rule evaluation engine
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Protocol for smart playlist rule evaluation
public protocol SmartPlaylistRuleEngineProtocol: Sendable {
    /// Evaluate rules against a track
    /// - Parameters:
    ///   - rules: Smart playlist rules to evaluate
    ///   - track: Track to evaluate
    /// - Returns: True if track matches rules, false otherwise
    func evaluate(rules: SmartPlaylistRules, against track: Track) -> Bool
    
    /// Filter tracks based on rules
    /// - Parameters:
    ///   - rules: Smart playlist rules
    ///   - tracks: Array of tracks to filter
    /// - Returns: Array of tracks that match the rules
    func filter(tracks: [Track], matching rules: SmartPlaylistRules) -> [Track]
}

/// Smart playlist rule evaluation engine
public final class SmartPlaylistRuleEngine: SmartPlaylistRuleEngineProtocol, @unchecked Sendable {
    
    /// Initialize the rule engine
    public init() {}
    
    /// Evaluate rules against a track
    public func evaluate(rules: SmartPlaylistRules, against track: Track) -> Bool {
        guard rules.isValid else {
            return false
        }
        
        // If no rules, no tracks match
        guard !rules.rules.isEmpty else {
            return false
        }
        
        // Evaluate rules with logical operators
        var result: Bool?
        
        for rule in rules.rules {
            let ruleResult = evaluate(rule: rule, against: track)
            
            if let previousResult = result, let logicalOp = rule.logicalOperator {
                // Combine with previous result using logical operator from current rule
                switch logicalOp {
                case .and:
                    result = previousResult && ruleResult
                case .or:
                    result = previousResult || ruleResult
                }
            } else {
                // First rule (no logical operator) or no previous result
                result = ruleResult
            }
        }
        
        return result ?? false
    }
    
    /// Filter tracks based on rules
    public func filter(tracks: [Track], matching rules: SmartPlaylistRules) -> [Track] {
        tracks.filter { evaluate(rules: rules, against: $0) }
    }
    
    // MARK: - Private Methods
    
    /// Evaluate a single rule against a track
    private func evaluate(rule: SmartPlaylistRule, against track: Track) -> Bool {
        let fieldValue = getFieldValue(field: rule.field, from: track)
        return compare(value: fieldValue, operator: rule.operator, against: rule.value)
    }
    
    /// Get field value from track
    private func getFieldValue(field: SmartPlaylistRule.Field, from track: Track) -> String {
        switch field {
        case .title:
            return track.title
        case .artist:
            return track.artist
        case .album:
            return track.album
        case .genre:
            return track.genre ?? ""
        case .year:
            return track.year.map { String($0) } ?? ""
        case .rating:
            return track.rating.map { String($0) } ?? ""
        case .playCount:
            // Track doesn't have playCount field, return "0" for now
            return "0"
        case .dateAdded:
            // Track doesn't have dateAdded, return empty for now
            return ""
        case .duration:
            return String(format: "%.2f", track.duration)
        }
    }
    
    /// Compare field value with rule value using operator
    private func compare(value: String, operator: SmartPlaylistRule.Operator, against ruleValue: String) -> Bool {
        let normalizedValue = value.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedRuleValue = ruleValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch `operator` {
        case .equals:
            return normalizedValue == normalizedRuleValue
        case .contains:
            return normalizedValue.contains(normalizedRuleValue)
        case .startsWith:
            return normalizedValue.hasPrefix(normalizedRuleValue)
        case .endsWith:
            return normalizedValue.hasSuffix(normalizedRuleValue)
        case .notEquals:
            return normalizedValue != normalizedRuleValue
        case .greaterThan, .greaterThanOrEqual, .lessThan, .lessThanOrEqual:
            return compareNumericOrString(
                value: normalizedValue,
                operator: `operator`,
                against: normalizedRuleValue
            )
        }
    }
    
    /// Compare numeric or string values for comparison operators
    private func compareNumericOrString(
        value: String,
        operator: SmartPlaylistRule.Operator,
        against ruleValue: String
    ) -> Bool {
        // Try numeric comparison first
        if let valueNum = Double(value), let ruleNum = Double(ruleValue) {
            return compareNumeric(value: valueNum, operator: `operator`, against: ruleNum)
        }
        // Fall back to string comparison
        return compareString(value: value, operator: `operator`, against: ruleValue)
    }
    
    /// Compare numeric values
    private func compareNumeric(
        value: Double,
        operator: SmartPlaylistRule.Operator,
        against ruleValue: Double
    ) -> Bool {
        switch `operator` {
        case .greaterThan:
            return value > ruleValue
        case .greaterThanOrEqual:
            return value >= ruleValue
        case .lessThan:
            return value < ruleValue
        case .lessThanOrEqual:
            return value <= ruleValue
        default:
            return false
        }
    }
    
    /// Compare string values lexicographically
    private func compareString(
        value: String,
        operator: SmartPlaylistRule.Operator,
        against ruleValue: String
    ) -> Bool {
        switch `operator` {
        case .greaterThan:
            return value > ruleValue
        case .greaterThanOrEqual:
            return value >= ruleValue
        case .lessThan:
            return value < ruleValue
        case .lessThanOrEqual:
            return value <= ruleValue
        default:
            return false
        }
    }
}
