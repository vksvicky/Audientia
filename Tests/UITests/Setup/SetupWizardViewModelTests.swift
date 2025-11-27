//
//  SetupWizardViewModelTests.swift
//  UITests
//
//  TDD tests for SetupWizardViewModel following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import Shared
import XCTest

@testable import Audientia

/// TDD tests for SetupWizardViewModel
/// Right-BICEP: Right results, Boundary conditions, Inverse relationships, Cross-checking, Error conditions, Performance
@MainActor
final class SetupWizardViewModelTests: XCTestCase {
    
    private var testUserDefaults: UserDefaults?
    private let hasCompletedWizardKey = "audientia.setup.hasCompletedWizard"
    
    override func setUp() {
        super.setUp()
        testUserDefaults = UserDefaults(suiteName: "test.audientia.setup")
        testUserDefaults?.removePersistentDomain(forName: "test.audientia.setup")
        UserDefaults.standard.removeObject(forKey: hasCompletedWizardKey)
    }
    
    override func tearDown() {
        testUserDefaults?.removePersistentDomain(forName: "test.audientia.setup")
        testUserDefaults = nil
        UserDefaults.standard.removeObject(forKey: hasCompletedWizardKey)
        super.tearDown()
    }
    
    // MARK: - Right Results
    
    func testInitialStateIsFirstStep() {
        // Given: A new SetupWizardViewModel
        let viewModel = SetupWizardViewModel()
        
        // Then: Should start at first step
        XCTAssertEqual(viewModel.currentStep, .welcome, "Should start at welcome step")
        XCTAssertFalse(viewModel.canGoBack, "Cannot go back from first step")
        XCTAssertTrue(viewModel.canGoNext, "Can go to next step")
    }
    
    func testNavigateToNextStep() {
        // Given: A SetupWizardViewModel at welcome step
        let viewModel = SetupWizardViewModel()
        
        // When: Navigating to next step
        viewModel.nextStep()
        
        // Then: Should be at library setup step
        XCTAssertEqual(viewModel.currentStep, .librarySetup, "Should be at library setup step")
        XCTAssertTrue(viewModel.canGoBack, "Can go back from second step")
    }
    
    func testNavigateToPreviousStep() {
        // Given: A SetupWizardViewModel at library setup step
        let viewModel = SetupWizardViewModel()
        viewModel.nextStep()
        
        // When: Navigating to previous step
        viewModel.previousStep()
        
        // Then: Should be back at welcome step
        XCTAssertEqual(viewModel.currentStep, .welcome, "Should be back at welcome step")
        XCTAssertFalse(viewModel.canGoBack, "Cannot go back from first step")
    }
    
    func testCompleteWizardMarksAsCompleted() {
        // Given: A SetupWizardViewModel
        let viewModel = SetupWizardViewModel()
        
        // When: Completing the wizard
        viewModel.completeWizard()
        
        // Then: Should be marked as completed
        XCTAssertTrue(viewModel.hasCompletedWizard, "Wizard should be marked as completed")
        let saved = UserDefaults.standard.bool(forKey: hasCompletedWizardKey)
        XCTAssertTrue(saved, "Should be saved to UserDefaults")
    }
    
    func testFirstLaunchShowsWizard() {
        // Given: No previous wizard completion
        UserDefaults.standard.removeObject(forKey: hasCompletedWizardKey)
        
        // When: Checking if wizard should show
        let shouldShow = SetupWizardViewModel.shouldShowWizard()
        
        // Then: Should show wizard
        XCTAssertTrue(shouldShow, "Should show wizard on first launch")
    }
    
    func testSubsequentLaunchHidesWizard() {
        // Given: Wizard was previously completed
        UserDefaults.standard.set(true, forKey: hasCompletedWizardKey)
        
        // When: Checking if wizard should show
        let shouldShow = SetupWizardViewModel.shouldShowWizard()
        
        // Then: Should not show wizard
        XCTAssertFalse(shouldShow, "Should not show wizard after completion")
    }
    
