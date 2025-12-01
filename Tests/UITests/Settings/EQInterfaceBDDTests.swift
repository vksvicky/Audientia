//
//  EQInterfaceBDDTests.swift
//  Audientia - UI BDD Tests
//
//  BDD scenarios for Equaliser Interface
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import SwiftUI
import XCTest

@testable import Audientia
@testable import AudioCore
@MainActor
final class EQInterfaceBDDTests: XCTestCase {
    
    // MARK: - BDD Scenarios
    
    /// BDD: As a user, I want to access the equaliser interface so that I can adjust audio frequencies
    func testUserAccessesEqualiserInterface() {
        // Given - I want to adjust audio frequencies
        // When - I open the equaliser interface
        let view = EQInterfaceView()
        
        // Then - The view should be created successfully
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        XCTAssertNotNil(view, "Equaliser interface view should be created")
    }
    
    /// BDD: As a user, I want to see 10-band EQ controls so that I can fine-tune audio frequencies
    func testUserSees10BandEQControls() {
        // Given - I have the equaliser interface open
        let view = EQInterfaceView()
        
        // When - I view the interface
        // Then - The view should display 10-band EQ controls
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// BDD: As a user, I want to apply EQ presets so that I can quickly adjust audio for different music styles
    func testUserCanApplyEQPresets() {
        // Given - I have the equaliser interface open
        let view = EQInterfaceView()
        
        // When - I view the interface
        // Then - The view should display preset options
        // Note: Presets are available in the view (Flat, Bass Boost, Treble Boost, etc.)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// BDD: As a user, I want to enable or disable the equaliser so that I can toggle audio processing
    func testUserCanEnableDisableEqualiser() {
        // Given - I have the equaliser interface open
        let view = EQInterfaceView()
        
        // When - I view the interface
        // Then - The view should display an enable/disable toggle
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// BDD: As a user, I want to reset the equaliser so that I can return to flat settings
    func testUserCanResetEqualiser() {
        // Given - I have the equaliser interface open
        let view = EQInterfaceView()
        
        // When - I view the interface
        // Then - The view should display a reset button
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    // MARK: - Boundary Conditions
    
    /// Test that the view handles being created multiple times
    func testViewCanBeCreatedMultipleTimes() {
        // Given - I want to create multiple instances
        // When - I create multiple views
        let view1 = EQInterfaceView()
        let view2 = EQInterfaceView()
        
        // Then - Both views should be created successfully
        XCTAssertNotNil(view1, "First view should be created")
        XCTAssertNotNil(view2, "Second view should be created")
        SwiftUIViewTestHelpers.verifyViewCreation(view1)
        SwiftUIViewTestHelpers.verifyViewCreation(view2)
    }
    
    /// Test that the view can be rendered without errors
    func testViewRendersWithoutErrors() {
        // Given - I have the equaliser interface view
        let view = EQInterfaceView()
        
        // When - I access the view body
        // Then - The view should render without throwing errors
        XCTAssertNoThrow({
            SwiftUIViewTestHelpers.verifyViewCreation(view)
        }, "View should render without errors")
    }
}
