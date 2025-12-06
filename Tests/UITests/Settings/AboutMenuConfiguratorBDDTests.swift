//
//  AboutMenuConfiguratorBDDTests.swift
//  AudientiaUITests
//
//  BDD tests for AboutMenuConfigurator following user-centric scenarios
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import XCTest

@testable import Audientia

/// BDD tests for AboutMenuConfigurator
/// Following user-centric "As a user, I want to..." format
final class AboutMenuConfiguratorBDDTests: XCTestCase {
    
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
    
    /// BDD: As a user, when I click the About menu item, it should show my custom About window
    func testUserClicksAboutMenuItemShowsCustomWindow() {
        // Given: I have a menu with an About item
        let mainMenu = createValidMenu()
        guard let aboutItem = findAboutItem(in: mainMenu) else {
            XCTFail("About item should exist")
            return
        }
        
        // When: The app configures the About menu item
        let result = configurator.configure(
            mainMenu: mainMenu,
            target: target,
            action: selector
        )
        
        // Then: The About menu item should be wired to show my custom window
        XCTAssertTrue(result, "About menu item should be configured")
        XCTAssertTrue(aboutItem.target === target, "About item should target custom handler")
        XCTAssertEqual(aboutItem.action, selector, "About item should use custom action")
    }
    
    /// BDD: As a developer, when I configure the About menu, it should work even if the menu structure is standard
    func testDeveloperConfiguresAboutMenuWithStandardStructure() {
        // Given: I have a standard macOS menu structure
        let mainMenu = createStandardMacOSMenu()
        
        // When: I configure the About menu item
        let result = configurator.configure(
            mainMenu: mainMenu,
            target: target,
            action: selector
        )
        
        // Then: The configuration should succeed
        XCTAssertTrue(result, "Configuration should work with standard menu structure")
        
        guard let aboutItem = findAboutItem(in: mainMenu) else {
            XCTFail("About item should exist")
            return
        }
        XCTAssertTrue(aboutItem.target === target, "About item should be wired")
    }
    
    /// BDD: As a developer, when the menu structure is invalid, configuration should fail gracefully
    func testDeveloperHandlesInvalidMenuStructureGracefully() {
        // Given: I have an invalid menu structure (no About item)
        let menu = NSMenu(title: "Main")
        let appItem = NSMenuItem(title: "Audientia", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "App")
        submenu.addItem(NSMenuItem(title: "Preferences...", action: nil, keyEquivalent: ","))
        appItem.submenu = submenu
        menu.addItem(appItem)
        
        // When: I try to configure the About menu item
        let result = configurator.configure(
            mainMenu: menu,
            target: target,
            action: selector
        )
        
        // Then: Configuration should fail gracefully (return false)
        XCTAssertFalse(result, "Configuration should fail gracefully for invalid structure")
    }
    
    /// BDD: As a user, when I have multiple app windows, the About menu should work from any window
    func testUserAccessesAboutMenuFromAnyWindow() {
        // Given: I have a menu configured for About
        let mainMenu = createValidMenu()
        
        // When: I configure the About menu (simulating app launch)
        let result = configurator.configure(
            mainMenu: mainMenu,
            target: target,
            action: selector
        )
        
        // Then: The About menu should be accessible
        XCTAssertTrue(result, "About menu should be accessible")
        
        guard let aboutItem = findAboutItem(in: mainMenu) else {
            XCTFail("About item should exist")
            return
        }
        XCTAssertNotNil(aboutItem.target, "About item should have a target")
        XCTAssertNotNil(aboutItem.action, "About item should have an action")
    }
    
    /// BDD: As a developer, when I reconfigure the About menu, it should update correctly
    func testDeveloperReconfiguresAboutMenuUpdatesCorrectly() {
        // Given: I have a menu that's already configured
        let mainMenu = createValidMenu()
        guard let aboutItem = findAboutItem(in: mainMenu) else {
            XCTFail("About item should exist")
            return
        }
        
        let firstTarget = TestTarget()
        let firstSelector = #selector(TestTarget.showAbout)
        _ = configurator.configure(
            mainMenu: mainMenu,
            target: firstTarget,
            action: firstSelector
        )
        
        // When: I reconfigure with a new target
        let newTarget = TestTarget()
        let newSelector = #selector(TestTarget.showAbout)
        let result = configurator.configure(
            mainMenu: mainMenu,
            target: newTarget,
            action: newSelector
        )
        
        // Then: The menu should be updated to the new target
        XCTAssertTrue(result, "Reconfiguration should succeed")
        XCTAssertTrue(aboutItem.target === newTarget, "Target should be updated")
        XCTAssertEqual(aboutItem.action, newSelector, "Action should be updated")
    }
    
    /// BDD: As a user, when the app menu doesn't exist, the About menu should not crash
    func testUserHandlesMissingAppMenuGracefully() {
        // Given: I have a menu without an app menu item
        let menu = NSMenu(title: "Main")
        menu.addItem(NSMenuItem(title: "File", action: nil, keyEquivalent: ""))
        
        // When: The app tries to configure the About menu
        let result = configurator.configure(
            mainMenu: menu,
            target: target,
            action: selector
        )
        
        // Then: Configuration should fail gracefully without crashing
        XCTAssertFalse(result, "Should fail gracefully when app menu missing")
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
    
    private func createStandardMacOSMenu() -> NSMenu {
        let mainMenu = NSMenu(title: "Main")
        let appMenuItem = NSMenuItem(title: "Audientia", action: nil, keyEquivalent: "")
        let appSubmenu = NSMenu(title: "App")
        
        // Standard macOS app menu items
        appSubmenu.addItem(NSMenuItem(title: "About Audientia", action: nil, keyEquivalent: ""))
        appSubmenu.addItem(NSMenuItem.separator())
        appSubmenu.addItem(NSMenuItem(title: "Preferences...", action: nil, keyEquivalent: ","))
        appSubmenu.addItem(NSMenuItem.separator())
        appSubmenu.addItem(NSMenuItem(title: "Services", action: nil, keyEquivalent: ""))
        appSubmenu.addItem(NSMenuItem.separator())
        appSubmenu.addItem(NSMenuItem(title: "Hide Audientia", action: nil, keyEquivalent: "h"))
        appSubmenu.addItem(NSMenuItem(title: "Hide Others", action: nil, keyEquivalent: "h"))
        appSubmenu.addItem(NSMenuItem(title: "Show All", action: nil, keyEquivalent: ""))
        appSubmenu.addItem(NSMenuItem.separator())
        appSubmenu.addItem(NSMenuItem(title: "Quit Audientia", action: nil, keyEquivalent: "q"))
        
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
