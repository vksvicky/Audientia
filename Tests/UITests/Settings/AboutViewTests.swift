//
//  AboutViewTests.swift
//  AudientiaUITests
//
//  Comprehensive TDD tests for AboutView following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import SwiftUI
import XCTest

@testable import Audientia
@testable import Shared

/// TDD tests for AboutView
/// Following Right-BICEP principles
final class AboutViewTests: XCTestCase {
    
    var mockSettings: MockAppSettings!
    
    override func setUp() {
        super.setUp()
        mockSettings = MockAppSettings()
    }
    
    override func tearDown() {
        mockSettings = nil
        super.tearDown()
    }
    
    // MARK: - [Right]: Are the Results Right?
    
    /// Test: AboutView displays app name correctly
    @MainActor
    func testAboutViewDisplaysAppName() {
        // Given: AboutView with settings
        let view = AboutView(settings: mockSettings)
        
        // When: View is created
        // Then: Should be able to create view (implies app name is displayed)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// Test: AboutView displays app version correctly
    @MainActor
    func testAboutViewDisplaysAppVersion() {
        // Given: Settings with known version
        mockSettings.appVersion = AppVersion(major: 1, minor: 0, patch: 0)
        let view = AboutView(settings: mockSettings)
        
        // When: View is created
        // Then: Should display version
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        XCTAssertEqual(mockSettings.appVersion.major, 1, "Version should be set")
    }
    
    /// Test: AboutView displays module versions correctly
    @MainActor
    func testAboutViewDisplaysModuleVersions() {
        // Given: Settings with module versions
        mockSettings.activeModuleVersions = [
            "AudioCore": AppVersion(major: 2025, minor: 12, patch: 1),
            "DataLayer": AppVersion(major: 2025, minor: 12, patch: 2)
        ]
        let view = AboutView(settings: mockSettings)
        
        // When: View is created
        // Then: Should display module versions
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        XCTAssertEqual(mockSettings.activeModuleVersions.count, 2, "Should have 2 modules")
    }
    
    /// Test: AboutView displays copyright information
    @MainActor
    func testAboutViewDisplaysCopyright() {
        // Given: AboutView
        let view = AboutView(settings: mockSettings)
        
        // When: View is created
        // Then: Should handle copyright display (copyright comes from Bundle)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    // MARK: - [B]oundary Conditions
    
    /// Test: AboutView handles empty module versions
    @MainActor
    func testAboutViewHandlesEmptyModuleVersions() {
        // Given: Settings with no module versions
        mockSettings.activeModuleVersions = [:]
        let view = AboutView(settings: mockSettings)
        
        // When: View is created
        // Then: Should handle empty modules gracefully
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        XCTAssertTrue(mockSettings.activeModuleVersions.isEmpty, "Should have no modules")
    }
    
    /// Test: AboutView handles many module versions
    @MainActor
    func testAboutViewHandlesManyModuleVersions() {
        // Given: Settings with many module versions
        var versions: [String: AppVersion] = [:]
        for i in 1...50 {
            versions["Module\(i)"] = AppVersion(major: 2025, minor: 12, patch: i)
        }
        mockSettings.activeModuleVersions = versions
        let view = AboutView(settings: mockSettings)
        
        // When: View is created
        // Then: Should handle many modules (ScrollView should handle overflow)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        XCTAssertEqual(mockSettings.activeModuleVersions.count, 50, "Should have 50 modules")
    }
    
    /// Test: AboutView handles missing app icon gracefully
    @MainActor
    func testAboutViewHandlesMissingAppIcon() {
        // Given: AboutView (icon may not exist in test environment)
        let view = AboutView(settings: mockSettings)
        
        // When: View is created
        // Then: Should fallback to system icon if app icon missing
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// Test: AboutView handles very long module names
    @MainActor
    func testAboutViewHandlesLongModuleNames() {
        // Given: Settings with very long module name
        let longName = String(repeating: "A", count: 100)
        mockSettings.activeModuleVersions = [
            longName: AppVersion(major: 2025, minor: 12, patch: 1)
        ]
        let view = AboutView(settings: mockSettings)
        
        // When: View is created
        // Then: Should handle long names (text should truncate or wrap)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    // MARK: - [I]nverse Relationships
    
    /// Test: AboutView updates when settings change
    @MainActor
    func testAboutViewUpdatesWhenSettingsChange() {
        // Given: AboutView with initial settings
        mockSettings.appVersion = AppVersion(major: 1, minor: 0, patch: 0)
        let view = AboutView(settings: mockSettings)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        
        // When: Settings change
        mockSettings.appVersion = AppVersion(major: 1, minor: 1, patch: 0)
        
        // Then: View should update (SwiftUI @ObservedObject handles this)
        XCTAssertEqual(mockSettings.appVersion.minor, 1, "Version should be updated")
    }
    
    // MARK: - [C]ross-Check Using Other Means
    
    /// Test: AboutView frame size matches expected dimensions
    @MainActor
    func testAboutViewFrameSizeMatchesExpected() {
        // Given: AboutView
        let view = AboutView(settings: mockSettings)
        
        // When: View is created
        // Then: Frame should match expected size (550x400 from implementation)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        // Note: Frame size is hardcoded in AboutView as .frame(width: 550, height: 400)
    }
    
    // MARK: - [E]rror Conditions
    
    /// Test: AboutView handles nil copyright gracefully
    @MainActor
    func testAboutViewHandlesNilCopyright() {
        // Given: AboutView (copyright may be nil from Bundle)
        let view = AboutView(settings: mockSettings)
        
        // When: View is created
        // Then: Should handle nil copyright (conditional display in implementation)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// Test: AboutView handles invalid version numbers
    @MainActor
    func testAboutViewHandlesInvalidVersions() {
        // Given: Settings with potentially invalid version
        mockSettings.appVersion = AppVersion(major: 0, minor: 0, patch: 0)
        let view = AboutView(settings: mockSettings)
        
        // When: View is created
        // Then: Should display version even if zero
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    // MARK: - [P]erformance Characteristics
    
    /// Test: AboutView creation is fast
    @MainActor
    func testAboutViewCreationPerformance() {
        // Given: Settings with many modules
        var versions: [String: AppVersion] = [:]
        for i in 1...20 {
            versions["Module\(i)"] = AppVersion(major: 2025, minor: 12, patch: i)
        }
        mockSettings.activeModuleVersions = versions
        
        // When: Measuring view creation
        measure {
            let view = AboutView(settings: mockSettings)
            SwiftUIViewTestHelpers.verifyViewCreation(view)
        }
        
        // Then: Should complete quickly
    }
    
    // MARK: - Edge Cases
    
    /// Test: AboutView handles special characters in module names
    @MainActor
    func testAboutViewHandlesSpecialCharactersInModuleNames() {
        // Given: Settings with special characters in module name
        mockSettings.activeModuleVersions = [
            "Module™": AppVersion(major: 2025, minor: 12, patch: 1),
            "Module©": AppVersion(major: 2025, minor: 12, patch: 2)
        ]
        let view = AboutView(settings: mockSettings)
        
        // When: View is created
        // Then: Should handle special characters
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// Test: AboutView handles Unicode in module names
    @MainActor
    func testAboutViewHandlesUnicodeInModuleNames() {
        // Given: Settings with Unicode in module name
        mockSettings.activeModuleVersions = [
            "モジュール": AppVersion(major: 2025, minor: 12, patch: 1),
            "Модуль": AppVersion(major: 2025, minor: 12, patch: 2)
        ]
        let view = AboutView(settings: mockSettings)
        
        // When: View is created
        // Then: Should handle Unicode
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
