//
//  DependencyChecker.swift
//  Shared
//
//  Utility to check for required external dependencies
//

import Foundation
import os.log

/// Status of a dependency check
public enum DependencyStatus {
    case available(version: String?)
    case missing
    case outdated(currentVersion: String, minimumVersion: String)
}

/// Information about a dependency
public struct DependencyInfo {
    public let name: String
    public let displayName: String
    public let status: DependencyStatus
    public let isRequired: Bool
    public let installationCommand: String
    public let minimumVersion: String?
    
    public init(
        name: String,
        displayName: String,
        status: DependencyStatus,
        isRequired: Bool,
        installationCommand: String,
        minimumVersion: String? = nil
    ) {
        self.name = name
        self.displayName = displayName
        self.status = status
        self.isRequired = isRequired
        self.installationCommand = installationCommand
        self.minimumVersion = minimumVersion
    }
}

/// Utility to check for required external dependencies
public actor DependencyChecker {
    private let logger = Logger(subsystem: "club.cycleruncode.audientia", category: "DependencyChecker")
    
    public init() {}
    
    /// Check all dependencies
    public func checkAllDependencies() async -> [DependencyInfo] {
        var dependencies: [DependencyInfo] = []
        
        // Check FFmpeg (required)
        let ffmpegStatus = await checkFFmpeg()
        dependencies.append(DependencyInfo(
            name: "ffmpeg",
            displayName: "FFmpeg",
            status: ffmpegStatus,
            isRequired: true,
            installationCommand: "brew install ffmpeg",
            minimumVersion: "6.0"
        ))
        
        // Check chromaprint (optional but recommended)
        let chromaprintStatus = await checkChromaprint()
        dependencies.append(DependencyInfo(
            name: "fpcalc",
            displayName: "chromaprint",
            status: chromaprintStatus,
            isRequired: false,
            installationCommand: "brew install chromaprint"
        ))
        
        return dependencies
    }
    
    /// Check if FFmpeg is available
    public func checkFFmpeg() async -> DependencyStatus {
        // Check common paths
        let possiblePaths = [
            "/usr/local/bin/ffmpeg",
            "/opt/homebrew/bin/ffmpeg",
            "/usr/bin/ffmpeg"
        ]
        
        // First check if in PATH
        if let path = await findExecutableInPath("ffmpeg") {
            return await getFFmpegVersion(path: path)
        }
        
        // Check common paths
        for path in possiblePaths where FileManager.default.fileExists(atPath: path) {
            return await getFFmpegVersion(path: path)
        }
        
        return .missing
    }
    
    /// Check if chromaprint (fpcalc) is available
    public func checkChromaprint() async -> DependencyStatus {
        // Check common paths
        let possiblePaths = [
            "/usr/local/bin/fpcalc",
            "/opt/homebrew/bin/fpcalc",
            "/usr/bin/fpcalc"
        ]
        
        // First check if in PATH
        if let path = await findExecutableInPath("fpcalc") {
            return await getChromaprintVersion(path: path)
        }
        
        // Check common paths
        for path in possiblePaths where FileManager.default.fileExists(atPath: path) {
            return await getChromaprintVersion(path: path)
        }
        
        return .missing
    }
    
    /// Find executable in PATH
    private func findExecutableInPath(_ name: String) async -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [name]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8),
                   !output.trimmingCharacters(in: .whitespaces).isEmpty {
                    return output.trimmingCharacters(in: .whitespaces)
                }
            }
        } catch {
            logger.debug("Failed to find \(name) in PATH: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Get FFmpeg version
    private func getFFmpegVersion(path: String) async -> DependencyStatus {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["-version"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    // Extract version (e.g., "ffmpeg version 6.0.1")
                    let lines = output.components(separatedBy: .newlines)
                    for line in lines where line.contains("ffmpeg version") {
                        let versionMatch = line.range(of: #"\d+\.\d+"#, options: .regularExpression)
                        if let match = versionMatch {
                            let version = String(line[match])
                            // Check minimum version
                            if let minVersion = parseVersion("6.0"),
                               let currentVersion = parseVersion(version),
                               currentVersion < minVersion {
                                return .outdated(currentVersion: version, minimumVersion: "6.0")
                            }
                            return .available(version: version)
                        }
                    }
                    return .available(version: nil)
                }
            }
        } catch {
            logger.debug("Failed to get FFmpeg version: \(error.localizedDescription)")
        }
        
        return .missing
    }
    
    /// Get chromaprint version
    private func getChromaprintVersion(path: String) async -> DependencyStatus {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["-version"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    // Extract version (e.g., "fpcalc version 1.5.1")
                    let lines = output.components(separatedBy: .newlines)
                    for line in lines where line.contains("version") {
                        let versionMatch = line.range(of: #"\d+\.\d+\.\d+"#, options: .regularExpression)
                        if let match = versionMatch {
                            let version = String(line[match])
                            return .available(version: version)
                        }
                    }
                    return .available(version: nil)
                }
            }
        } catch {
            logger.debug("Failed to get chromaprint version: \(error.localizedDescription)")
        }
        
        return .missing
    }
    
    /// Parse version string to comparable format
    private func parseVersion(_ version: String) -> (major: Int, minor: Int)? {
        let components = version.split(separator: ".")
        guard components.count >= 2,
              let major = Int(components[0]),
              let minor = Int(components[1]) else {
            return nil
        }
        return (major: major, minor: minor)
    }
    
    /// Format dependency status message for user notification
    public func formatStatusMessage(_ dependencies: [DependencyInfo]) -> String {
        var messages: [String] = []
        var hasMissing = false
        
        for dep in dependencies {
            switch dep.status {
            case .available(let version):
                if let version = version {
                    messages.append("✅ \(dep.displayName) \(version)")
                } else {
                    messages.append("✅ \(dep.displayName)")
                }
            case .missing:
                hasMissing = true
                let required = dep.isRequired ? " (Required)" : " (Optional)"
                messages.append("❌ \(dep.displayName) not found\(required)")
            case .outdated(let current, let minimum):
                hasMissing = true
                messages.append("⚠️ \(dep.displayName) \(current) is below minimum \(minimum)")
            }
        }
        
        if hasMissing {
            messages.append("")
            messages.append("Install missing dependencies:")
            for dep in dependencies {
                if case .missing = dep.status {
                    messages.append("  \(dep.installationCommand)")
                }
            }
        }
        
        return messages.joined(separator: "\n")
    }
}
