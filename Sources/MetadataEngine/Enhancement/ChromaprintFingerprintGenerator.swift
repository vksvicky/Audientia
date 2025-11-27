//
//  ChromaprintFingerprintGenerator.swift
//  MetadataEngine
//
//  Real Chromaprint fingerprint generator using FFmpeg
//

import Foundation
import os.log
import Shared
/// Real implementation of FingerprintGeneratorProtocol using FFmpeg's chromaprint filter or fpcalc
public actor ChromaprintFingerprintGenerator: FingerprintGeneratorProtocol {
    
    private let logger = Logger.metadata
    private var ffmpegPath: String?
    private var fpcalcPath: String?
    private var availabilityChecked = false
    private var isAvailableCache = false
    private var useFpcalc = false // Whether to use fpcalc instead of FFmpeg
    
    public init() {
        // Find FFmpeg and fpcalc executables
        Task {
            await findFFmpeg()
            await findFpcalc()
        }
    }
    
    // MARK: - FingerprintGeneratorProtocol
    
    public func generateFingerprint(fileURL: URL) async throws -> String {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw AcoustIDError.fileNotFound(fileURL)
        }
        
        // Determine which method to use
        let useFpcalcMethod = await shouldUseFpcalc()
        
        if useFpcalcMethod {
            return try await generateFingerprintWithFpcalc(fileURL: fileURL)
        } else {
            return try await generateFingerprintWithFFmpeg(fileURL: fileURL)
        }
    }
    
    // Generate fingerprint using fpcalc (preferred method)
    private func generateFingerprintWithFpcalc(fileURL: URL) async throws -> String {
        guard let fpcalc = await getFpcalcPath() else {
            throw AcoustIDError.fingerprintGenerationFailed("fpcalc executable not found. Install with: brew install chromaprint")
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: fpcalc)
        // fpcalc outputs: DURATION=<seconds>\nFINGERPRINT=<fingerprint>
        process.arguments = [fileURL.path]
        
        let pipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = stderrPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            guard process.terminationStatus == 0 else {
                // Read stderr to get actual error message
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrString = String(data: stderrData, encoding: .utf8) ?? "Unknown error"
                
                // Extract meaningful error message
                let errorMessage = stderrString.trimmingCharacters(in: .whitespacesAndNewlines)
                if errorMessage.isEmpty {
                    throw AcoustIDError.fingerprintGenerationFailed("fpcalc process failed with status \(process.terminationStatus)")
                } else {
                    throw AcoustIDError.fingerprintGenerationFailed("fpcalc failed: \(errorMessage)")
                }
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                throw AcoustIDError.fingerprintGenerationFailed("Failed to read fpcalc output")
            }
            
            // Parse fingerprint from fpcalc output
            // Format: DURATION=<seconds>\nFINGERPRINT=<fingerprint>
            return try parseFpcalcOutput(output)
        } catch let error as AcoustIDError {
            throw error
        } catch {
            throw AcoustIDError.fingerprintGenerationFailed(error.localizedDescription)
        }
    }
    
    // Generate fingerprint using FFmpeg chromaprint filter
    private func generateFingerprintWithFFmpeg(fileURL: URL) async throws -> String {
        guard let ffmpeg = await getFFmpegPath() else {
            throw AcoustIDError.fingerprintGenerationFailed("FFmpeg executable not found")
        }
        
        // Check if chromaprint filter is available
        guard await isChromaprintAvailable(ffmpeg: ffmpeg) else {
            // Fall back to fpcalc if available
            if await getFpcalcPath() != nil {
                return try await generateFingerprintWithFpcalc(fileURL: fileURL)
            }
            throw AcoustIDError.fingerprintGenerationFailed(
                "FFmpeg chromaprint filter is not available. " +
                "Install chromaprint: brew install chromaprint"
            )
        }
        
        // Build FFmpeg command for Chromaprint
        // FFmpeg chromaprint filter outputs fingerprint to stderr
        // Format: [chromaprint @ 0x...] fingerprint=AQADtE...
        let arguments = [
            "-i", fileURL.path,
            "-af", "chromaprint",
            "-f", "null",
            "-"
        ]
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpeg)
        process.arguments = arguments
        
        // Capture stderr (where chromaprint outputs the fingerprint)
        let stderrPipe = Pipe()
        process.standardError = stderrPipe
        process.standardOutput = Pipe() // Discard stdout
        
        do {
            try process.run()
            process.waitUntilExit()
            
            // Read stderr output
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            guard let stderrString = String(data: stderrData, encoding: .utf8) else {
                throw AcoustIDError.fingerprintGenerationFailed("Failed to read FFmpeg output")
            }
            
            // Parse fingerprint from output
            // Look for pattern: fingerprint=AQADtE...
            let fingerprint = try parseFingerprint(from: stderrString)
            
            guard !fingerprint.isEmpty else {
                throw AcoustIDError.fingerprintGenerationFailed("Empty fingerprint generated")
            }
            
            return fingerprint
        } catch {
            if process.terminationStatus != 0 {
                // Read stderr to get actual error message
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrString = String(data: stderrData, encoding: .utf8) ?? "Unknown error"
                
                // Extract meaningful error message
                let errorMessage = extractErrorMessage(from: stderrString) ?? stderrString
                throw AcoustIDError.fingerprintGenerationFailed(
                    "FFmpeg process failed with status \(process.terminationStatus): \(errorMessage)"
                )
            }
            throw AcoustIDError.fingerprintGenerationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Private Methods
    
    // Parse fpcalc output: DURATION=<seconds>\nFINGERPRINT=<fingerprint>
    private func parseFpcalcOutput(_ output: String) throws -> String {
        let lines = output.components(separatedBy: .newlines)
        for line in lines where line.hasPrefix("FINGERPRINT=") {
            let fingerprint = String(line.dropFirst("FINGERPRINT=".count)).trimmingCharacters(in: .whitespaces)
            if !fingerprint.isEmpty {
                return fingerprint
            }
        }
        throw AcoustIDError.fingerprintGenerationFailed("Could not parse fingerprint from fpcalc output")
    }
    
    private func parseFingerprint(from output: String) throws -> String {
        // FFmpeg chromaprint filter outputs: [chromaprint @ 0x...] fingerprint=AQADtE...
        // We need to extract the fingerprint value
        
        // Pattern 1: Look for "fingerprint=" followed by the fingerprint
        if let range = output.range(of: "fingerprint=") {
            let afterFingerprint = output[range.upperBound...]
            // Extract until newline or end
            if let newlineRange = afterFingerprint.range(of: "\n") {
                let fingerprint = String(afterFingerprint[..<newlineRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                if !fingerprint.isEmpty {
                    return fingerprint
                }
            } else {
                // No newline, take the rest
                let fingerprint = String(afterFingerprint).trimmingCharacters(in: .whitespaces)
                if !fingerprint.isEmpty {
                    return fingerprint
                }
            }
        }
        
        // Pattern 2: Look for base64-like strings (Chromaprint fingerprints are base64)
        // This is a fallback if the format is different
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Chromaprint fingerprints are typically long base64 strings
            if trimmed.count > 20 && trimmed.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "+" || $0 == "/" || $0 == "=" }) {
                // Check if it looks like a fingerprint (starts with common Chromaprint prefixes)
                if trimmed.hasPrefix("AQAD") || trimmed.hasPrefix("AgAD") {
                    return trimmed
                }
            }
        }
        
        throw AcoustIDError.fingerprintGenerationFailed("Could not parse fingerprint from FFmpeg output")
    }
    
    // Determine which method to use (fpcalc is preferred)
    private func shouldUseFpcalc() async -> Bool {
        // Prefer fpcalc if available, as it's the native chromaprint tool
        await getFpcalcPath() != nil
    }
    
    private func findFpcalc() async {
        self.fpcalcPath = ExecutableFinder.findExecutable("fpcalc")
    }
    
    private func getFpcalcPath() async -> String? {
        if fpcalcPath == nil {
            await findFpcalc()
        }
        return fpcalcPath
    }
    
    private func findFFmpeg() async {
        if let path = ExecutableFinder.findExecutable("ffmpeg") {
            self.ffmpegPath = path
            self.isAvailableCache = true
        } else {
            self.ffmpegPath = nil
            self.isAvailableCache = false
        }
    }
    
    private func getFFmpegPath() async -> String? {
        if !availabilityChecked {
            await findFFmpeg()
            availabilityChecked = true
        }
        return ffmpegPath
    }
    
    private func isFFmpegAvailable() async -> Bool {
        if !availabilityChecked {
            await findFFmpeg()
            availabilityChecked = true
        }
        return isAvailableCache
    }
    
    // Check if chromaprint filter is available in FFmpeg
    private func isChromaprintAvailable(ffmpeg: String) async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpeg)
        process.arguments = ["-filters"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe() // Suppress stderr
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    // Check if chromaprint filter is in the list
                    return output.contains("chromaprint")
                }
            }
        } catch {
            // If we can't check, assume not available
            return false
        }
        
        return false
    }
    
    // Extract meaningful error message from FFmpeg stderr
    private func extractErrorMessage(from output: String) -> String? {
        let lines = output.components(separatedBy: .newlines)
        
        // Look for common error patterns
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let error = extractSpecificError(from: trimmed) {
                return error
            }
        }
        
        // Return last non-empty line if no specific error found
        for line in lines.reversed() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && !trimmed.hasPrefix("[") {
                return trimmed
            }
        }
        
        return nil
    }
    
    private func extractSpecificError(from line: String) -> String? {
        if line.contains("No such filter") || line.contains("Filter not found") {
            return line.contains("chromaprint") ? "Chromaprint filter not found in FFmpeg" : line
        }
        if line.contains("Unknown encoder") || line.contains("Codec not found") {
            return line
        }
        if line.contains("No such file") || line.contains("Invalid data") {
            return line
        }
        if line.contains("Permission denied") {
            return line
        }
        return nil
    }
    
    // Public method for testing
    public func checkAvailability() async -> Bool {
        // Check if fpcalc is available (preferred)
        if await getFpcalcPath() != nil {
            return true
        }
        
        // Fall back to checking FFmpeg with chromaprint filter
        guard await isFFmpegAvailable() else {
            return false
        }
        guard let ffmpeg = await getFFmpegPath() else {
            return false
        }
        return await isChromaprintAvailable(ffmpeg: ffmpeg)
    }
}
