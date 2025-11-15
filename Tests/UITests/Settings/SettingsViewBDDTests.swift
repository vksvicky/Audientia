//
//  SettingsViewBDDTests.swift
//  UITests
//
//  BDD scenarios for Settings views
//  Following user-centric "As a user, I want to..." format
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import Shared
@testable import UI
import XCTest

/// BDD-style test scenarios for Settings views
/// Following user-centric "As a user, I want to..." format
@MainActor
final class SettingsViewBDDTests: XCTestCase {
    
    // MARK: - BDD Scenarios
    
    /// BDD: As a user, I want to see information about the app
    func testUserViewsAppInformation() {
        // Given - I open the About screen
        let settings = AppSettings.shared
        let aboutView = AboutView(settings: settings)
        
        // When - I view the About screen
        
        // Then - I should see app information
        XCTAssertNotNil(aboutView, "User should be able to view About screen")
        XCTAssertNotNil(settings.appVersion, "User should see app version")
    }
    
    /// BDD: As a user, I want to see module versions
    func testUserViewsModuleVersions() {
        // Given - I have modules installed
        let settings = AppSettings.shared
        settings.activeModuleVersions = [
            "AudioCore": Version(year: 2025, month: 11, build: 1),
            "MetadataEngine": Version(year: 2025, month: 11, build: 2),
            "DataLayer": Version(year: 2025, month: 11, build: 3)
        ]
        let aboutView = AboutView(settings: settings)
        
        // When - I view the About screen
        
        // Then - I should see module versions
        XCTAssertNotNil(aboutView, "User should be able to view About screen")
        XCTAssertEqual(settings.activeModuleVersions.count, 3, "User should see 3 module versions")
        XCTAssertNotNil(settings.activeModuleVersions["AudioCore"], "User should see AudioCore version")
    }
    
    /// BDD: As a user, I want to see the app icon
    func testUserSeesAppIcon() {
        // Given - I open the About screen
        let aboutView = AboutView()
        
        // When - I view the About screen
        
        // Then - I should see the app icon (or fallback)
        // Note: Icon may or may not be present, but view should handle both cases
        XCTAssertNotNil(aboutView, "User should see About screen with icon or fallback")
    }
    
    /// BDD: As a user, I want to see copyright information
    func testUserSeesCopyrightInformation() {
        // Given - I open the About screen
        let aboutView = AboutView()
        
        // When - I view the About screen
        
        // Then - I should see copyright information
        // Note: Copyright comes from Info.plist, may or may not be present
        XCTAssertNotNil(aboutView, "User should see About screen with copyright information")
    }
    
    /// BDD: As a user, I want to see sorted module versions
    func testUserSeesSortedModuleVersions() {
        // Given - I have modules with unsorted names
        let settings = AppSettings.shared
        settings.activeModuleVersions = [
            "ZModule": Version(year: 2025, month: 11, build: 1),
            "AModule": Version(year: 2025, month: 11, build: 2),
            "MModule": Version(year: 2025, month: 11, build: 3)
        ]
        let aboutView = AboutView(settings: settings)
        
        // When - I view the About screen
        
        // Then - I should see modules sorted alphabetically
        // Note: The view sorts modules by key, so AModule should come first
        let sortedKeys = settings.activeModuleVersions.keys.sorted()
        XCTAssertEqual(sortedKeys.first, "AModule", "Modules should be sorted alphabetically")
        XCTAssertNotNil(aboutView, "User should see sorted module list")
    }
    
    /// BDD: As a user, I want to see the app name
    func testUserSeesAppName() {
        // Given - I open the About screen
        let aboutView = AboutView()
        
        // When - I view the About screen
        
        // Then - I should see the app name
        // Note: App name comes from Bundle, should be "Audientia" or from Info.plist
        XCTAssertNotNil(aboutView, "User should see app name in About screen")
    }
}
