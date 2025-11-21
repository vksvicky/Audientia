//
//  RealFFmpegWrapper.swift
//  DataLayer
//
//  Real FFmpeg wrapper implementation using Process
//

import Foundation
import os.log
import Shared

/// Real implementation of FFmpegWrapperProtocol using Process
actor RealFFmpegWrapper: FFmpegWrapperProtocol {
    
    private let logger = Logger.deviceSync
    private var ffmpegPath: String?
    private var availabilityChecked = false
    private var isAvailableCache = false
    
    init() {
        // Find FFmpeg executable
        // Check common locations: bundled, system PATH, or /usr/local/bin
        Task {
            await findFFmpeg()
        }
    }
    
    func transcode(
        params: TranscodeParams,
        progress: @escaping (Double) -> Void
    ) async throws {
        guard let ffmpeg = await getFFmpegPath() else {
            throw TranscodeError.engineNotAvailable
        }
        
        let arguments = buildFFmpegArguments(
            inputPath: params.inputPath,
            outputPath: params.outputPath,
            format: params.format,
            bitrate: params.bitrate,
            sampleRate: params.sampleRate
        )
        
        let setup = setupFFmpegProcess(ffmpeg: ffmpeg, arguments: arguments)
        let progressTask = startProgressParsing(fileHandle: setup.fileHandle, progress: progress)
        
        do {
            try await executeFFmpegProcess(
                process: setup.process,
                fileHandle: setup.fileHandle,
                progressTask: progressTask,
                progress: progress
            )
        } catch {
            progressTask?.cancel()
            throw TranscodeError.transcodingFailed(error.localizedDescription)
        }
    }
    
    private func buildFFmpegArguments(
        inputPath: String,
        outputPath: String,
        format: AudioFormat,
        bitrate: Int,
        sampleRate: Int?
    ) -> [String] {
        var arguments: [String] = [
            "-i", inputPath,
            "-y" // Overwrite output file
        ]
        
        // Set audio codec based on format
        switch format {
        case .mp3:
            arguments.append(contentsOf: ["-acodec", "libmp3lame", "-b:a", "\(bitrate)k"])
        case .aac:
            arguments.append(contentsOf: ["-acodec", "aac", "-b:a", "\(bitrate)k"])
        case .flac:
            arguments.append(contentsOf: ["-acodec", "flac", "-compression_level", "5"])
        case .original:
            break
        }
        
        // Set sample rate if specified
        if let sampleRate = sampleRate {
            arguments.append(contentsOf: ["-ar", "\(sampleRate)"])
        }
        
        // Output file
        arguments.append(outputPath)
        return arguments
    }
    
    private struct FFmpegProcessSetup {
        let process: Process
        let pipe: Pipe
        let fileHandle: FileHandle
    }
    
    private func setupFFmpegProcess(ffmpeg: String, arguments: [String]) -> FFmpegProcessSetup {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpeg)
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardError = pipe
        let fileHandle = pipe.fileHandleForReading
        
        return FFmpegProcessSetup(process: process, pipe: pipe, fileHandle: fileHandle)
    }
    
    private func startProgressParsing(
        fileHandle: FileHandle,
        progress: @escaping (Double) -> Void
    ) -> Task<Void, Never> {
        Task {
            var buffer = Data()
            while !Task.isCancelled {
                let availableData = fileHandle.availableData
                if availableData.isEmpty {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    continue
                }
                
                buffer.append(availableData)
                if let string = String(data: buffer, encoding: .utf8) {
                    if let progressValue = parseFFmpegProgress(from: string) {
                        progress(progressValue)
                    }
                    buffer.removeAll()
                }
            }
        }
    }
    
    private func executeFFmpegProcess(
        process: Process,
        fileHandle: FileHandle,
        progressTask: Task<Void, Never>?,
        progress: @escaping (Double) -> Void
    ) async throws {
        try process.run()
        process.waitUntilExit()
        progressTask?.cancel()
        
        guard process.terminationStatus == 0 else {
            let errorData = try? fileHandle.readToEnd()
            let errorMessage = errorData.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown error"
            let errorMsg = "FFmpeg exited with code \(process.terminationStatus): \(errorMessage)"
            throw TranscodeError.transcodingFailed(errorMsg)
        }
        
        // Final progress
        progress(1.0)
    }
    
    func isAvailable() async -> Bool {
        if availabilityChecked {
            return isAvailableCache
        }
        
        availabilityChecked = true
        isAvailableCache = await getFFmpegPath() != nil
        return isAvailableCache
    }
    
    func getVersion() async -> String? {
        guard let ffmpeg = await getFFmpegPath() else {
            return nil
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpeg)
        process.arguments = ["-version"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0,
               let data = try? pipe.fileHandleForReading.readToEnd(),
               let output = String(data: data, encoding: .utf8) {
                return output.components(separatedBy: .newlines).first
            }
        } catch {
            logger.error("Failed to get FFmpeg version: \(error.localizedDescription, privacy: .public)")
        }
        
        return nil
    }
    
    // MARK: - Private
    
    private func findFFmpeg() async {
        // Check bundled location first
        if let bundlePath = Bundle.main.path(forResource: "ffmpeg", ofType: nil, inDirectory: "Frameworks") {
            ffmpegPath = bundlePath
            return
        }
        
        // Check system PATH
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["ffmpeg"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0,
               let data = try? pipe.fileHandleForReading.readToEnd(),
               let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !path.isEmpty {
                ffmpegPath = path
                return
            }
        } catch {
            logger.debug("FFmpeg not found in PATH: \(error.localizedDescription, privacy: .public)")
        }
        
        // Check common locations
        let commonPaths = [
            "/usr/local/bin/ffmpeg",
            "/opt/homebrew/bin/ffmpeg",
            "/usr/bin/ffmpeg"
        ]
        
        for path in commonPaths where FileManager.default.fileExists(atPath: path) {
            ffmpegPath = path
            return
        }
    }
    
    private func getFFmpegPath() async -> String? {
        if ffmpegPath == nil {
            await findFFmpeg()
        }
        return ffmpegPath
    }
    
    private func parseFFmpegProgress(from output: String) -> Double? {
        // FFmpeg outputs progress like: time=00:01:23.45
        // We need to parse this and convert to 0.0-1.0 progress
        // For simplicity, we'll use a basic heuristic based on output length
        // In a real implementation, we'd parse the time and compare to total duration
        
        // Simple heuristic: if we see "time=" in output, estimate progress
        // This is a placeholder - real implementation would parse duration from input
        if output.contains("time=") {
            // Extract time value and estimate (this is simplified)
            // Real implementation would need input file duration
            return nil // Will be improved with actual duration parsing
        }
        
        return nil
    }
}
