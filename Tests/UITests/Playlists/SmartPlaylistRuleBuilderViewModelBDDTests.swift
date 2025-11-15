//
//  SmartPlaylistRuleBuilderViewModelBDDTests.swift
//  Audientia - UI Tests
//
//  BDD tests for SmartPlaylistRuleBuilderViewModel
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import XCTest

@testable import DataLayer
@testable import Shared

/// BDD tests for SmartPlaylistRuleBuilderViewModel
/// Scenarios: "As a user, I want to create a playlist of 5-star songs from 2020"
@MainActor
final class SmartPlaylistRuleBuilderViewModelBDDTests: XCTestCase {
    
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
    
    // MARK: - BDD Scenarios
    
    /// Scenario: As a user, I want to create a playlist of 5-star songs from 2020
    func testUserCreatesPlaylistOfFiveStarSongsFrom2020() {
        // Given - User wants to create a smart playlist
        // When - User adds rules: rating equals 5 AND year equals 2020
        viewModel.addRule(field: .rating, operator: .equals, value: "5")
        viewModel.addRule(field: .year, operator: .equals, value: "2020", logicalOperator: .and)
        
        // Then - Rules should be created and valid
        XCTAssertTrue(viewModel.isValid)
        XCTAssertEqual(viewModel.rules.count, 2)
        XCTAssertEqual(viewModel.rules[0].field, .rating)
        XCTAssertEqual(viewModel.rules[0].operator, .equals)
        XCTAssertEqual(viewModel.rules[0].value, "5")
        XCTAssertEqual(viewModel.rules[1].field, .year)
        XCTAssertEqual(viewModel.rules[1].operator, .equals)
        XCTAssertEqual(viewModel.rules[1].value, "2020")
        XCTAssertEqual(viewModel.rules[1].logicalOperator, .and)
        
        // And - Should be able to build SmartPlaylistRules
        let smartRules = viewModel.buildRules()
        XCTAssertTrue(smartRules.isValid)
        XCTAssertEqual(smartRules.rules.count, 2)
    }
    
    /// Scenario: As a user, I want to create a playlist of songs by a specific artist
    func testUserCreatesPlaylistOfSongsByArtist() {
        // Given - User wants songs by "The Beatles"
        // When - User adds rule: artist contains "Beatles"
        viewModel.addRule(field: .artist, operator: .contains, value: "Beatles")
        
        // Then - Rule should be created
        XCTAssertTrue(viewModel.isValid)
        XCTAssertEqual(viewModel.rules.count, 1)
        XCTAssertEqual(viewModel.rules.first?.field, .artist)
        XCTAssertEqual(viewModel.rules.first?.operator, .contains)
        XCTAssertEqual(viewModel.rules.first?.value, "Beatles")
    }
    
    /// Scenario: As a user, I want to create a playlist with multiple conditions
    func testUserCreatesPlaylistWithMultipleConditions() {
        // Given - User wants songs from 2020 with rating >= 4
        // When - User adds multiple rules
        viewModel.addRule(field: .year, operator: .equals, value: "2020")
        viewModel.addRule(field: .rating, operator: .greaterThanOrEqual, value: "4", logicalOperator: .and)
        
        // Then - All rules should be created
        XCTAssertTrue(viewModel.isValid)
        XCTAssertEqual(viewModel.rules.count, 2)
        XCTAssertEqual(viewModel.rules[0].field, .year)
        XCTAssertEqual(viewModel.rules[1].field, .rating)
        XCTAssertEqual(viewModel.rules[1].logicalOperator, .and)
    }
    
    /// Scenario: As a user, I want to remove a rule I added by mistake
    func testUserRemovesRule() {
        // Given - User has added multiple rules
        viewModel.addRule(field: .artist, operator: .contains, value: "Beatles")
        viewModel.addRule(field: .year, operator: .equals, value: "2020", logicalOperator: .and)
        XCTAssertEqual(viewModel.rules.count, 2)
        
        // When - User removes the first rule
        viewModel.removeRule(at: 0)
        
        // Then - Only the second rule should remain
        XCTAssertEqual(viewModel.rules.count, 1)
        XCTAssertEqual(viewModel.rules.first?.field, .year)
    }
    
    /// Scenario: As a user, I want to update a rule I created
    func testUserUpdatesRule() {
        // Given - User has added a rule
        viewModel.addRule(field: .artist, operator: .contains, value: "Beatles")
        XCTAssertEqual(viewModel.rules.first?.value, "Beatles")
        
        // When - User updates the rule value
        viewModel.updateRule(at: 0, field: .artist, operator: .contains, value: "The Beatles")
        
        // Then - Rule should be updated
        XCTAssertEqual(viewModel.rules.first?.value, "The Beatles")
    }
    
    /// Scenario: As a user, I want to see that my rules are valid before creating the playlist
    func testUserSeesRulesAreValid() {
        // Given - User has no rules
        XCTAssertFalse(viewModel.isValid)
        
        // When - User adds a rule
        viewModel.addRule(field: .artist, operator: .contains, value: "Beatles")
        
        // Then - Rules should be marked as valid
        XCTAssertTrue(viewModel.isValid)
    }
    
    /// Scenario: As a user, I want to clear all rules and start over
    func testUserClearsAllRules() {
        // Given - User has added multiple rules
        viewModel.addRule(field: .artist, operator: .contains, value: "Beatles")
        viewModel.addRule(field: .year, operator: .equals, value: "2020", logicalOperator: .and)
        XCTAssertEqual(viewModel.rules.count, 2)
        XCTAssertTrue(viewModel.isValid)
        
        // When - User clears all rules
        viewModel.clearRules()
        
        // Then - All rules should be removed
        XCTAssertTrue(viewModel.rules.isEmpty)
        XCTAssertFalse(viewModel.isValid)
    }
    
    /// Scenario: As a user, I want to create a playlist with OR conditions
    func testUserCreatesPlaylistWithORConditions() {
        // Given - User wants songs by "Beatles" OR "Rolling Stones"
        // When - User adds rules with OR operator
        viewModel.addRule(field: .artist, operator: .equals, value: "Beatles")
        viewModel.addRule(field: .artist, operator: .equals, value: "Rolling Stones", logicalOperator: .or)
        
        // Then - Rules should be created with OR operator
        XCTAssertTrue(viewModel.isValid)
        XCTAssertEqual(viewModel.rules.count, 2)
        XCTAssertEqual(viewModel.rules[1].logicalOperator, .or)
    }
}
