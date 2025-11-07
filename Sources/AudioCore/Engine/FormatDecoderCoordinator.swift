//
//  FormatDecoderCoordinator.swift
//  AudioCore
//
//  Abstraction layer for audio format decoding with pluggable decoders.
//  Provides a foundation for FFmpeg integration while remaining fully testable via mocks.
//

import AVFoundation
import Foundation
import os.log

// MARK: - Audio Format Model

/// Normalised metadata about an audio file after decoding
public struct DecodedAudioFormat: Equatable {
    public let codec: String
    public let sampleRate: Int
    public let channelCount: Int
    public let bitRate: Int
    public let duration: TimeInterval
}

// MARK: - Decoder Protocols

/// Errors that can occur while selecting or running format decoders
public enum FormatDecoderError: Error, LocalizedError {
    case noDecoderAvailable(attempted: [String], underlying: [Error])
    case decoderFailed(decoder: String, reason: String)
    case unsupportedFormat(String)

    public var errorDescription: String? {
        switch self {
        case let .noDecoderAvailable(attempted, _):
            return "No format decoder could handle the file. Attempted: \(attempted.joined(separator: ", "))"
        case let .decoderFailed(decoder, reason):
            return "Decoder \(decoder) failed: \(reason)"
        case let .unsupportedFormat(`extension`):
            return "Unsupported audio format: .\(`extension`)"
        }
    }
}

/// Contract for all audio format decoders (AVFoundation, FFmpeg, etc.)
public protocol FormatDecoder {
    /// Identifier for observability
    var name: String { get }

    /// File extensions the decoder can handle (lowercased, without dot)
    var supportedExtensions: Set<String> { get }

    /// Determine if the decoder is suitable for the file path
    func canDecode(filePath: String) -> Bool

    /// Decode metadata from the provided file path
    func decode(filePath: String) throws -> DecodedAudioFormat
}

/// Coordinator protocol to support dependency injection & mocking
public protocol FormatDecodingCoordinating {
    func decodeFormat(for filePath: String) throws -> DecodedAudioFormat
}

// MARK: - Coordinator Implementation

/// Default coordinator that iterates through a priority-ordered list of decoders
public final class DefaultFormatDecodingCoordinator: FormatDecodingCoordinating {
    private let decoders: [FormatDecoder]
    private let logger = Logger.audio

    /// Public convenience initializer using the built-in decoder stack
    public convenience init() {
        self.init(decoders: DefaultFormatDecodingCoordinator.defaultDecoders())
    }

    /// Designated initializer for dependency injection (used heavily in tests)
    public init(decoders: [FormatDecoder]) {
        self.decoders = decoders
    }

    /// Resolve the audio format by delegating to the available decoders
    public func decodeFormat(for filePath: String) throws -> DecodedAudioFormat {
        var attemptedDecoders: [String] = []
        var collectedErrors: [Error] = []

        for decoder in decoders {
            attemptedDecoders.append(decoder.name)
            guard decoder.canDecode(filePath: filePath) else {
                logger.debug("Decoder \(decoder.name, privacy: .public) skipped (unsupported)")
                continue
            }

            do {
                logger.debug("Decoder \(decoder.name, privacy: .public) attempting decode")
                let format = try decoder.decode(filePath: filePath)
                logger.info("Decoder \(decoder.name, privacy: .public) succeeded")
                logger.debug("Codec: \(format.codec, privacy: .public)")
                return format
            } catch {
                collectedErrors.append(error)
                logger.error("Decoder \(decoder.name, privacy: .public) failed")
                logger.debug("Error: \(error.localizedDescription, privacy: .public)")
                continue
            }
        }

        let fileExtension = URL(fileURLWithPath: filePath).pathExtension.lowercased()
        if decoders.contains(where: { $0.supportedExtensions.contains(fileExtension) }) {
            throw FormatDecoderError.noDecoderAvailable(
                attempted: attemptedDecoders,
                underlying: collectedErrors
            )
        } else {
            throw FormatDecoderError.unsupportedFormat(fileExtension)
        }
    }

    private static func defaultDecoders() -> [FormatDecoder] {
        [AVFoundationFormatDecoder(), FFmpegFormatDecoder()] // Future decoders appended here
    }
}

// MARK: - Built-in Decoders

/// Decoder that uses AVFoundation to read audio metadata
struct AVFoundationFormatDecoder: FormatDecoder {
    let name = "AVFoundation"
    let supportedExtensions: Set<String> = [
        "aac", "aiff", "caf", "m4a", "mp3", "mp4", "wav"
    ]

    func canDecode(filePath: String) -> Bool {
        let fileExtension = URL(fileURLWithPath: filePath).pathExtension.lowercased()
        return supportedExtensions.contains(fileExtension)
    }

    func decode(filePath: String) throws -> DecodedAudioFormat {
        let url = URL(fileURLWithPath: filePath)
        let asset = AVURLAsset(url: url)

        // Duration (seconds)
        let durationSeconds = asset.duration.isNumeric ? CMTimeGetSeconds(asset.duration) : 0

        // Inspect first audio track for technical details where possible
        var sampleRate = 0
        var channels = 0
        var bitRate = Int(asset.duration.isNumeric ? asset.estimatedDataRate / 1_000 : 0)
        var codec = url.pathExtension.uppercased()

        if let track = asset.tracks(withMediaType: .audio).first {
            if let formatDescription = track.formatDescriptions.first as? CMAudioFormatDescription,
               let basicDescriptionPointer = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) {
                let streamBasicDescription = basicDescriptionPointer.pointee
                sampleRate = Int(streamBasicDescription.mSampleRate)
                channels = Int(streamBasicDescription.mChannelsPerFrame)
                codec = streamBasicDescription.mFormatID.fourCCString
            }

            if bitRate == 0 {
                bitRate = Int(track.estimatedDataRate / 1_000)
            }
        }

        return DecodedAudioFormat(
            codec: codec,
            sampleRate: sampleRate,
            channelCount: channels,
            bitRate: bitRate,
            duration: durationSeconds
        )
    }
}

/// Placeholder FFmpeg decoder (structure only; implementation pending)
struct FFmpegFormatDecoder: FormatDecoder {
    let name = "FFmpeg"
    let supportedExtensions: Set<String> = [
        "flac", "ogg", "opus", "alac", "ape"
    ]

    func canDecode(filePath: String) -> Bool {
        let fileExtension = URL(fileURLWithPath: filePath).pathExtension.lowercased()
        return supportedExtensions.contains(fileExtension)
    }

    func decode(filePath: String) throws -> DecodedAudioFormat {
        throw FormatDecoderError.decoderFailed(decoder: name, reason: "FFmpeg bridge not yet implemented")
    }
}

// MARK: - Helpers

private extension CMTime {
    var isNumeric: Bool {
        let invalidFlags: CMTimeFlags = [.indefinite, .positiveInfinity, .negativeInfinity]
        return flags.contains(.valid) && flags.isDisjoint(with: invalidFlags)
    }
}

private extension FourCharCode {
    var fourCCString: String {
        let bytes: [CChar] = [
            CChar((self >> 24) & 0xFF),
            CChar((self >> 16) & 0xFF),
            CChar((self >> 8) & 0xFF),
            CChar(self & 0xFF),
            0
        ]
        return String(cString: bytes)
    }
}