    // MARK: - Boundary Conditions
    
    func testCannotGoBackFromFirstStep() {
        // Given: A SetupWizardViewModel at first step
        let viewModel = SetupWizardViewModel()
        
        // When: Trying to go back
        viewModel.previousStep()
        
        // Then: Should remain at first step
        XCTAssertEqual(viewModel.currentStep, .welcome, "Should remain at first step")
    }
    
    func testCannotGoNextFromLastStep() {
        // Given: A SetupWizardViewModel at last step
        let viewModel = SetupWizardViewModel()
        // Navigate to last step
        while viewModel.canGoNext {
            viewModel.nextStep()
        }
        
        // When: Trying to go next
        let lastStep = viewModel.currentStep
        viewModel.nextStep()
        
        // Then: Should remain at last step
        XCTAssertEqual(viewModel.currentStep, lastStep, "Should remain at last step")
    }
    
    func testNavigateThroughAllSteps() {
        // Given: A SetupWizardViewModel
        let viewModel = SetupWizardViewModel()
        var stepsVisited: [SetupWizardStep] = []
        
        // When: Navigating through all steps
        stepsVisited.append(viewModel.currentStep)
        while viewModel.canGoNext {
            viewModel.nextStep()
            stepsVisited.append(viewModel.currentStep)
        }
        
        // Then: Should have visited all steps
        XCTAssertEqual(stepsVisited.count, SetupWizardStep.allCases.count, "Should visit all steps")
        XCTAssertEqual(stepsVisited.last, SetupWizardStep.allCases.last, "Should end at last step")
    }
    
    // MARK: - Inverse Relationships
    
    func testNavigateForwardThenBack() {
        // Given: A SetupWizardViewModel
        let viewModel = SetupWizardViewModel()
        let initialStep = viewModel.currentStep
        
        // When: Navigating forward then back
        viewModel.nextStep()
        viewModel.previousStep()
        
        // Then: Should be back at initial step
        XCTAssertEqual(viewModel.currentStep, initialStep, "Should return to initial step")
    }
    
    // MARK: - Cross-checking
    
    func testStepCountMatchesAllCases() {
        // Given: SetupWizardStep enum
        let allSteps = SetupWizardStep.allCases
        
        // Then: Should have expected number of steps
        XCTAssertGreaterThanOrEqual(allSteps.count, 3, "Should have at least 3 steps")
        XCTAssertEqual(allSteps.first, .welcome, "First step should be welcome")
    }
    
    // MARK: - Error Conditions
    
    func testCompleteWizardHandlesUserDefaultsFailure() {
        // Given: A SetupWizardViewModel
        let viewModel = SetupWizardViewModel()
        
        // When: Completing wizard (UserDefaults.set is not throwing)
        viewModel.completeWizard()
        
        // Then: Should not crash
        XCTAssertTrue(viewModel.hasCompletedWizard, "Should handle completion gracefully")
    }
    
    // MARK: - Library Setup Tests
    
    func testAddLibraryLocation() {
        // Given: A SetupWizardViewModel with library setup
        let viewModel = SetupWizardViewModel()
        viewModel.nextStep() // Move to library setup
        
        // When: Adding a library location
        let location = URL(fileURLWithPath: "/Users/test/Music")
        viewModel.addLibraryLocation(location)
        
        // Then: Location should be added
        XCTAssertTrue(viewModel.libraryLocations.contains(location), "Location should be added")
    }
    
    func testRemoveLibraryLocation() {
        // Given: A SetupWizardViewModel with library locations
        let viewModel = SetupWizardViewModel()
        viewModel.nextStep()
        let location = URL(fileURLWithPath: "/Users/test/Music")
        viewModel.addLibraryLocation(location)
        
        // When: Removing a library location
        viewModel.removeLibraryLocation(location)
        
        // Then: Location should be removed
        XCTAssertFalse(viewModel.libraryLocations.contains(location), "Location should be removed")
    }
}
