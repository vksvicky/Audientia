//
//  AboutMenuConfiguratorTests.swift
//  AudientiaUITests
//
//  Comprehensive TDD tests for AboutMenuConfigurator following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import XCTest

@testable import Audientia

/// TDD tests for AboutMenuConfigurator
/// Following Right-BICEP principles:
/// - [Right]: Verify menu item is correctly wired
/// - [B]oundary: Empty menu, missing items, nil menu
/// - [I]nverse: Wire → Verify → Unwire → Verify original
/// - [C]ross-check: Compare with manual menu inspection
/// - [E]rror: Missing menu items, invalid structure
/// - [P]erformance: Configuration completes quickly
final class AboutMenuConfiguratorTests: XCTestCase {
    
    var configurator: AboutMenuConfigurator!
    var target: TestTarget!
    var selector: Selector!
    
    override func setUp() {
        super.setUp()
        configurator = AboutMenuConfigurator()
        target = TestTarget()
        selector = #selector(TestTarget.showAbout)
    }
    
    override func tearDown() {
        configurator = nil
        target = nil
        selector = nil
        super.tearDown()
    }
    
    // MARK: - [Right]: Are the Results Right?
    
    /// Test: Configurator correctly wires About menu item to target/action
    func testConfiguratorWiresMenuItemCorrectly() {
        // Given: A main menu with About item
        let mainMenu = createValidMenu()
        guard let aboutItem = findAboutItem(in: mainMenu) else {
            XCTFail("About item should exist")
            return
        }
        
        // When: Configuring the menu
        let result = configurator.configure(
            mainMenu: mainMenu,
            target: target,
            action: selector
        )
        
        // Then: Configuration should succeed
        XCTAssertTrue(result, "Configuration should succeed for valid menu")
        XCTAssertTrue(aboutItem.target === target, "Target should be set correctly")
        XCTAssertEqual(aboutItem.action, selector, "Action should be set correctly")
    }
    
    /// Test: Configurator returns true when menu item is found and wired
    func testConfiguratorReturnsTrueOnSuccess() {
        // Given: A valid menu structure
        let mainMenu = createValidMenu()
        
        // When: Configuring
        let result = configurator.configure(
            mainMenu: mainMenu,
            target: target,
            action: selector
        )
        
        // Then: Should return true
        XCTAssertTrue(result, "Should return true when configuration succeeds")
    }
    
    // MARK: - [B]oundary Conditions
    
    /// Test: Configurator handles nil main menu gracefully
    func testConfiguratorHandlesNilMenu() {
        // Given: nil main menu
        // When: Configuring
        let result = configurator.configure(
            mainMenu: nil,
            target: target,
            action: selector
        )
        
        // Then: Should return false
        XCTAssertFalse(result, "Should return false for nil menu")
    }
    
    /// Test: Configurator handles empty menu gracefully
    func testConfiguratorHandlesEmptyMenu() {
        // Given: Empty menu
        let emptyMenu = NSMenu(title: "Empty")
        
        // When: Configuring
        let result = configurator.configure(
            mainMenu: emptyMenu,
            target: target,
            action: selector
        )
        
        // Then: Should return false
        XCTAssertFalse(result, "Should return false for empty menu")
    }
    
    /// Test: Configurator handles menu without app menu item
    func testConfiguratorHandlesMenuWithoutAppItem() {
        // Given: Menu without app menu item at index 0
        let menu = NSMenu(title: "Main")
        menu.addItem(NSMenuItem(title: "File", action: nil, keyEquivalent: ""))
        
        // When: Configuring
        let result = configurator.configure(
            mainMenu: menu,
            target: target,
            action: selector
        )
        
        // Then: Should return false
        XCTAssertFalse(result, "Should return false when app menu item not found")
    }
    
    /// Test: Configurator handles app menu without submenu
    func testConfiguratorHandlesAppMenuWithoutSubmenu() {
        // Given: App menu item without submenu
        let menu = NSMenu(title: "Main")
        let appItem = NSMenuItem(title: "Audientia", action: nil, keyEquivalent: "")
        menu.addItem(appItem)
        
        // When: Configuring
        let result = configurator.configure(
            mainMenu: menu,
            target: target,
            action: selector
        )
        
        // Then: Should return false
        XCTAssertFalse(result, "Should return false when app submenu not found")
    }
    
    /// Test: Configurator handles submenu without About item
    func testConfiguratorHandlesSubmenuWithoutAboutItem() {
        // Given: App submenu without About item
        let menu = NSMenu(title: "Main")
        let appItem = NSMenuItem(title: "Audientia", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "App")
        submenu.addItem(NSMenuItem(title: "Preferences...", action: nil, keyEquivalent: ","))
        appItem.submenu = submenu
        menu.addItem(appItem)
        
        // When: Configuring
        let result = configurator.configure(
            mainMenu: menu,
            target: target,
            action: selector
        )
        
        // Then: Should return false
        XCTAssertFalse(result, "Should return false when About item not found")
    }
    
