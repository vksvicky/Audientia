//
//  ListNavigationManager.swift
//  Audientia
//
//  Manages arrow key navigation for lists and grids
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

/// Manages arrow key navigation for lists and grids
/// Provides selection management and navigation operations
@MainActor
public final class ListNavigationManager<T: Hashable>: ObservableObject {
    
    // MARK: - Properties
    
    /// Currently selected item index
    @Published public private(set) var selectedIndex: Int?
    
    /// Total number of items in the list
    @Published public private(set) var itemCount: Int
    
    /// Currently selected item (if available)
    public var selectedItem: T? {
        guard let index = selectedIndex,
              index >= 0,
              index < items.count else {
            return nil
        }
        return items[index]
    }
    
    /// All items in the list
    private var items: [T] = []
    
    // MARK: - Initialization
    
    public init(itemCount: Int = 0) {
        self.itemCount = itemCount
    }
    
    // MARK: - Item Management
    
    /// Update the list of items
    /// - Parameter items: The new list of items
    public func updateItems(_ items: [T]) {
        self.items = items
        self.itemCount = items.count
        
        // Adjust selected index if it's out of bounds
        if let index = selectedIndex, index >= itemCount {
            selectedIndex = itemCount > 0 ? itemCount - 1 : nil
        }
    }
    
    /// Set the selected index
    /// - Parameter index: The index to select (nil to deselect)
    public func selectIndex(_ index: Int?) {
        guard let index = index else {
            selectedIndex = nil
            return
        }
        
        if index < 0 {
            // Negative index: set to nil
            selectedIndex = nil
        } else if index >= itemCount {
            // Out of bounds: adjust to last valid index if items exist
            selectedIndex = itemCount > 0 ? itemCount - 1 : nil
        } else {
            // Valid index
            selectedIndex = index
        }
    }
    
    /// Select an item by value
    /// - Parameter item: The item to select
    public func selectItem(_ item: T) {
        if let index = items.firstIndex(of: item) {
            selectedIndex = index
        }
    }
    
    // MARK: - Navigation
    
    /// Move selection up (Up arrow key)
    /// - Returns: The new selected index, or nil if navigation failed
    @discardableResult
    public func moveUp() -> Int? {
        guard itemCount > 0 else {
            return nil
        }
        
        if let currentIndex = selectedIndex {
            if currentIndex > 0 {
                selectedIndex = currentIndex - 1
                return selectedIndex
            } else {
                // Wrap to last item
                selectedIndex = itemCount - 1
                return selectedIndex
            }
        } else {
            // No selection, select last item
            selectedIndex = itemCount - 1
            return selectedIndex
        }
    }
    
    /// Move selection down (Down arrow key)
    /// - Returns: The new selected index, or nil if navigation failed
    @discardableResult
    public func moveDown() -> Int? {
        guard itemCount > 0 else {
            return nil
        }
        
        if let currentIndex = selectedIndex {
            if currentIndex < itemCount - 1 {
                selectedIndex = currentIndex + 1
                return selectedIndex
            } else {
                // Wrap to first item
                selectedIndex = 0
                return selectedIndex
            }
        } else {
            // No selection, select first item
            selectedIndex = 0
            return selectedIndex
        }
    }
    
    /// Move selection left (Left arrow key for grids)
    /// - Parameter columnsPerRow: Number of columns in the grid
    /// - Returns: The new selected index, or nil if navigation failed
    @discardableResult
    public func moveLeft(columnsPerRow: Int = 1) -> Int? {
        guard itemCount > 0, columnsPerRow > 0 else {
            return nil
        }
        
        guard let currentIndex = selectedIndex else {
            // No selection, select last item
            selectedIndex = itemCount - 1
            return selectedIndex
        }
        
        if currentIndex >= columnsPerRow {
            // Move to previous row
            selectedIndex = currentIndex - columnsPerRow
            return selectedIndex
        } else {
            // Wrap to last row, same column position
            let column = currentIndex % columnsPerRow
            // Calculate last row start: ((itemCount - 1) / columnsPerRow) * columnsPerRow
            // This handles cases where the last row is incomplete
            let lastRowStart = ((itemCount - 1) / columnsPerRow) * columnsPerRow
            let targetIndex = min(lastRowStart + column, itemCount - 1)
            selectedIndex = targetIndex
            return selectedIndex
        }
    }
    
    /// Move selection right (Right arrow key for grids)
    /// - Parameter columnsPerRow: Number of columns in the grid
    /// - Returns: The new selected index, or nil if navigation failed
    @discardableResult
    public func moveRight(columnsPerRow: Int = 1) -> Int? {
        guard itemCount > 0, columnsPerRow > 0 else {
            return nil
        }
        
        guard let currentIndex = selectedIndex else {
            // No selection, select first item
            selectedIndex = 0
            return selectedIndex
        }
        
        if currentIndex + columnsPerRow < itemCount {
            // Move to next row
            selectedIndex = currentIndex + columnsPerRow
            return selectedIndex
        } else {
            // Wrap to first row, same column position
            let column = currentIndex % columnsPerRow
            selectedIndex = column
            return selectedIndex
        }
    }
    
    /// Clear selection
    public func clearSelection() {
        selectedIndex = nil
    }
    
    /// Select first item
    public func selectFirst() {
        if itemCount > 0 {
            selectedIndex = 0
        }
    }
    
    /// Select last item
    public func selectLast() {
        if itemCount > 0 {
            selectedIndex = itemCount - 1
        }
    }
}
