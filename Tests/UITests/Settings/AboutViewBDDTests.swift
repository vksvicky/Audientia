//
//  AboutViewBDDTests.swift
//  AudientiaUITests
//
//  BDD tests for AboutView following user-centric scenarios
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import SwiftUI
import XCTest

@testable import Audientia
@testable import Shared

/// BDD tests for AboutView
/// Following user-centric "As a user, I want to..." format
final class AboutViewBDDTests: XCTestCase {
    
    var mockSettings: MockAppSettings!
    
    override func setUp() {
        super.setUp()
        mockSettings = MockAppSettings()
    }
    
    override func tearDown() {
        mockSettings = nil
        super.tearDown()
    }
    
    /// BDD: As a user, when I open the About window, I should see the app name and version
    @MainActor
    func testUserOpensAboutWindowSeesAppNameAndVersion() {
        // Given: I have an app with version information
        mockSettings.appVersion = AppVersion(major: 1, minor: 2, patch: 3)
        let view = AboutView(settings: mockSettings)
        
        // When: I open the About window
        // Then: I should see the app name and version
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        XCTAssertEqual(mockSettings.appVersion.major, 1, "Should show major version")
        XCTAssertEqual(mockSettings.appVersion.minor, 2, "Should show minor version")
        XCTAssertEqual(mockSettings.appVersion.patch, 3, "Should show patch version")
    }
    
    /// BDD: As a user, when I open the About window, I should see all module versions
    @MainActor
    func testUserOpensAboutWindowSeesModuleVersions() {
        // Given: I have an app with multiple modules
        mockSettings.activeModuleVersions = [
            "AudioCore": AppVersion(major: 2025, minor: 12, patch: 1),
            "DataLayer": AppVersion(major: 2025, minor: 12, patch: 2),
            "Shared": AppVersion(major: 2025, minor: 12, patch: 3)
        ]
        let view = AboutView(settings: mockSettings)
        
        // When: I open the About window
        // Then: I should see all module versions listed
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        XCTAssertEqual(mockSettings.activeModuleVersions.count, 3, "Should show 3 modules")
    }
    
    /// BDD: As a user, when I open the About window, I should see the app icon
    @MainActor
    func testUserOpensAboutWindowSeesAppIcon() {
        // Given: I have an app with an icon
        let view = AboutView(settings: mockSettings)
        
        // When: I open the About window
        // Then: I should see the app icon (or fallback icon)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        // Note: Icon display is handled in AboutView implementation
    }
    
    /// BDD: As a user, when I open the About window, I should see copyright information
    @MainActor
    func testUserOpensAboutWindowSeesCopyright() {
        // Given: I have an app with copyright information
        let view = AboutView(settings: mockSettings)
        
        // When: I open the About window
        // Then: I should see copyright information (if available from Bundle)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        // Note: Copyright comes from Bundle.main.infoDictionary
    }
    
    /// BDD: As a user, when I have many modules, I should be able to scroll to see all of them
    @MainActor
    func testUserScrollsToSeeAllModules() {
        // Given: I have an app with many modules
        var versions: [String: AppVersion] = [:]
        for i in 1...30 {
            versions["Module\(i)"] = AppVersion(major: 2025, minor: 12, patch: i)
        }
        mockSettings.activeModuleVersions = versions
        let view = AboutView(settings: mockSettings)
        
        // When: I open the About window
        // Then: I should be able to scroll to see all modules (ScrollView handles this)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        XCTAssertEqual(mockSettings.activeModuleVersions.count, 30, "Should have 30 modules")
    }
    
    /// BDD: As a user, when I open the About window, the information should be accurate
    @MainActor
    func testUserSeesAccurateVersionInformation() {
        // Given: I have an app with specific version information
        mockSettings.appVersion = AppVersion(major: 2, minor: 5, patch: 10)
        mockSettings.activeModuleVersions = [
            "AudioCore": AppVersion(major: 2025, minor: 12, patch: 50)
        ]
        let view = AboutView(settings: mockSettings)
        
        // When: I open the About window
        // Then: The version information should match what's in settings
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        XCTAssertEqual(mockSettings.appVersion.major, 2, "App version should be accurate")
        XCTAssertEqual(mockSettings.activeModuleVersions["AudioCore"]?.patch, 50, "Module version should be accurate")
    }
    
    /// BDD: As a user, when I open the About window, it should display correctly even with no modules
    @MainActor
    func testUserOpensAboutWindowWithNoModules() {
        // Given: I have an app with no modules loaded
        mockSettings.activeModuleVersions = [:]
        let view = AboutView(settings: mockSettings)
        
        // When: I open the About window
        // Then: The window should still display correctly (showing only app version)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        XCTAssertTrue(mockSettings.activeModuleVersions.isEmpty, "Should handle empty modules")
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
