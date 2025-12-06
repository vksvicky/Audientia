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
        let alert = NSAlert()
        alert.messageText = "Missing Required Dependencies"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Installation Instructions")
        alert.addButton(withTitle: "OK")
        
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
                let script = """
                tell application "Terminal"
                    activate
                    do script "echo 'Installing dependencies...' && brew install ffmpeg chromaprint"
                end tell
                """
                if let appleScript = NSAppleScript(source: script) {
                    appleScript.executeAndReturnError(nil)
                }
            }
        }
    }
}
