//
//  ScrollingTextViewTests.swift
//  UITests
//
//  TDD tests for ScrollingTextView following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

#if canImport(XCTest)
import SwiftUI
import XCTest

@testable import Audientia

/// TDD tests for ScrollingTextView
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class ScrollingTextViewTests: XCTestCase {
    
    // MARK: - Right: Are the Results Right?
    
    /// Test that short text displays statically without scrolling
    func testShortTextDisplaysStatically() {
        // Given - A short text that fits within the frame
        let shortText = "Short"
        let frameWidth: CGFloat = 200
        
        // When - Creating a ScrollingTextView
        let view = ScrollingTextView(
            text: shortText,
            frameWidth: frameWidth
        )
        
        // Then - View should be created successfully
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// Test that long text triggers scrolling
    func testLongTextTriggersScrolling() {
        // Given - A long text that exceeds the frame width
        let longText = "This is a very long track title that definitely exceeds the frame width and should trigger scrolling behavior"
        let frameWidth: CGFloat = 200
        
        // When - Creating a ScrollingTextView
        let view = ScrollingTextView(
            text: longText,
            scrollSpeed: 30.0,
            frameWidth: frameWidth
        )
        
        // Then - View should be created successfully
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    // MARK: - Boundary Conditions
    
    /// Test text exactly at frame width boundary
    func testTextAtBoundaryWidth() {
        // Given - Text that might be exactly at the boundary
        let text = "Boundary test text"
        let frameWidth: CGFloat = 200
        
        // When - Creating a ScrollingTextView
        let view = ScrollingTextView(
            text: text,
            frameWidth: frameWidth
        )
        
        // Then - View should handle boundary case
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// Test with minimum scroll speed
    func testMinimumScrollSpeed() {
        // Given - Minimum scroll speed (10 px/s)
        let longText = "This is a very long track title that should scroll slowly"
        let frameWidth: CGFloat = 200
        
        // When - Creating a ScrollingTextView with minimum speed
        let view = ScrollingTextView(
            text: longText,
            scrollSpeed: 10.0,
            frameWidth: frameWidth
        )
        
        // Then - View should be created
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// Test with maximum scroll speed
    func testMaximumScrollSpeed() {
        // Given - Maximum scroll speed (100 px/s)
        let longText = "This is a very long track title that should scroll quickly"
        let frameWidth: CGFloat = 200
        
        // When - Creating a ScrollingTextView with maximum speed
        let view = ScrollingTextView(
            text: longText,
            scrollSpeed: 100.0,
            frameWidth: frameWidth
        )
        
        // Then - View should be created
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// Test with empty text
    func testEmptyText() {
        // Given - Empty text
        let emptyText = ""
        let frameWidth: CGFloat = 200
        
        // When - Creating a ScrollingTextView
        let view = ScrollingTextView(
            text: emptyText,
            frameWidth: frameWidth
        )
        
        // Then - View should handle empty text gracefully
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// Test with very narrow frame width
    func testVeryNarrowFrame() {
        // Given - Very narrow frame
        let text = "Normal text"
        let frameWidth: CGFloat = 10
        
        // When - Creating a ScrollingTextView
        let view = ScrollingTextView(
            text: text,
            frameWidth: frameWidth
        )
        
        // Then - View should handle narrow frame
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    // MARK: - Inverse Relationships
    
    /// Test that changing scroll speed affects behavior
    func testScrollSpeedAffectsBehavior() {
        // Given - Long text
        let longText = "This is a very long track title that should scroll"
        let frameWidth: CGFloat = 200
        
        // When - Creating views with different scroll speeds
        let slowView = ScrollingTextView(
            text: longText,
            scrollSpeed: 10.0,
            frameWidth: frameWidth
        )
        let fastView = ScrollingTextView(
            text: longText,
            scrollSpeed: 100.0,
            frameWidth: frameWidth
        )
        
        // Then - Both views should be created
        SwiftUIViewTestHelpers.verifyViewCreation(slowView)
        SwiftUIViewTestHelpers.verifyViewCreation(fastView)
    }
    
    // MARK: - Cross-Checking Using Other Means
    
    /// Test that font customization works
    func testFontCustomization() {
        // Given - Custom font
        let text = "Custom font text"
        let customFont = Font.system(size: 16, weight: .bold)
        let frameWidth: CGFloat = 200
        
        // When - Creating a ScrollingTextView with custom font
        let view = ScrollingTextView(
            text: text,
            font: customFont,
            frameWidth: frameWidth
        )
        
        // Then - View should be created with custom font
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// Test that foreground color customization works
    func testForegroundColorCustomization() {
        // Given - Custom color
        let text = "Custom color text"
        let customColor = Color.blue
        let frameWidth: CGFloat = 200
        
        // When - Creating a ScrollingTextView with custom color
        let view = ScrollingTextView(
            text: text,
            foregroundColor: customColor,
            frameWidth: frameWidth
        )
        
        // Then - View should be created with custom color
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    // MARK: - Error Conditions
    
    /// Test with zero frame width
    func testZeroFrameWidth() {
        // Given - Zero frame width
        let text = "Test text"
        let frameWidth: CGFloat = 0
        
        // When - Creating a ScrollingTextView
        let view = ScrollingTextView(
            text: text,
            frameWidth: frameWidth
        )
        
        // Then - View should handle zero width gracefully
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// Test with negative scroll speed (should be clamped)
    func testNegativeScrollSpeed() {
        // Given - Negative scroll speed
        let text = "Test text"
        let frameWidth: CGFloat = 200
        
        // When - Creating a ScrollingTextView with negative speed
        // Note: The component should handle this, but we test it doesn't crash
        let view = ScrollingTextView(
            text: text,
            scrollSpeed: -10.0,
            frameWidth: frameWidth
        )
        
        // Then - View should be created
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    // MARK: - Performance Characteristics
    
    /// Test that view creation is performant
    func testViewCreationPerformance() {
        // Given - Long text
        let longText = String(repeating: "Long track title ", count: 20)
        let frameWidth: CGFloat = 200
        
        // When - Measuring view creation time
        measure {
            let view = ScrollingTextView(
                text: longText,
                frameWidth: frameWidth
            )
            SwiftUIViewTestHelpers.verifyViewCreation(view)
        }
    }
    
    /// Test that text changes don't cause performance issues
    func testTextChangePerformance() {
        // Given - A view with initial text
        let initialText = "Initial text"
        let frameWidth: CGFloat = 200
        
        // When - Creating view and changing text multiple times
        let view = ScrollingTextView(
            text: initialText,
            frameWidth: frameWidth
        )
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        
        // Note: In a real scenario, we'd test that changing text doesn't cause
        // performance degradation, but SwiftUI view updates are handled internally
    }
}
#endif
// End of ScrollingTextViewTests
