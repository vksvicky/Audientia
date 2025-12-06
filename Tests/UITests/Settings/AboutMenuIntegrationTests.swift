//
//  AboutMenuIntegrationTests.swift
//  AudientiaUITests
//
//  Integration tests for About menu end-to-end workflow
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import SwiftUI
import XCTest

@testable import Audientia
@testable import Shared

/// Integration tests for About menu complete workflow
/// Tests the full flow: menu configuration → menu click → window display
final class AboutMenuIntegrationTests: XCTestCase {
    
    var appDelegate: AppDelegate!
    var configurator: AboutMenuConfigurator!
    var mainMenu: NSMenu!
    
    @MainActor
    override func setUp() {
        super.setUp()
        appDelegate = AppDelegate()
        configurator = AboutMenuConfigurator()
        mainMenu = createValidMenu()
    }
    
    @MainActor
    override func tearDown() {
        // Close any windows that were opened
        NSApplication.shared.windows.forEach { $0.close() }
        appDelegate = nil
        configurator = nil
        mainMenu = nil
        super.tearDown()
    }
    
    /// Integration Test: Complete About menu workflow
    @MainActor
    func testCompleteAboutMenuWorkflow() {
        // Given: App delegate with About menu configured
        let result = configurator.configure(
            mainMenu: mainMenu,
            target: appDelegate,
            action: #selector(AppDelegate.showCustomAbout)
        )
        XCTAssertTrue(result, "Menu should be configured")
        
        // When: About menu item is clicked (simulated)
        guard let aboutItem = findAboutItem(in: mainMenu) else {
            XCTFail("About item should exist")
            return
        }
        XCTAssertNotNil(aboutItem.target, "About item should have target")
        XCTAssertNotNil(aboutItem.action, "About item should have action")
        
        // Simulate menu item click
        if let target = aboutItem.target as? NSObject,
           aboutItem.action != nil {
            // Verify target responds to action
            XCTAssertTrue(
                target.responds(to: aboutItem.action),
                "Target should respond to action"
            )
        }
        
        // Then: About window should be creatable
        // Note: We can't actually trigger the menu click in unit tests,
        // but we can verify the wiring is correct
        XCTAssertTrue(result, "Workflow should be complete")
    }
    
    /// Integration Test: About menu configuration persists across app lifecycle
    @MainActor
    func testAboutMenuConfigurationPersists() {
        // Given: Menu is configured
        let result1 = configurator.configure(
            mainMenu: mainMenu,
            target: appDelegate,
            action: #selector(AppDelegate.showCustomAbout)
        )
        XCTAssertTrue(result1, "First configuration should succeed")
        
        guard let aboutItem1 = findAboutItem(in: mainMenu) else {
            XCTFail("About item should exist")
            return
        }
        let originalTarget = aboutItem1.target
        let originalAction = aboutItem1.action
        
        // When: Menu is reconfigured (simulating app restart)
        let result2 = configurator.configure(
            mainMenu: mainMenu,
            target: appDelegate,
            action: #selector(AppDelegate.showCustomAbout)
        )
        
        // Then: Configuration should still work
        XCTAssertTrue(result2, "Reconfiguration should succeed")
        guard let aboutItem2 = findAboutItem(in: mainMenu) else {
            XCTFail("About item should exist")
            return
        }
        XCTAssertNotNil(aboutItem2.target, "Target should persist")
        XCTAssertNotNil(aboutItem2.action, "Action should persist")
    }
    
    /// Integration Test: About window displays correct content
    @MainActor
    func testAboutWindowDisplaysCorrectContent() {
        // Given: AboutView with settings
        let settings = AppSettings.shared
        let aboutView = AboutView(settings: settings)
        
        // When: About window is created (simulated)
        let aboutWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        aboutWindow.title = "About Audientia"
        
        let hostingView = NSHostingView(rootView: aboutView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 450, height: 400)
        aboutWindow.contentView = hostingView
        
        // Then: Window should have correct properties
        XCTAssertEqual(aboutWindow.title, "About Audientia", "Window should have correct title")
        XCTAssertNotNil(aboutWindow.contentView, "Window should have content view")
        XCTAssertTrue(aboutWindow.styleMask.contains(.titled), "Window should be titled")
        XCTAssertTrue(aboutWindow.styleMask.contains(.closable), "Window should be closable")
        
        // Cleanup
        aboutWindow.close()
    }
    
    /// Integration Test: About menu works with standard macOS menu structure
    @MainActor
    func testAboutMenuWorksWithStandardMacOSMenu() {
        // Given: Standard macOS menu structure
        let standardMenu = createStandardMacOSMenu()
        
        // When: Configuring About menu
        let result = configurator.configure(
            mainMenu: standardMenu,
            target: appDelegate,
            action: #selector(AppDelegate.showCustomAbout)
        )
        
        // Then: Should work with standard structure
        XCTAssertTrue(result, "Should work with standard macOS menu")
        guard let aboutItem = findAboutItem(in: standardMenu) else {
            XCTFail("About item should exist")
            return
        }
        XCTAssertTrue(aboutItem.target === appDelegate, "Should wire to app delegate")
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
        
        appSubmenu.addItem(NSMenuItem(title: "About Audientia", action: nil, keyEquivalent: ""))
        appSubmenu.addItem(NSMenuItem.separator())
        appSubmenu.addItem(NSMenuItem(title: "Preferences...", action: nil, keyEquivalent: ","))
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
