//
//  VersionManager.swift
//  Audientia
//
//  Version management for app (not modules - use ModuleVersionManager for modules)
//

import Foundation

/// Version format: yyyy.mm.bbbb (year.month.build)
public struct Version: Codable, Equatable, Comparable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let build: Int

    public init(year: Int, month: Int, build: Int) {
        self.year = year
        self.month = month
        self.build = build
    }

    /// Initialize from string format "yyyy.mm.bbbb"
    public init?(from string: String) {
        let components = string.split(separator: ".").compactMap { Int($0) }
        guard components.count == 3,
              components[0] >= 2000 && components[0] <= 2100, // year validation
              components[1] >= 1 && components[1] <= 12,     // month validation
              components[2] >= 0                               // build validation
        else {
            return nil
        }
        self.year = components[0]
        self.month = components[1]
        self.build = components[2]
    }

    /// String representation: "yyyy.mm.bbbb"
    public var description: String {
        String(format: "%04d.%02d.%04d", year, month, build)
    }

    /// Version string for display
    public var displayString: String {
        description
    }
}

/// Manages app version (not module versions - use ModuleVersionManager)
public class VersionManager {
    public static let shared = VersionManager()

    private let appVersionKey = "AppVersion"

    private init() {}

    /// Get current app version
    public var appVersion: Version {
        if let versionString = UserDefaults.standard.string(forKey: appVersionKey),
           let version = Version(from: versionString) {
            return version
        }
        // Default to current date if not set
        return generateCurrentVersion()
    }

    /// Set app version
    public func setAppVersion(_ version: Version) {
        UserDefaults.standard.set(version.description, forKey: appVersionKey)
        UserDefaults.standard.synchronize()
    }

    /// Generate version from current date
    public func generateCurrentVersion() -> Version {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let build = generateBuildNumber(for: year, month: month)
        return Version(year: year, month: month, build: build)
    }

    /// Generate build number for a given year/month
    private func generateBuildNumber(for year: Int, month: Int) -> Int {
        let key = "\(year).\(month).build"
        let currentBuild = UserDefaults.standard.integer(forKey: key)
        let newBuild = currentBuild + 1
        UserDefaults.standard.set(newBuild, forKey: key)
        UserDefaults.standard.synchronize()
        return newBuild
    }

    /// Reset build number for a year/month (useful for testing)
    public func resetBuildNumber(for year: Int, month: Int) {
        let key = "\(year).\(month).build"
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.synchronize()
    }
}

// MARK: - Version Comparison

extension Version {
    public static func < (lhs: Version, rhs: Version) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }
        if lhs.month != rhs.month {
            return lhs.month < rhs.month
        }
        return lhs.build < rhs.build
    }
}
