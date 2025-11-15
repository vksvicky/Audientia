//
//  SmartPlaylistRuleBuilderViewModel.swift
//  Audientia - Playlist Rule Builder ViewModel
//
//  ViewModel for building smart playlist rules
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Combine
import DataLayer
import Foundation
import os.log
import Shared
import SwiftUI

/// ViewModel for smart playlist rule building
/// Manages rule creation, editing, and validation
@MainActor
public final class SmartPlaylistRuleBuilderViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current rules being built
    @Published public private(set) var rules: [SmartPlaylistRule] = []
    
    /// Whether rules are valid
    @Published public private(set) var isValid: Bool = false
    
    // MARK: - Initialization
    
    /// Initialize the rule builder
    public init() {
        Logger.userInterface.info("SmartPlaylistRuleBuilderViewModel initialized")
    }
    
    // MARK: - Public Methods
    
    /// Add a rule to the builder
    /// - Parameters:
    ///   - field: Field to match against
    ///   - operator: Comparison operator
    ///   - value: Value to compare against
    ///   - logicalOperator: Logical operator for combining with previous rule (optional)
    public func addRule(
        field: SmartPlaylistRule.Field,
        operator: SmartPlaylistRule.Operator,
        value: String,
        logicalOperator: SmartPlaylistRule.LogicalOperator? = nil
    ) {
        let rule = SmartPlaylistRule(
            field: field,
            operator: `operator`,
            value: value,
            logicalOperator: logicalOperator
        )
        rules.append(rule)
        updateValidation()
        Logger.userInterface.debug("Added rule: \(field.rawValue) \(`operator`.rawValue) \(value)")
    }
    
    /// Remove a rule at the specified index
    /// - Parameter index: Index of the rule to remove
    public func removeRule(at index: Int) {
        guard index >= 0 && index < rules.count else {
            Logger.userInterface.warning("Attempted to remove rule at invalid index: \(index)")
            return
        }
        rules.remove(at: index)
        updateValidation()
        Logger.userInterface.debug("Removed rule at index: \(index)")
    }
    
    /// Update a rule at the specified index
    /// - Parameters:
    ///   - index: Index of the rule to update
    ///   - field: New field value
    ///   - operator: New operator value
    ///   - value: New value
    ///   - logicalOperator: New logical operator
    public func updateRule(
        at index: Int,
        field: SmartPlaylistRule.Field,
        operator: SmartPlaylistRule.Operator,
        value: String,
        logicalOperator: SmartPlaylistRule.LogicalOperator? = nil
    ) {
        guard index >= 0 && index < rules.count else {
            Logger.userInterface.warning("Attempted to update rule at invalid index: \(index)")
            return
        }
        
        let updatedRule = SmartPlaylistRule(
            field: field,
            operator: `operator`,
            value: value,
            logicalOperator: logicalOperator
        )
        rules[index] = updatedRule
        updateValidation()
        Logger.userInterface.debug("Updated rule at index: \(index)")
    }
    
    /// Build SmartPlaylistRules from current rules
    /// - Returns: SmartPlaylistRules object
    public func buildRules() -> SmartPlaylistRules {
        SmartPlaylistRules(rules: rules)
    }
    
    /// Clear all rules
    public func clearRules() {
        rules.removeAll()
        updateValidation()
        Logger.userInterface.debug("Cleared all rules")
    }
    
    // MARK: - Private Methods
    
    private func updateValidation() {
        isValid = !rules.isEmpty
    }
}
