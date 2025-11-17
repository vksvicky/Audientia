//
//  SmartPlaylistRuleBuilderViewModelTests.swift
//  Audientia - UI Tests
//
//  TDD tests for SmartPlaylistRuleBuilderViewModel following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import XCTest

@testable import DataLayer
@testable import Shared

/// TDD tests for SmartPlaylistRuleBuilderViewModel
/// Following Right-BICEP principles:
/// - [Right]: Verify rule building produces correct results
/// - [B]oundary: Empty rules, complex nested rules, edge cases
/// - [I]nverse: Add rule → Remove → Verify not in rules
/// - [C]ross-check: Compare with manual rule creation
/// - [E]rror: Invalid rules, missing fields
/// - [P]erformance: Rule building completes quickly
@MainActor
final class SmartPlaylistRuleBuilderViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: SmartPlaylistRuleBuilderViewModel!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        viewModel = SmartPlaylistRuleBuilderViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - [Right] Tests - Verify Expected Behavior
    
    /// Test: ViewModel should add a rule
    func testAddsRule() {
        // Given - A rule configuration
        let field = SmartPlaylistRule.Field.artist
        let ruleOperator = SmartPlaylistRule.Operator.contains
        let value = "Beatles"
        
        // When - Adding a rule
        viewModel.addRule(field: field, operator: ruleOperator, value: value)
        
        // Then - Rule should be added
        XCTAssertEqual(viewModel.rules.count, 1)
        XCTAssertEqual(viewModel.rules.first?.field, field)
        XCTAssertEqual(viewModel.rules.first?.operator, ruleOperator)
        XCTAssertEqual(viewModel.rules.first?.value, value)
    }
    
    /// Test: ViewModel should remove a rule
    func testRemovesRule() {
        // Given - A rule exists
        viewModel.addRule(field: .artist, operator: .contains, value: "Beatles")
        XCTAssertEqual(viewModel.rules.count, 1)
        
        // When - Removing the rule
        if viewModel.rules.first != nil {
            viewModel.removeRule(at: 0)
        }
        
        // Then - Rule should be removed
        XCTAssertTrue(viewModel.rules.isEmpty)
    }
    
    /// Test: ViewModel should build SmartPlaylistRules
    func testBuildsSmartPlaylistRules() {
        // Given - Multiple rules
        viewModel.addRule(field: .artist, operator: .contains, value: "Beatles")
        viewModel.addRule(field: .year, operator: .greaterThan, value: "1960", logicalOperator: .and)
        
        // When - Building rules
        let smartRules = viewModel.buildRules()
        
        // Then - Should create valid SmartPlaylistRules
        XCTAssertNotNil(smartRules)
        XCTAssertTrue(smartRules.isValid)
        XCTAssertEqual(smartRules.rules.count, 2)
    }
    
    /// Test: ViewModel should validate rules
    func testValidatesRules() {
        // Given - No rules
        XCTAssertFalse(viewModel.isValid)
        
        // When - Adding a rule
        viewModel.addRule(field: .artist, operator: .contains, value: "Beatles")
        
        // Then - Rules should be valid
        XCTAssertTrue(viewModel.isValid)
    }
    
    // MARK: - [B]oundary Condition Tests
    
    /// Test: ViewModel should handle empty rules
    func testHandlesEmptyRules() {
        // Given - No rules
        // When - Building rules
        let smartRules = viewModel.buildRules()
        
        // Then - Should return invalid rules
        XCTAssertFalse(smartRules.isValid)
    }
    
    /// Test: ViewModel should handle many rules
    func testHandlesManyRules() {
        // Given - Many rules
        for i in 0..<50 {
            let logicalOp: SmartPlaylistRule.LogicalOperator? = i > 0 ? .and : nil
            viewModel.addRule(
                field: .title,
                operator: .contains,
                value: "Song \(i)",
                logicalOperator: logicalOp
            )
        }
        
        // When - Building rules
        let smartRules = viewModel.buildRules()
        
        // Then - Should create rules with all rules
        XCTAssertEqual(smartRules.rules.count, 50)
    }
    
    // MARK: - [I]nverse Relationship Tests
    
    /// Test: Add rule then remove should result in empty rules
    func testAddThenRemoveRule() {
        // Given - No rules
        XCTAssertTrue(viewModel.rules.isEmpty)
        
        // When - Adding then removing rule
        viewModel.addRule(field: .artist, operator: .contains, value: "Beatles")
        viewModel.removeRule(at: 0)
        
        // Then - Rules should be empty
        XCTAssertTrue(viewModel.rules.isEmpty)
    }
    
    // MARK: - [C]ross-Check Tests
    
    /// Test: Built rules should match manual creation
    func testBuiltRulesMatchManualCreation() {
        // Given - Rules added to ViewModel
        viewModel.addRule(field: .artist, operator: .contains, value: "Beatles")
        viewModel.addRule(field: .year, operator: .greaterThan, value: "1960", logicalOperator: .and)
        
        // When - Building rules
        let builtRules = viewModel.buildRules()
        
        // Then - Should match manually created rules
        let manualRule1 = SmartPlaylistRule(field: .artist, operator: .contains, value: "Beatles")
        let manualRule2 = SmartPlaylistRule(
            field: .year,
            operator: .greaterThan,
            value: "1960",
            logicalOperator: .and
        )
        let manualRules = SmartPlaylistRules(rules: [manualRule1, manualRule2])
        
        XCTAssertEqual(builtRules.rules.count, manualRules.rules.count)
        XCTAssertEqual(builtRules.rules.first?.field, manualRules.rules.first?.field)
    }
    
    // MARK: - [E]rror Condition Tests
    
    /// Test: ViewModel should handle invalid rule values
    func testHandlesInvalidRuleValues() {
        // Given - Empty value
        viewModel.addRule(field: .artist, operator: .contains, value: "")
        
        // When - Building rules
        let smartRules = viewModel.buildRules()
        
        // Then - Rules should still be built (validation happens at rule engine level)
        XCTAssertTrue(smartRules.isValid)
    }
    
    // MARK: - [P]erformance Tests
    
    /// Test: Building rules should complete quickly
    func testBuildRulesPerformance() {
        // Given - Many rules
        for i in 0..<100 {
            let logicalOp: SmartPlaylistRule.LogicalOperator? = i > 0 ? .and : nil
            viewModel.addRule(
                field: .title,
                operator: .contains,
                value: "Song \(i)",
                logicalOperator: logicalOp
            )
        }
        
        // When - Building rules
        let startTime = Date()
        _ = viewModel.buildRules()
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete within 10ms
        XCTAssertLessThan(duration, 0.01, "Building rules should complete within 10ms")
    }
    
    // MARK: - Edge Case Tests
    
    /// Test: ViewModel should handle all field types
    func testHandlesAllFieldTypes() {
        // Given - Rules with different field types
        let fields: [SmartPlaylistRule.Field] = [.title, .artist, .album, .genre, .year, .rating, .duration]
        
        // When - Adding rules for each field
        for field in fields {
            viewModel.addRule(field: field, operator: .equals, value: "Test")
        }
        
        // Then - All rules should be added
        XCTAssertEqual(viewModel.rules.count, fields.count)
    }
    
    /// Test: ViewModel should handle all operators
    func testHandlesAllOperators() {
        // Given - Rules with different operators
        let operators: [SmartPlaylistRule.Operator] = [
            .equals, .contains, .startsWith, .endsWith,
            .greaterThan, .lessThan, .greaterThanOrEqual, .lessThanOrEqual, .notEquals
        ]
        
        // When - Adding rules for each operator
        for op in operators {
            viewModel.addRule(field: .title, operator: op, value: "Test")
        }
        
        // Then - All rules should be added
        XCTAssertEqual(viewModel.rules.count, operators.count)
    }
    
    /// Test: ViewModel should handle logical operators
    func testHandlesLogicalOperators() {
        // Given - Rules with logical operators
        viewModel.addRule(field: .artist, operator: .contains, value: "Beatles")
        viewModel.addRule(field: .year, operator: .greaterThan, value: "1960", logicalOperator: .and)
        viewModel.addRule(field: .rating, operator: .equals, value: "5", logicalOperator: .or)
        
        // When - Building rules
        let smartRules = viewModel.buildRules()
        
        // Then - Logical operators should be preserved
        XCTAssertEqual(smartRules.rules.count, 3)
        XCTAssertNil(smartRules.rules[0].logicalOperator)
        XCTAssertEqual(smartRules.rules[1].logicalOperator, .and)
        XCTAssertEqual(smartRules.rules[2].logicalOperator, .or)
    }
}
