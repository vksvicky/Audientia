//
//  AboutMenuWiringTests.swift
//  AudientiaUITests
//
//  Verifies the About menu wiring so the custom About window is reachable.
//

import AppKit
import XCTest

@testable import Audientia

final class AboutMenuWiringTests: XCTestCase {
    func testConfiguratorWiresMenuItemToCustomTarget() {
        // Given a main menu with an About item
        let mainMenu = NSMenu(title: "Main")
        let appMenuItem = NSMenuItem(title: "Audientia", action: nil, keyEquivalent: "")
        let appSubmenu = NSMenu(title: "App")
        let aboutItem = NSMenuItem(title: "About Audientia", action: nil, keyEquivalent: "")
        appSubmenu.addItem(aboutItem)
        appMenuItem.submenu = appSubmenu
        mainMenu.addItem(appMenuItem)

        let configurator = AboutMenuConfigurator()
        let target = DummyTarget()
        let selector = #selector(DummyTarget.showAbout)

        // When configuring
        let result = configurator.configure(mainMenu: mainMenu, target: target, action: selector)

        // Then the About item should be wired to our target/action
        XCTAssertTrue(result, "Configurator should find and wire the About menu item")
        XCTAssertTrue(aboutItem.target === target, "Target should be set to the provided object")
        XCTAssertEqual(aboutItem.action, selector, "Action should be set to the provided selector")
    }
}

private final class DummyTarget: NSObject {
    @objc func showAbout() {}
}
