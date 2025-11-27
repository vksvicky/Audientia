//
//  AppSettings.swift
//  Audientia
//
//  Application settings and preferences
//

import Combine
import Foundation

/// Application settings model
public class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    // MARK: - Version Information

    @Published public var appVersion: Version {
        didSet {
            VersionManager.shared.setAppVersion(appVersion)
        }
    }

    @Published public var activeModuleVersions: [String: Version] {
        didSet {
            // Versions are managed by ModuleVersionManager
        }
    }

    @Published public var moduleConflictWarnings: [String: ModuleConflictWarning] = [:]
    
    // MARK: - UI Preferences
    
    @Published public var showSplashScreen: Bool {
        didSet {
            UserDefaults.standard.set(showSplashScreen, forKey: "audientia.settings.showSplashScreen")
        }
    }

    // MARK: - Initialization

    private init() {
        self.appVersion = VersionManager.shared.appVersion
        self.activeModuleVersions = ModuleVersionManager.shared.getAllActiveVersions()
        
        // Load splash screen preference (default: true)
        let splashScreenKey = "audientia.settings.showSplashScreen"
        self.showSplashScreen = UserDefaults.standard.object(forKey: splashScreenKey) as? Bool ?? true

        // Listen for module conflict notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleModuleConflict(_:)),
            name: .moduleVersionConflict,
            object: nil
        )

        // Load module versions on init
        loadModuleVersions()
    }

    // MARK: - Version Management

    /// Load all active module versions from ModuleVersionManager
    public func loadModuleVersions() {
        activeModuleVersions = ModuleVersionManager.shared.getAllActiveVersions()
    }

    /// Get version string for a specific module (latest/active version)
    public func versionString(for moduleName: String) -> String {
        if let version = activeModuleVersions[moduleName] {
            return version.description
        }
        return "Unknown"
    }

    /// Get full version string with module name
    public func fullVersionString(for moduleName: String) -> String {
        if let version = activeModuleVersions[moduleName] {
            return "\(moduleName)-\(version)"
        }
        return "\(moduleName)-Unknown"
    }

    /// Update app version
    public func updateAppVersion(_ version: Version) {
        appVersion = version
    }

    /// Get all versions as formatted string for display
    public var allVersionsDisplayString: String {
        var lines: [String] = []
        lines.append("App: \(appVersion.description)")
        for (moduleName, version) in activeModuleVersions.sorted(by: { $0.key < $1.key }) {
            lines.append("\(moduleName): \(version.description)")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Conflict Handling

    @objc private func handleModuleConflict(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let moduleName = userInfo["moduleName"] as? String,
              let latestVersion = userInfo["latestVersion"] as? String,
              let removedVersions = userInfo["removedVersions"] as? [String] else {
            return
        }

        let warning = ModuleConflictWarning(
            moduleName: moduleName,
            latestVersion: latestVersion,
            removedVersions: removedVersions,
            timestamp: Date()
        )

        moduleConflictWarnings[moduleName] = warning

        // Reload module versions after conflict resolution
        loadModuleVersions()
    }

    /// Clear conflict warning for a module
    public func clearConflictWarning(for moduleName: String) {
        moduleConflictWarnings.removeValue(forKey: moduleName)
    }
}

/// Represents a module version conflict warning
public struct ModuleConflictWarning: Codable, Identifiable {
    public let id: UUID
    public let moduleName: String
    public let latestVersion: String
    public let removedVersions: [String]
    public let timestamp: Date

    public init(moduleName: String, latestVersion: String, removedVersions: [String], timestamp: Date) {
        self.id = UUID()
        self.moduleName = moduleName
        self.latestVersion = latestVersion
        self.removedVersions = removedVersions
        self.timestamp = timestamp
    }

    // Exclude id from Codable since it's generated
    private enum CodingKeys: String, CodingKey {
        case moduleName, latestVersion, removedVersions, timestamp
    }

    // Custom decoder to generate id on decode
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.moduleName = try container.decode(String.self, forKey: .moduleName)
        self.latestVersion = try container.decode(String.self, forKey: .latestVersion)
        self.removedVersions = try container.decode([String].self, forKey: .removedVersions)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
    }

    public var message: String {
        let removed = removedVersions.joined(separator: ", ")
        return "Multiple versions of \(moduleName) detected. Kept \(latestVersion), removed: \(removed)"
    }
}
