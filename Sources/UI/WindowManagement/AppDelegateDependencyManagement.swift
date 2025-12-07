//
//  AppDelegateDependencyManagement.swift
//  Audientia
//
//  Dependency checking extension for AppDelegate
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import Foundation
import Shared

extension AppDelegate {
    func checkDependenciesOnFirstLaunch() {
        let hasChecked = UserDefaults.standard.bool(forKey: hasCheckedDependenciesKey)
        
        // Only check on first launch
        guard !hasChecked else { return }
        
        UserDefaults.standard.set(true, forKey: hasCheckedDependenciesKey)
        
        Task {
            let dependencies = await dependencyChecker.checkAllDependencies()
            let missingRequired = dependencies.filter { dep in
                dep.isRequired && {
                    switch dep.status {
                    case .missing, .outdated:
                        return true
                    case .available:
                        return false
                    }
                }()
            }
            
            if !missingRequired.isEmpty {
                let message = await dependencyChecker.formatStatusMessage(dependencies)
                await MainActor.run {
                    showDependencyAlert(message: message, missingRequired: missingRequired)
                }
            }
        }
    }
    
    @MainActor
    private func showDependencyAlert(message: String, missingRequired: [DependencyInfo]) {
        let localisation = LocalisationManager.shared
        let alert = NSAlert()
        alert.messageText = localisation[LocalisationManager.missingRequiredDependencies]
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: localisation[LocalisationManager.openInstallationInstructions])
        alert.addButton(withTitle: localisation[LocalisationManager.apply])
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            // Open installation instructions
            if let instructionsURL = Bundle.main.url(
                forResource: "INSTALL_INSTRUCTIONS",
                withExtension: "md"
            ) {
                NSWorkspace.shared.open(instructionsURL)
            } else {
                // Fallback: open Terminal with installation commands
                let installMsg = localisation[LocalisationManager.installingDependencies]
                let script = """
                tell application "Terminal"
                    activate
                    do script "echo '\(installMsg)' && brew install ffmpeg chromaprint"
                end tell
                """
                if let appleScript = NSAppleScript(source: script) {
                    appleScript.executeAndReturnError(nil)
                }
            }
        }
    }
}
