//
//  ExecutableFinder.swift
//  MetadataEngine
//
//  Helper for finding executables in common paths
//

import Foundation

/// Helper for finding executables in common system paths
enum ExecutableFinder {
    /// Find an executable in common paths or PATH
    static func findExecutable(_ name: String) -> String? {
        let possiblePaths = [
            "/usr/local/bin/\(name)",
            "/opt/homebrew/bin/\(name)",
            "/usr/bin/\(name)",
            name // In PATH
        ]
        
        for path in possiblePaths {
            if path == name {
                // Check if executable is in PATH
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
                process.arguments = [name]
                let pipe = Pipe()
                process.standardOutput = pipe
                
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
                    continue
                }
            } else {
                // Check if file exists at path
                if FileManager.default.fileExists(atPath: path) {
                    return path
                }
            }
        }
        
        return nil
    }
}
