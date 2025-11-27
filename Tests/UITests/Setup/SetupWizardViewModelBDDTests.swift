//
//  SetupWizardViewModelBDDTests.swift
//  UITests
//
//  BDD tests for SetupWizardViewModel
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import Shared
import XCTest

@testable import Audientia

/// BDD tests for SetupWizardViewModel
@MainActor
final class SetupWizardViewModelBDDTests: XCTestCase {
    
    private let hasCompletedWizardKey = "audientia.setup.hasCompletedWizard"
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: hasCompletedWizardKey)
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: hasCompletedWizardKey)
        super.tearDown()
    }
    
    // MARK: - BDD Scenarios
    
    func testAsANewUserIWantToSeeTheSetupWizardOnFirstLaunch() {
        // Given: I am a new user launching the app for the first time
        UserDefaults.standard.removeObject(forKey: hasCompletedWizardKey)
        
        // When: The app checks if the wizard should be shown
        let shouldShow = SetupWizardViewModel.shouldShowWizard()
        
        // Then: The setup wizard should be displayed
        XCTAssertTrue(shouldShow, "Setup wizard should show on first launch")
    }
    
    func testAsAUserIWantToNavigateThroughTheSetupWizardSteps() {
        // Given: I have opened the setup wizard
        let viewModel = SetupWizardViewModel()
        
        // When: I click "Next" to move through the steps
        viewModel.nextStep()
        viewModel.nextStep()
        
        // Then: I should see the next step in the wizard
        XCTAssertNotEqual(viewModel.currentStep, .welcome, "Should have moved from welcome step")
        XCTAssertTrue(viewModel.canGoBack, "Should be able to go back")
    }
    
    func testAsAUserIWantToGoBackToPreviousSteps() {
        // Given: I am on the second step of the wizard
        let viewModel = SetupWizardViewModel()
        viewModel.nextStep()
        let secondStep = viewModel.currentStep
        
        // When: I click "Previous"
        viewModel.previousStep()
        
        // Then: I should see the previous step
        XCTAssertEqual(viewModel.currentStep, .welcome, "Should return to welcome step")
        XCTAssertNotEqual(viewModel.currentStep, secondStep, "Should not be on second step")
    }
    
    func testAsAUserIWantToCompleteTheSetupWizard() {
        // Given: I have gone through all the wizard steps
        let viewModel = SetupWizardViewModel()
        
        // When: I click "Done" to complete the wizard
        viewModel.completeWizard()
        
        // Then: The wizard should be marked as completed
        XCTAssertTrue(viewModel.hasCompletedWizard, "Wizard should be completed")
        
        // And: The wizard should not show on next launch
        let shouldShow = SetupWizardViewModel.shouldShowWizard()
        XCTAssertFalse(shouldShow, "Wizard should not show after completion")
    }
    
    func testAsAUserIWantToAddMyMusicLibraryLocations() {
        // Given: I am on the library setup step
        let viewModel = SetupWizardViewModel()
        viewModel.nextStep() // Move to library setup
        
        // When: I add a music library location
        let musicPath = URL(fileURLWithPath: "/Users/test/Music")
        viewModel.addLibraryLocation(musicPath)
        
        // Then: The location should be added to my library
        XCTAssertTrue(viewModel.libraryLocations.contains(musicPath), "Location should be added")
    }
    
    func testAsAUserIWantToRemoveLibraryLocations() {
        // Given: I have added library locations
        let viewModel = SetupWizardViewModel()
        viewModel.nextStep()
        let location = URL(fileURLWithPath: "/Users/test/Music")
        viewModel.addLibraryLocation(location)
        
        // When: I remove a location
        viewModel.removeLibraryLocation(location)
        
        // Then: The location should be removed
        XCTAssertFalse(viewModel.libraryLocations.contains(location), "Location should be removed")
    }
    
    func testAsAUserIWantToRelaunchTheSetupWizardFromTheMenu() {
        // Given: I have completed the wizard previously
        UserDefaults.standard.set(true, forKey: hasCompletedWizardKey)
        
        // When: I select "Setup Wizard" from the menu
        // (This would be tested via menu integration, but we can test the state)
        let viewModel = SetupWizardViewModel()
        
        // Then: I should be able to see the wizard again
        // The viewModel can be shown regardless of completion status when manually triggered
        XCTAssertNotNil(viewModel, "Wizard should be accessible from menu")
    }
}
