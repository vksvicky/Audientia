//
//  MockLayoutConfigurationManager.swift
//  UITests
//
//  Mock implementation of LayoutConfigurationManagerProtocol for testing
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

@testable import Shared

/// Mock implementation of LayoutConfigurationManagerProtocol for testing
actor MockLayoutConfigurationManager: LayoutConfigurationManagerProtocol {
    private var layout: LayoutConfiguration?
    var shouldFail = false
    
    func setLayout(_ layout: LayoutConfiguration) {
        self.layout = layout
    }
    
    func getLayout() -> LayoutConfiguration? {
        layout
    }
    
    func setShouldFail(_ fail: Bool) {
        shouldFail = fail
    }
    
    func saveLayout(_ layout: LayoutConfiguration) async throws {
        if shouldFail {
            throw NSError(domain: "test", code: 1)
        }
        self.layout = layout
    }
    
    func loadLayout() async -> LayoutConfiguration {
        layout ?? LayoutConfiguration.default
    }
    
    func resetToDefault() async throws {
        if shouldFail {
            throw NSError(domain: "test", code: 1)
        }
        layout = LayoutConfiguration.default
    }
}
