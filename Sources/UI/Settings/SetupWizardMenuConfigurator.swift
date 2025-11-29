//
//  SetupWizardMenuConfigurator.swift
//  Audientia
//
//  Configures the Setup Wizard menu item
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import os.log
import Shared

/// Configures the "Setup Wizard" menu item
public struct SetupWizardMenuConfigurator {
    /// Wires the Setup Wizard menu item to the provided target/action pair
    /// - Parameters:
    ///   - mainMenu: The main application menu
    ///   - target: Target object for the action
    ///   - action: Selector for the action
    /// - Returns: `true` when the item was found and updated, `false` otherwise
    @discardableResult
    public func configure(mainMenu: NSMenu?, target: AnyObject, action: Selector) -> Bool {
        guard let mainMenu = mainMenu else {
            Logger.userInterface.error("mainMenu is nil")
            return false
        }
        
        // Look for "File" menu
        var fileMenu: NSMenuItem?
        for i in 0..<(mainMenu.numberOfItems) {
            if let item = mainMenu.item(at: i), item.title == "File" {
                fileMenu = item
                break
            }
        }
        
        guard let fileMenu = fileMenu else {
            Logger.userInterface.error("File menu not found")
            return false
        }
        
        guard let submenu = fileMenu.submenu else {
            Logger.userInterface.error("File menu submenu is nil")
            return false
        }
        
        // Remove "New Window" menu item - media players don't need multiple windows
        if let newWindowItem = submenu.item(withTitle: "New Window") {
            submenu.removeItem(newWindowItem)
            Logger.userInterface.info("Removed 'New Window' menu item")
        }
        
        // Check if Setup Wizard item already exists
        if let existingItem = submenu.item(withTitle: "Setup Wizard...") {
            // Always update to ensure it's properly configured
            existingItem.target = target
            existingItem.action = action
            existingItem.keyEquivalent = "s"
            existingItem.keyEquivalentModifierMask = [.command, .shift]
            existingItem.toolTip = "Open the setup wizard (⌘⇧S)"
            Logger.userInterface.info("Updated existing Setup Wizard menu item")
            return true
        }
        
        // Create new menu item
        let setupItem = NSMenuItem(
            title: "Setup Wizard...",
            action: action,
            keyEquivalent: "s"
        )
        setupItem.target = target
        setupItem.keyEquivalentModifierMask = [.command, .shift]
        setupItem.toolTip = "Open the setup wizard (⌘⇧S)"
        
        // Insert at the top of the File menu (position 0)
        submenu.insertItem(setupItem, at: 0)
        
        // Add a separator after Setup Wizard
        submenu.insertItem(NSMenuItem.separator(), at: 1)
        
        Logger.userInterface.info("Added Setup Wizard menu item at position 0")
        return true
    }
}
