//
//  KeyboardNavigationManager.swift
//  Audientia
//
//  Manages keyboard navigation focus order and state
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import Shared

/// Manages keyboard navigation focus order and state
/// Provides focus order management, focus state tracking, and navigation operations
@MainActor
public final class KeyboardNavigationManager: ObservableObject {
    
    // MARK: - Properties
    
    /// Current focused element
    @Published public private(set) var currentFocus: KeyboardNavigationElement?
    
    /// Focus order (sections in navigation sequence)
    public let focusOrder: [KeyboardNavigationSection] = [
        .toolbar,
        .sidebar,
        .content,
        .player
    ]
    
    /// All available navigation elements organized by section
    private let elementsBySection: [KeyboardNavigationSection: [KeyboardNavigationElement]]
    
    /// Flat list of all elements in focus order
    private let allElements: [KeyboardNavigationElement]
    
    // MARK: - Initialization
    
    public init() {
        // Initialize elements by section
        var elements: [KeyboardNavigationSection: [KeyboardNavigationElement]] = [:]
        
        // Toolbar elements
        elements[.toolbar] = TabItem.allCases.map { .toolbarTab($0) } + [.toolbarCollapse]
        
        // Sidebar elements (will be populated dynamically based on current tab)
        elements[.sidebar] = [
            .sidebarSearch,
            .sidebarNavItem("quickAccess"),
            .sidebarAction("importFiles")
        ]
        
        // Content elements (will be populated dynamically)
        elements[.content] = [
            .contentTrack(index: 0)
        ]
        
        // Player elements
        elements[.player] = [
            .playerPrevious,
            .playerPlayPause,
            .playerStop,
            .playerNext,
            .playerShuffle,
            .playerLoop,
            .playerVolume,
            .playerCollapse
        ]
        
        self.elementsBySection = elements
        
        // Create flat list in focus order
        var allElements: [KeyboardNavigationElement] = []
        for section in focusOrder {
            if let sectionElements = elements[section] {
                allElements.append(contentsOf: sectionElements)
            }
        }
        self.allElements = allElements
    }
    
    // MARK: - Focus Management
    
    /// Set focus to a specific element
    /// - Parameter element: The element to focus
    public func setFocus(to element: KeyboardNavigationElement) {
        currentFocus = element
    }
    
    /// Clear current focus
    public func clearFocus() {
        currentFocus = nil
    }
    
    /// Restore focus to previously focused element (if available)
    public func restoreFocus() {
        // For now, restore to first element if no focus is set
        if currentFocus == nil, let firstElement = allElements.first {
            currentFocus = firstElement
        }
    }
    
    // MARK: - Navigation
    
    /// Move focus forward (Tab key)
    /// - Returns: The new focused element, or nil if navigation failed
    @discardableResult
    public func moveFocusForward() -> KeyboardNavigationElement? {
        guard let current = currentFocus else {
            // If no focus, set to first element
            if let firstElement = allElements.first {
                currentFocus = firstElement
                return firstElement
            }
            return nil
        }
        
        // Find current element index
        guard let currentIndex = allElements.firstIndex(of: current) else {
            // Current element not found, set to first
            if let firstElement = allElements.first {
                currentFocus = firstElement
                return firstElement
            }
            return nil
        }
        
        // Move to next element (wrap around)
        let nextIndex = (currentIndex + 1) % allElements.count
        let nextElement = allElements[nextIndex]
        currentFocus = nextElement
        
        return nextElement
    }
    
    /// Move focus backward (Shift+Tab key)
    /// - Returns: The new focused element, or nil if navigation failed
    @discardableResult
    public func moveFocusBackward() -> KeyboardNavigationElement? {
        guard let current = currentFocus else {
            // If no focus, set to last element
            if let lastElement = allElements.last {
                currentFocus = lastElement
                return lastElement
            }
            return nil
        }
        
        // Find current element index
        guard let currentIndex = allElements.firstIndex(of: current) else {
            // Current element not found, set to last
            if let lastElement = allElements.last {
                currentFocus = lastElement
                return lastElement
            }
            return nil
        }
        
        // Move to previous element (wrap around)
        let previousIndex = currentIndex == 0 ? allElements.count - 1 : currentIndex - 1
        let previousElement = allElements[previousIndex]
        currentFocus = previousElement
        
        return previousElement
    }
    
    /// Move focus to first element in a section
    /// - Parameter section: The section to focus
    /// - Returns: The focused element, or nil if section is empty
    @discardableResult
    public func moveFocusToSection(_ section: KeyboardNavigationSection) -> KeyboardNavigationElement? {
        guard let sectionElements = elementsBySection[section],
              let firstElement = sectionElements.first else {
            return nil
        }
        
        currentFocus = firstElement
        return firstElement
    }
    
    /// Get all elements in a section
    /// - Parameter section: The section
    /// - Returns: Array of elements in the section
    public func elements(in section: KeyboardNavigationSection) -> [KeyboardNavigationElement] {
        elementsBySection[section] ?? []
    }
}
