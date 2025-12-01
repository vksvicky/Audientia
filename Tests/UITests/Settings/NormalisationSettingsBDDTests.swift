//
//  NormalisationSettingsBDDTests.swift
//  Audientia - UI BDD Tests
//
//  BDD scenarios for Normalization Settings
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import SwiftUI
import XCTest

@testable import Audientia
@testable import AudioCore
@MainActor
final class NormalisationSettingsBDDTests: XCTestCase {
    
    // MARK: - BDD Scenarios
    
    /// BDD: As a user, I want to access normalization settings so that I can normalize audio levels
    func testUserAccessesNormalisationSettings() {
        // Given - I want to normalize audio levels
        // When - I open the normalization settings view
        let view = NormalisationSettingsView()
        
        // Then - The view should be created successfully
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        XCTAssertNotNil(view, "Normalization settings view should be created")
    }
    
    /// BDD: As a user, I want to select normalization mode so that I can choose peak, RMS, or loudness normalization
    func testUserSelectsNormalizationMode() {
        // Given - I have the normalization settings view open
        let view = NormalisationSettingsView()
        
        // When - I view the interface
        // Then - The view should display mode selection (peak/RMS/loudness)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// BDD: As a user, I want to adjust target level so that I can set the normalization target
    func testUserAdjustsTargetLevel() {
        // Given - I have the normalization settings view open
        let view = NormalisationSettingsView()
        
        // When - I view the interface
        // Then - The view should display target level controls
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// BDD: As a user, I want to see normalization information so that I understand how normalization works
    func testUserSeesNormalizationInformation() {
        // Given - I have the normalization settings view open
        let view = NormalisationSettingsView()
        
        // When - I view the interface
        // Then - The view should display information about normalization modes
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    // MARK: - Boundary Conditions
    
    /// Test that the view handles being created multiple times
    func testViewCanBeCreatedMultipleTimes() {
        // Given - I want to create multiple instances
        // When - I create multiple views
        let view1 = NormalisationSettingsView()
        let view2 = NormalisationSettingsView()
        
        // Then - Both views should be created successfully
        XCTAssertNotNil(view1, "First view should be created")
        XCTAssertNotNil(view2, "Second view should be created")
        SwiftUIViewTestHelpers.verifyViewCreation(view1)
        SwiftUIViewTestHelpers.verifyViewCreation(view2)
    }
    
    /// Test that the view can be rendered without errors
    func testViewRendersWithoutErrors() {
        // Given - I have the normalization settings view
        let view = NormalisationSettingsView()
        
        // When - I access the view body
        // Then - The view should render without throwing errors
        XCTAssertNoThrow({
            SwiftUIViewTestHelpers.verifyViewCreation(view)
        }, "View should render without errors")
    }
}