    /// Test: Configurator handles About item with different title casing
    func testConfiguratorHandlesCaseSensitiveTitle() {
        // Given: About item with different casing
        let menu = NSMenu(title: "Main")
        let appItem = NSMenuItem(title: "Audientia", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "App")
        submenu.addItem(NSMenuItem(title: "about audientia", action: nil, keyEquivalent: ""))
        appItem.submenu = submenu
        menu.addItem(appItem)
        
        // When: Configuring
        let result = configurator.configure(
            mainMenu: menu,
            target: target,
            action: selector
        )
        
        // Then: Should return false (exact match required)
        XCTAssertFalse(result, "Should return false for case mismatch")
    }
    
    // MARK: - [I]nverse Relationships
    
    /// Test: Configurator can wire and verify inverse relationship
    func testConfiguratorWiringIsReversible() {
        // Given: A menu with About item
        let mainMenu = createValidMenu()
        guard let aboutItem = findAboutItem(in: mainMenu) else {
            XCTFail("About item should exist")
            return
        }
        let originalTarget = aboutItem.target
        let originalAction = aboutItem.action
        
        // When: Wiring the menu
        let result1 = configurator.configure(
            mainMenu: mainMenu,
            target: target,
            action: selector
        )
        
        // Then: Should be wired
        XCTAssertTrue(result1, "First configuration should succeed")
        XCTAssertTrue(aboutItem.target === target, "Target should be set")
        XCTAssertEqual(aboutItem.action, selector, "Action should be set")
        
        // When: Wiring to different target
        let newTarget = TestTarget()
        let newSelector = #selector(TestTarget.showAbout)
        let result2 = configurator.configure(
            mainMenu: mainMenu,
            target: newTarget,
            action: newSelector
        )
        
        // Then: Should update to new target
        XCTAssertTrue(result2, "Second configuration should succeed")
        XCTAssertTrue(aboutItem.target === newTarget, "Target should be updated")
        XCTAssertEqual(aboutItem.action, newSelector, "Action should be updated")
        
        // Verify original was different
        XCTAssertNotNil(originalTarget, "Original target should exist")
        XCTAssertNotEqual(aboutItem.target, originalTarget, "Target should have changed")
    }
    
    // MARK: - [C]ross-Check Using Other Means
    
    /// Test: Verify menu structure matches expected macOS menu layout
    func testMenuStructureMatchesExpectedLayout() {
        // Given: A valid menu structure
        let mainMenu = createValidMenu()
        
        // When: Inspecting the menu structure
        let appMenuItem = mainMenu.item(at: 0)
        let appSubmenu = appMenuItem?.submenu
        let aboutItem = appSubmenu?.item(withTitle: "About Audientia")
        
        // Then: Structure should match expected layout
        XCTAssertNotNil(appMenuItem, "App menu item should exist at index 0")
        XCTAssertNotNil(appSubmenu, "App submenu should exist")
        XCTAssertNotNil(aboutItem, "About item should exist in submenu")
        XCTAssertEqual(aboutItem?.title, "About Audientia", "About item should have correct title")
    }
    
    /// Test: Verify configuration matches manual menu inspection
    func testConfigurationMatchesManualInspection() {
        // Given: A configured menu
        let mainMenu = createValidMenu()
        guard let aboutItem = findAboutItem(in: mainMenu) else {
            XCTFail("About item should exist")
            return
        }
        
        // When: Configuring and then manually inspecting
        let result = configurator.configure(
            mainMenu: mainMenu,
            target: target,
            action: selector
        )
        
        // Then: Manual inspection should match configuration
        XCTAssertTrue(result, "Configuration should succeed")
        XCTAssertTrue(aboutItem.target === target, "Manual inspection should match configured target")
        XCTAssertEqual(aboutItem.action, selector, "Manual inspection should match configured action")
    }
    
    // MARK: - [E]rror Conditions
    
