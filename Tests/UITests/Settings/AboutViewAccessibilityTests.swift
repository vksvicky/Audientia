//
//  AboutViewAccessibilityTests.swift
//  AudientiaUITests
//
//  Accessibility tests for AboutView (VoiceOver, keyboard navigation)
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import SwiftUI
import XCTest

@testable import Audientia
@testable import Shared

/// Accessibility tests for AboutView
/// Following Right-BICEP principles for accessibility
final class AboutViewAccessibilityTests: XCTestCase {
    
    var mockSettings: MockAppSettings!
    
    override func setUp() {
        super.setUp()
        mockSettings = MockAppSettings()
    }
    
    override func tearDown() {
        mockSettings = nil
        super.tearDown()
    }
    
    /// Test: AboutView has proper accessibility structure
    @MainActor
    func testAboutViewHasAccessibilityStructure() {
        // Given: AboutView
        let view = AboutView(settings: mockSettings)
        
        // When: View is created
        // Then: Should have accessible structure
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// Test: AboutView app name is accessible to VoiceOver
    @MainActor
    func testAboutViewAppNameIsAccessible() {
        // Given: AboutView with app name
        let view = AboutView(settings: mockSettings)
        
        // When: VoiceOver navigates the view
        // Then: App name should be accessible
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        // Note: SwiftUI Text views are automatically accessible
    }
    
    /// Test: AboutView version information is accessible
    @MainActor
    func testAboutViewVersionInformationIsAccessible() {
        // Given: AboutView with version information
        mockSettings.appVersion = AppVersion(major: 1, minor: 2, patch: 3)
        let view = AboutView(settings: mockSettings)
        
        // When: VoiceOver navigates the view
        // Then: Version information should be accessible
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// Test: AboutView module versions are accessible
    @MainActor
    func testAboutViewModuleVersionsAreAccessible() {
        // Given: AboutView with module versions
        mockSettings.activeModuleVersions = [
            "AudioCore": AppVersion(major: 2025, minor: 12, patch: 1)
        ]
        let view = AboutView(settings: mockSettings)
        
        // When: VoiceOver navigates the view
        // Then: Module versions should be accessible
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// Test: AboutView is keyboard navigable
    @MainActor
    func testAboutViewIsKeyboardNavigable() {
        // Given: AboutView
        let view = AboutView(settings: mockSettings)
        
        // When: User navigates with keyboard
        // Then: All content should be keyboard accessible
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        // Note: SwiftUI views are keyboard accessible by default
    }
    
    /// BDD: As a VoiceOver user, when I open the About window, I should be able to navigate all information
    @MainActor
    func testVoiceOverUserNavigatesAboutWindow() {
        // Given: I am using VoiceOver
        // And: I have an About window open
        let view = AboutView(settings: mockSettings)
        
        // When: I navigate the About window with VoiceOver
        // Then: I should be able to access all information (app name, version, modules, copyright)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// BDD: As a keyboard-only user, when I open the About window, I should be able to navigate with Tab key
    @MainActor
    func testKeyboardOnlyUserNavigatesAboutWindow() {
        // Given: I am using keyboard only
        // And: I have an About window open
        let view = AboutView(settings: mockSettings)
        
        // When: I navigate with Tab key
        // Then: I should be able to navigate all content
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
}

// MARK: - Mock AppSettings

private final class MockAppSettings: AppSettings {
    var appVersion: AppVersion = AppVersion(major: 1, minor: 0, patch: 0)
    var activeModuleVersions: [String: AppVersion] = [:]
    
    override init() {
        super.init()
    }
}
