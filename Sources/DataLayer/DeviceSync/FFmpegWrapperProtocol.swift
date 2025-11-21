//
//  FFmpegWrapperProtocol.swift
//  DataLayer
//
//  Protocol for FFmpeg operations (transcoding)
//

import Foundation
import Shared

/// Parameters for FFmpeg transcoding operation
public struct TranscodeParams: Sendable {
    public let inputPath: String
    public let outputPath: String
    public let format: AudioFormat
    public let bitrate: Int
    public let sampleRate: Int?
    
    public init(
        inputPath: String,
        outputPath: String,
        format: AudioFormat,
        bitrate: Int,
        sampleRate: Int?
    ) {
        self.inputPath = inputPath
        self.outputPath = outputPath
        self.format = format
        self.bitrate = bitrate
        self.sampleRate = sampleRate
    }
}

/// Protocol for FFmpeg command execution
/// Allows testing without requiring FFmpeg to be installed
public protocol FFmpegWrapperProtocol: Sendable {
    /// Execute FFmpeg transcoding command
    /// - Parameters:
    ///   - params: Transcoding parameters
    ///   - progress: Progress callback (0.0 to 1.0)
    /// - Throws: TranscodeError if transcoding fails
    func transcode(
        params: TranscodeParams,
        progress: @escaping (Double) -> Void
    ) async throws
    
    /// Check if FFmpeg is available
    /// - Returns: True if FFmpeg can be executed
    func isAvailable() async -> Bool
    
    /// Get FFmpeg version information
    /// - Returns: Version string or nil if unavailable
    func getVersion() async -> String?
}
