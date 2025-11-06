//
//  ModuleVersionManager.swift
//  Audientia
//
//  Manages multiple versions of modules and automatically selects latest
//

import Foundation

/// Represents a module with its version and file path
public struct ModuleInfo: Codable, Equatable {
    public let moduleName: String
    public let version: Version
    public let filePath: String
    public let buildDate: Date

    public init(moduleName: String, version: Version, filePath: String, buildDate: Date = Date()) {
        self.moduleName = moduleName
        self.version = version
        self.filePath = filePath
        self.buildDate = buildDate
    }
}

/// Manages multiple versions of modules
public class ModuleVersionManager {
    public static let shared = ModuleVersionManager()

    private let moduleVersionsKey = "ModuleVersions"
    private let fileManager = FileManager.default

    private init() {}

    /// Get all versions of a module
    public func getAllVersions(for moduleName: String) -> [ModuleInfo] {
        let allModules = loadAllModules()
        return allModules.filter { $0.moduleName == moduleName }
            .sorted(by: { $0.version > $1.version }) // Latest first
    }

    /// Get latest version of a module
    public func getLatestVersion(for moduleName: String) -> ModuleInfo? {
        return getAllVersions(for: moduleName).first
    }

    /// Register a new module version
    public func registerModule(_ moduleInfo: ModuleInfo) throws {
        var allModules = loadAllModules()

        // Check if this version already exists
        if allModules.contains(where: { $0.moduleName == moduleInfo.moduleName && $0.version == moduleInfo.version }) {
            // Version already registered, update file path if different
            if let index = allModules.firstIndex(where: { $0.moduleName == moduleInfo.moduleName && $0.version == moduleInfo.version }) {
                allModules[index] = moduleInfo
            }
        } else {
            // Add new version
            allModules.append(moduleInfo)
        }

        // Save updated list
        saveAllModules(allModules)

        // Check for conflicts and clean up old versions
        try handleModuleConflicts(for: moduleInfo.moduleName)
    }

    /// Handle conflicts when multiple versions exist
    private func handleModuleConflicts(for moduleName: String) throws {
        let allVersions = getAllVersions(for: moduleName)

        guard allVersions.count > 1 else {
            return // No conflicts, only one version
        }

        let latest = allVersions[0]
        let olderVersions = Array(allVersions[1...])

        // Log warning about conflicts
        print("⚠️ WARNING: Multiple versions of \(moduleName) detected:")
        print("   Latest: \(latest.version) at \(latest.filePath)")
        for oldVersion in olderVersions {
            print("   Older: \(oldVersion.version) at \(oldVersion.filePath)")
        }
        print("   Removing older versions and keeping: \(latest.version)")

        // Delete older version files
        for oldVersion in olderVersions {
            try deleteModuleFiles(for: oldVersion)
        }

        // Remove older versions from registry
        var allModules = loadAllModules()
        allModules.removeAll { module in
            module.moduleName == moduleName && module.version != latest.version
        }
        saveAllModules(allModules)

        // Post notification for UI to display warning
        NotificationCenter.default.post(
            name: .moduleVersionConflict,
            object: nil,
            userInfo: [
                "moduleName": moduleName,
                "latestVersion": latest.version.description,
                "removedVersions": olderVersions.map { $0.version.description }
            ]
        )
    }

    /// Delete files for a module version
    private func deleteModuleFiles(for moduleInfo: ModuleInfo) throws {
        let filePath = moduleInfo.filePath

        // Check if file exists
        guard fileManager.fileExists(atPath: filePath) else {
            print("   File not found: \(filePath), skipping deletion")
            return
        }

        // Delete the file
        try fileManager.removeItem(atPath: filePath)
        print("   ✓ Deleted: \(filePath)")

        // Also try to delete associated files (e.g., .dSYM, headers, etc.)
        let basePath = (filePath as NSString).deletingLastPathComponent
        let fileName = (filePath as NSString).lastPathComponent
        let fileNameWithoutExt = (fileName as NSString).deletingPathExtension

        // Delete .dSYM if exists
        let dSYMPath = "\(basePath)/\(fileNameWithoutExt).dSYM"
        if fileManager.fileExists(atPath: dSYMPath) {
            try? fileManager.removeItem(atPath: dSYMPath)
        }

        // Delete headers if exists (for frameworks)
        let headersPath = "\(basePath)/\(fileNameWithoutExt).framework/Headers"
        if fileManager.fileExists(atPath: headersPath) {
            try? fileManager.removeItem(atPath: headersPath)
        }
    }

    /// Load all registered modules
    private func loadAllModules() -> [ModuleInfo] {
        guard let data = UserDefaults.standard.data(forKey: moduleVersionsKey),
              let modules = try? JSONDecoder().decode([ModuleInfo].self, from: data) else {
            return []
        }
        return modules
    }

    /// Save all registered modules
    private func saveAllModules(_ modules: [ModuleInfo]) {
        if let data = try? JSONEncoder().encode(modules) {
            UserDefaults.standard.set(data, forKey: moduleVersionsKey)
            UserDefaults.standard.synchronize()
        }
    }

    /// Get current active version for a module (latest)
    public func getActiveVersion(for moduleName: String) -> Version? {
        return getLatestVersion(for: moduleName)?.version
    }

    /// Get all active module versions (latest for each)
    public func getAllActiveVersions() -> [String: Version] {
        let allModules = loadAllModules()
        var activeVersions: [String: Version] = [:]

        // Group by module name and get latest for each
        let grouped = Dictionary(grouping: allModules) { $0.moduleName }
        for (name, modules) in grouped {
            if let latest = modules.max(by: { $0.version < $1.version }) {
                activeVersions[name] = latest.version
            }
        }

        return activeVersions
    }

    /// Scan directory for module files and register them
    public func scanAndRegisterModules(in directory: String) throws {
        let directoryURL = URL(fileURLWithPath: directory)
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.creationDateKey, .nameKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw NSError(domain: "ModuleVersionManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to enumerate directory"])
        }

        for case let fileURL as URL in enumerator {
            // Check if it's a module file (framework, bundle, or library)
            let pathExtension = fileURL.pathExtension
            if pathExtension == "framework" || pathExtension == "bundle" || pathExtension == "dylib" {
                // Try to extract module name and version from filename
                // Format: ModuleName-Version.framework or ModuleName.framework
                let fileName = fileURL.lastPathComponent
                if let moduleInfo = parseModuleInfo(from: fileName, filePath: fileURL.path) {
                    try registerModule(moduleInfo)
                }
            }
        }
    }

    /// Parse module info from filename
    private func parseModuleInfo(from fileName: String, filePath: String) -> ModuleInfo? {
        // Expected formats:
        // - ModuleName-Version.framework
        // - ModuleName-Version.bundle
        // - ModuleName-Version.dylib

        let nameWithoutExt = (fileName as NSString).deletingPathExtension

        // Try to split on last dash to separate name and version
        if let lastDashIndex = nameWithoutExt.lastIndex(of: "-") {
            let moduleName = String(nameWithoutExt[..<lastDashIndex])
            let versionString = String(nameWithoutExt[nameWithoutExt.index(after: lastDashIndex)...])

            if let version = Version(from: versionString) {
                return ModuleInfo(
                    moduleName: moduleName,
                    version: version,
                    filePath: filePath
                )
            }
        }

        // If no version in filename, try to get from file metadata or use current
        let moduleName = nameWithoutExt
        let version = VersionManager.shared.generateCurrentVersion()
        return ModuleInfo(
            moduleName: moduleName,
            version: version,
            filePath: filePath
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    public static let moduleVersionConflict = Notification.Name("moduleVersionConflict")
}
