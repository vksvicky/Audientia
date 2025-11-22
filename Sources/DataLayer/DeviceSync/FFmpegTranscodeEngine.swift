//
//  FFmpegTranscodeEngine.swift
//  DataLayer
//
//  FFmpeg-based transcoding engine implementation
//

import Foundation
import os.log
import Shared

/// FFmpeg-based implementation of TranscodeEngineProtocol
/// Uses FFmpeg for format conversion and quality adjustment
public actor FFmpegTranscodeEngine: TranscodeEngineProtocol {
    
    private let ffmpegWrapper: FFmpegWrapperProtocol
    private let logger = Logger.deviceSync
    private var availabilityChecked = false
    private var isAvailable = false
    
    public init(ffmpegWrapper: FFmpegWrapperProtocol? = nil) {
        // Use provided wrapper or create default implementation
        if let wrapper = ffmpegWrapper {
            self.ffmpegWrapper = wrapper
        } else {
            self.ffmpegWrapper = RealFFmpegWrapper()
        }
    }
    
    public func transcode(
        inputPath: String,
        outputPath: String,
        profile: TranscodeProfile,
        progress: @escaping (Double) -> Void
    ) async throws -> String {
        // Check FFmpeg availability
        if !availabilityChecked {
            isAvailable = await ffmpegWrapper.isAvailable()
            availabilityChecked = true
        }
        
        guard isAvailable else {
            throw TranscodeError.engineNotAvailable
        }
        
        // Validate input file
        guard FileManager.default.fileExists(atPath: inputPath) else {
            throw TranscodeError.invalidInputFile
        }
        
        // Validate output directory exists
        let outputURL = URL(fileURLWithPath: outputPath)
        let outputDir = outputURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: outputDir.path) {
            do {
                try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
            } catch {
                throw TranscodeError.invalidOutputPath
            }
        }
        
        // Check if format is supported
        let inputExtension = (inputPath as NSString).pathExtension.lowercased()
        guard AudioFormats.isSupported(inputExtension) else {
            throw TranscodeError.unsupportedFormat
        }
        
        // Check available space (rough estimate)
        try await checkAvailableSpace(outputDir: outputDir, inputPath: inputPath, profile: profile)
        
        // Use FFmpeg wrapper for actual transcoding
        do {
            let params = TranscodeParams(
                inputPath: inputPath,
                outputPath: outputPath,
                format: profile.format,
                bitrate: profile.bitrate,
                sampleRate: profile.sampleRate
            )
            try await ffmpegWrapper.transcode(params: params, progress: progress)
            
            logger.info("Transcoded \(inputPath, privacy: .public) to \(outputPath, privacy: .public)")
            return outputPath
        } catch let error as TranscodeError {
            throw error
        } catch {
            throw TranscodeError.transcodingFailed(error.localizedDescription)
        }
    }
    
    public func needsTranscoding(track: Track, profile: TranscodeProfile) async -> Bool {
        let trackExtension = (track.filePath as NSString).pathExtension.lowercased()
        let profileFormatExtension = profile.format.rawValue
        
        // If format matches and bitrate is acceptable, no transcoding needed
        if trackExtension == profileFormatExtension {
            // Check if bitrate is close enough (within 20%)
            if profile.bitrate > 0 {
                let bitrateDiff = abs(track.bitrate - profile.bitrate)
                let threshold = profile.bitrate / 5 // 20%
                return bitrateDiff > threshold
            }
            return false
        }
        
        return true
    }
    
    public func estimateOutputSize(track: Track, profile: TranscodeProfile) async -> Int64 {
        // Simple estimation: bitrate * duration / 8 (bytes)
        // Add 10% overhead for container/metadata
        let bitrateBytesPerSecond = Double(profile.bitrate * 1000) / 8.0
        let baseSize = Int64(bitrateBytesPerSecond * track.duration)
        return Int64(Double(baseSize) * 1.1) // 10% overhead
    }
    
    private func checkAvailableSpace(
        outputDir: URL,
        inputPath: String,
        profile: TranscodeProfile
    ) async throws {
        guard let availableSpace = try? FileManager.default.attributesOfFileSystem(
            forPath: outputDir.path
        )[.systemFreeSize] as? Int64 else {
            return // Can't check, proceed anyway
        }
        
        let estimatedSize = await estimateOutputSize(
            track: Track(
                title: "",
                artist: "",
                album: "",
                duration: 180.0, // Default estimate
                filePath: inputPath,
                fileSize: 0,
                bitrate: 0,
                sampleRate: 44100
            ),
            profile: profile
        )
        
        if availableSpace < estimatedSize {
            throw TranscodeError.insufficientSpace
        }
    }
}
