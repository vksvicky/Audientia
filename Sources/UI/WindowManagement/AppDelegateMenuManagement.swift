//
//  AppDelegateMenuManagement.swift
//  Audientia
//
//  Menu and keyboard shortcut management extension for AppDelegate
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import Foundation

extension AppDelegate {
    @MainActor
    func disableKeyboardShortcuts() {
        shortcutsDisabled = true
        // Disable menu items that have keyboard shortcuts
        if let mainMenu = NSApplication.shared.mainMenu {
            disableMenuShortcuts(menu: mainMenu)
        }
    }
    
    @MainActor
    func enableKeyboardShortcuts() {
        shortcutsDisabled = false
        // Re-enable menu items
        if let mainMenu = NSApplication.shared.mainMenu {
            enableMenuShortcuts(menu: mainMenu)
        }
    }
    
    private func disableMenuShortcuts(menu: NSMenu) {
        for item in menu.items {
            if !item.keyEquivalent.isEmpty {
                item.isEnabled = false
            }
            if let submenu = item.submenu {
                disableMenuShortcuts(menu: submenu)
            }
        }
    }
    
    private func enableMenuShortcuts(menu: NSMenu) {
        for item in menu.items {
            if !item.keyEquivalent.isEmpty {
                item.isEnabled = true
            }
            if let submenu = item.submenu {
                enableMenuShortcuts(menu: submenu)
            }
        }
    }
}
