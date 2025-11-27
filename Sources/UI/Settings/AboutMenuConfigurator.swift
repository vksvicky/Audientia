//
//  AboutMenuConfigurator.swift
//  Audientia
//
//  Small helper responsible for wiring the About menu item to our custom window handler.
//

import AppKit

/// Configures the "About Audientia" menu item to point at the provided target/action.
struct AboutMenuConfigurator {
    /// Wires the About menu item found inside the application menu (`NSApp.mainMenu?.item(at: 0)`)
    /// to the supplied target/action pair.
    /// - Returns: `true` when the item was found and updated, `false` otherwise.
    @discardableResult
    func configure(mainMenu: NSMenu?, target: AnyObject, action: Selector) -> Bool {
        guard
            let appMenuItem = mainMenu?.item(at: 0),
            let appSubmenu = appMenuItem.submenu,
            let aboutItem = appSubmenu.item(withTitle: "About Audientia")
        else {
            return false
        }

        aboutItem.target = target
        aboutItem.action = action
        return true
    }
}