    /// Test: Configurator handles menu with invalid structure
    func testConfiguratorHandlesInvalidMenuStructure() {
        // Given: Menu with app item at wrong index
        let menu = NSMenu(title: "Main")
        menu.addItem(NSMenuItem(title: "File", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Audientia", action: nil, keyEquivalent: ""))
        
        // When: Configuring
        let result = configurator.configure(
            mainMenu: menu,
            target: target,
            action: selector
        )
        
        // Then: Should return false
        XCTAssertFalse(result, "Should return false for invalid menu structure")
    }
    
    /// Test: Configurator handles About item that is disabled
    func testConfiguratorHandlesDisabledAboutItem() {
        // Given: About item that is disabled
        let mainMenu = createValidMenu()
        guard let aboutItem = findAboutItem(in: mainMenu) else {
            XCTFail("About item should exist")
            return
        }
        aboutItem.isEnabled = false
        
        // When: Configuring
        let result = configurator.configure(
            mainMenu: mainMenu,
            target: target,
            action: selector
        )
        
        // Then: Should still succeed (disabled items can still have targets)
        XCTAssertTrue(result, "Should succeed even if item is disabled")
        XCTAssertTrue(aboutItem.target === target, "Target should be set even if disabled")
    }
    
    /// Test: Configurator handles About item with existing target/action
    func testConfiguratorOverwritesExistingTarget() {
        // Given: About item with existing target/action
        let mainMenu = createValidMenu()
        guard let aboutItem = findAboutItem(in: mainMenu) else {
            XCTFail("About item should exist")
            return
        }
        let existingTarget = TestTarget()
        let existingSelector = #selector(TestTarget.showAbout)
        aboutItem.target = existingTarget
        aboutItem.action = existingSelector
        
        // When: Configuring with new target
        let result = configurator.configure(
            mainMenu: mainMenu,
            target: target,
            action: selector
        )
        
        // Then: Should overwrite existing target
        XCTAssertTrue(result, "Configuration should succeed")
        XCTAssertTrue(aboutItem.target === target, "Target should be overwritten")
        XCTAssertNotEqual(aboutItem.target, existingTarget, "Original target should be replaced")
    }
    
    // MARK: - [P]erformance Characteristics
    
    /// Test: Configuration completes quickly
    func testConfigurationPerformance() {
        // Given: A valid menu
        let mainMenu = createValidMenu()
        
        // When: Measuring configuration time
        measure {
            _ = configurator.configure(
                mainMenu: mainMenu,
                target: target,
                action: selector
            )
        }
        
        // Then: Should complete quickly (XCTest measure validates this)
    }
    
    /// Test: Multiple configurations complete quickly
    func testMultipleConfigurationsPerformance() {
        // Given: A valid menu
        let mainMenu = createValidMenu()
        
        // When: Performing multiple configurations
        measure {
            for _ in 0..<100 {
                _ = configurator.configure(
                    mainMenu: mainMenu,
                    target: target,
                    action: selector
                )
            }
        }
        
        // Then: Should complete quickly
    }
    
    // MARK: - Edge Cases
    
    /// Test: Configurator handles menu with multiple About items (first one wins)
    func testConfiguratorHandlesMultipleAboutItems() {
        // Given: Menu with multiple About items
        let menu = NSMenu(title: "Main")
        let appItem = NSMenuItem(title: "Audientia", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "App")
        let aboutItem1 = NSMenuItem(title: "About Audientia", action: nil, keyEquivalent: "")
        let aboutItem2 = NSMenuItem(title: "About Audientia", action: nil, keyEquivalent: "")
        submenu.addItem(aboutItem1)
        submenu.addItem(aboutItem2)
        appItem.submenu = submenu
        menu.addItem(appItem)
        
        // When: Configuring
        let result = configurator.configure(
            mainMenu: menu,
            target: target,
            action: selector
        )
        
        // Then: Should wire first item found
        XCTAssertTrue(result, "Should succeed")
        XCTAssertTrue(aboutItem1.target === target, "First item should be wired")
        // Note: item(withTitle:) returns first match, so aboutItem2 may not be wired
    }
    
    /// Test: Configurator handles menu with special characters in titles
    func testConfiguratorHandlesSpecialCharacters() {
        // Given: Menu with special characters
        let menu = NSMenu(title: "Main")
        let appItem = NSMenuItem(title: "Audientia™", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "App")
        submenu.addItem(NSMenuItem(title: "About Audientia", action: nil, keyEquivalent: ""))
        appItem.submenu = submenu
        menu.addItem(appItem)
        
        // When: Configuring
        let result = configurator.configure(
            mainMenu: menu,
            target: target,
            action: selector
        )
        
        // Then: Should still work (special characters in app name don't affect About item search)
        XCTAssertTrue(result, "Should succeed with special characters in app name")
    }
    
    // MARK: - Helper Methods
    
    private func createValidMenu() -> NSMenu {
        let mainMenu = NSMenu(title: "Main")
        let appMenuItem = NSMenuItem(title: "Audientia", action: nil, keyEquivalent: "")
        let appSubmenu = NSMenu(title: "App")
        let aboutItem = NSMenuItem(title: "About Audientia", action: nil, keyEquivalent: "")
        appSubmenu.addItem(aboutItem)
        appMenuItem.submenu = appSubmenu
        mainMenu.addItem(appMenuItem)
        return mainMenu
    }
    
    private func findAboutItem(in menu: NSMenu) -> NSMenuItem? {
        guard
            let appMenuItem = menu.item(at: 0),
            let appSubmenu = appMenuItem.submenu
        else {
            return nil
        }
        return appSubmenu.item(withTitle: "About Audientia")
    }
}

// MARK: - Test Target

private final class TestTarget: NSObject {
    @objc func showAbout() {
        // Test target for menu wiring
    }
}
