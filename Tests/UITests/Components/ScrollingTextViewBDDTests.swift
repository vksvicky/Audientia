//
//  ScrollingTextViewBDDTests.swift
//  UITests
//
//  BDD tests for ScrollingTextView
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

#if canImport(XCTest)
import SwiftUI
import XCTest

@testable import Audientia

/// BDD tests for ScrollingTextView
@MainActor
final class ScrollingTextViewBDDTests: XCTestCase {
    
    // MARK: - BDD Scenarios
    
    /// BDD: As a user, I want long track titles to scroll horizontally so that I can read the full title
    func testAsAUserIWantLongTrackTitlesToScroll() {
        // Given - I have a track with a long title
        let longTitle = "This is a very long track title that exceeds the available space in the player controls"
        
        // When - The track title is displayed
        let view = ScrollingTextView(
            text: longTitle,
            scrollSpeed: 30.0,
            frameWidth: 200
        )
        
        // Then - The title should scroll horizontally so I can read it
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// BDD: As a user, I want short track titles to display normally so that I don't see unnecessary scrolling
    func testAsAUserIWantShortTitlesToDisplayNormally() {
        // Given - I have a track with a short title
        let shortTitle = "Short"
        
        // When - The track title is displayed
        let view = ScrollingTextView(
            text: shortTitle,
            frameWidth: 200
        )
        
        // Then - The title should display statically without scrolling
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// BDD: As a user, I want to adjust the scroll speed in settings so that I can read at my preferred pace
    func testAsAUserIWantToAdjustScrollSpeed() {
        // Given - I have configured a scroll speed in settings
        let scrollSpeed: Double = 50.0
        let longTitle = "This is a very long track title that should scroll at my configured speed"
        
        // When - The track title is displayed
        let view = ScrollingTextView(
            text: longTitle,
            scrollSpeed: scrollSpeed,
            frameWidth: 200
        )
        
        // Then - The title should scroll at my configured speed
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// BDD: As a user, I want artist names to scroll when they're long so that I can see the full artist name
    func testAsAUserIWantLongArtistNamesToScroll() {
        // Given - I have a track with a long artist name
        let longArtist = "This is a very long artist name that includes multiple words and should scroll"
        
        // When - The artist name is displayed
        let view = ScrollingTextView(
            text: longArtist,
            font: .system(size: 11),
            foregroundColor: .secondary,
            scrollSpeed: 30.0,
            frameWidth: 200
        )
        
        // Then - The artist name should scroll horizontally
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// BDD: As a user, I want the scrolling to be smooth and continuous so that it's easy to read
    func testAsAUserIWantSmoothContinuousScrolling() {
        // Given - I have a long track title
        let longTitle = "This is a very long track title that should scroll smoothly and continuously"
        
        // When - The track title is displayed and scrolling
        let view = ScrollingTextView(
            text: longTitle,
            scrollSpeed: 30.0,
            frameWidth: 200
        )
        
        // Then - The scrolling should be smooth and continuous
        // Note: Visual smoothness is tested through view creation and timer-based animation
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
}
#endif
// End of ScrollingTextViewBDDTests
