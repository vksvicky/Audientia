//
//  AutoVersionUpdate.swift
//  Audientia
//
//  Auto-updates app version from build files
//  Module versions are handled by ModuleVersionManager
//

import Foundation

/// Auto-updates app version from build files
public func updateAppVersionFromBuild() {
    let versionManager = VersionManager.shared
    let fileManager = FileManager.default

    // Helper to read version from file
    func readVersion(from file: String) -> Version? {
        guard let versionString = try? String(contentsOfFile: file, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines),
              let version = Version(from: versionString) else {
            return nil
        }
        return version
    }

    // First, try to read from Info.plist (most reliable - comes from project.yml)
    if let infoDict = Bundle.main.infoDictionary,
       let versionString = infoDict["CFBundleShortVersionString"] as? String,
       let version = Version(from: versionString) {
        versionManager.setAppVersion(version)
        return
    }

    // Try to find version file in common locations
    let possiblePaths = [
        Bundle.main.bundlePath + "/Contents/.app_version",  // App bundle (most reliable)
        Bundle.main.bundlePath + "/../.app_version",  // Build directory
        (Bundle.main.bundlePath as NSString).deletingLastPathComponent + "/.app_version"  // Parent directory
    ]

    var versionFound = false
    for path in possiblePaths {
        if fileManager.fileExists(atPath: path), let version = readVersion(from: path) {
            versionManager.setAppVersion(version)
            versionFound = true
            break
        }
    }

    if !versionFound {
        // Fallback to generating current version
        let currentVersion = versionManager.generateCurrentVersion()
        versionManager.setAppVersion(currentVersion)
    }
}

/// Scan and register all modules from build directory
public func scanAndRegisterModules() {
    let moduleManager = ModuleVersionManager.shared
    let fileManager = FileManager.default

    // Common module locations
    let possiblePaths = [
        Bundle.main.bundlePath + "/Contents/Frameworks",
        Bundle.main.bundlePath + "/../Frameworks",
        Bundle.main.bundlePath + "/Modules"
    ]

    for path in possiblePaths where fileManager.fileExists(atPath: path) {
        do {
            try moduleManager.scanAndRegisterModules(in: path)
        } catch {
            print("Failed to scan modules in \(path): \(error)")
        }
    }
}
