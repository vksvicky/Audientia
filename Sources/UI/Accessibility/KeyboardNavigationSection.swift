//
//  KeyboardNavigationSection.swift
//  Audientia
//
//  Keyboard navigation sections for focus order management
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

/// Sections of the UI that can receive keyboard focus
/// Defines the order of navigation: toolbar → sidebar → content → player
public enum KeyboardNavigationSection: String, CaseIterable, Hashable {
    case toolbar
    case sidebar
    case content
    case player
}
