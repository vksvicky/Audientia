//
//  SetupWizardStep.swift
//  Shared
//
//  Setup wizard step enumeration
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

/// Steps in the setup wizard
public enum SetupWizardStep: String, CaseIterable, Identifiable {
    case welcome
    case librarySetup
    case preferences
    case support
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .welcome:
            return "Welcome to Audientia"
        case .librarySetup:
            return "Library Setup"
        case .preferences:
            return "Preferences"
        case .support:
            return "Support"
        }
    }
    
    public var stepNumber: Int {
        guard let index = SetupWizardStep.allCases.firstIndex(of: self) else {
            return 0
        }
        return index + 1
    }
    
    public var totalSteps: Int {
        SetupWizardStep.allCases.count
    }
}
