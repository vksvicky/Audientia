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
import Shared

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
    func decode(filePath: String) async throws -> DecodedAudioFormat
}

/// Coordinator protocol to support dependency injection & mocking
public protocol FormatDecodingCoordinating {
    func decodeFormat(for filePath: String) async throws -> DecodedAudioFormat
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
    public func decodeFormat(for filePath: String) async throws -> DecodedAudioFormat {
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
                let format = try await decoder.decode(filePath: filePath)
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

        // If we attempted any decoders (even if they were skipped), throw noDecoderAvailable
        // Only throw unsupportedFormat if no decoders were provided or attempted
        if !attemptedDecoders.isEmpty {
            throw FormatDecoderError.noDecoderAvailable(
                attempted: attemptedDecoders,
                underlying: collectedErrors
            )
        } else {
            let fileExtension = URL(fileURLWithPath: filePath).pathExtension.lowercased()
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
    let supportedExtensions: Set<String> = AudioFormats.avFoundationSupportedExtensions

    func canDecode(filePath: String) -> Bool {
        let fileExtension = URL(fileURLWithPath: filePath).pathExtension.lowercased()
        return supportedExtensions.contains(fileExtension)
    }

    func decode(filePath: String) async throws -> DecodedAudioFormat {
        let url = URL(fileURLWithPath: filePath)
        let asset = AVURLAsset(url: url)

        let durationSeconds = try await loadDurationSeconds(for: asset)
        let trackMetrics = try await loadTrackMetrics(for: asset, defaultCodec: url.pathExtension.uppercased())

        return DecodedAudioFormat(
            codec: trackMetrics.codec,
            sampleRate: trackMetrics.sampleRate,
            channelCount: trackMetrics.channelCount,
            bitRate: trackMetrics.bitRate,
            duration: durationSeconds
        )
    }
}

private extension AVFoundationFormatDecoder {
    struct TrackMetrics {
        let codec: String
        let sampleRate: Int
        let channelCount: Int
        let bitRate: Int
    }

    func loadDurationSeconds(for asset: AVURLAsset) async throws -> TimeInterval {
        let durationTime: CMTime
        if #available(macOS 13.0, *) {
            durationTime = try await asset.load(.duration)
        } else {
            durationTime = asset.duration
        }
        return durationTime.isNumeric ? CMTimeGetSeconds(durationTime) : 0
    }

    func loadTrackMetrics(for asset: AVURLAsset, defaultCodec: String) async throws -> TrackMetrics {
        guard let track = try await firstAudioTrack(from: asset) else {
            return TrackMetrics(codec: defaultCodec, sampleRate: 0, channelCount: 0, bitRate: 0)
        }

        let formatDescriptions = try await loadFormatDescriptions(for: track)
        var codec = defaultCodec
        var sampleRate = 0
        var channelCount = 0
        var bitsPerSample = 0

        if let formatDescription = formatDescriptions.first,
           let basicDescriptionPointer = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) {
            let streamBasicDescription = basicDescriptionPointer.pointee
            sampleRate = Int(streamBasicDescription.mSampleRate)
            channelCount = Int(streamBasicDescription.mChannelsPerFrame)
            codec = streamBasicDescription.mFormatID.fourCCString
            bitsPerSample = Int(streamBasicDescription.mBitsPerChannel)
        }

        let estimatedBitRate = try await loadEstimatedDataRate(for: track)
        let bitRate: Int
        if estimatedBitRate > 0 {
            bitRate = Int(estimatedBitRate / 1_000)
        } else if sampleRate > 0 && bitsPerSample > 0 && channelCount > 0 {
            bitRate = Int(Double(sampleRate * bitsPerSample * channelCount) / 1_000.0)
        } else {
            bitRate = 0
        }

        return TrackMetrics(
            codec: codec,
            sampleRate: sampleRate,
            channelCount: channelCount,
            bitRate: bitRate
        )
    }

    func firstAudioTrack(from asset: AVURLAsset) async throws -> AVAssetTrack? {
        if #available(macOS 13.0, *) {
            return try await asset.loadTracks(withMediaType: .audio).first
        } else {
            return asset.tracks(withMediaType: .audio).first
        }
    }

    func loadFormatDescriptions(for track: AVAssetTrack) async throws -> [CMFormatDescription] {
        if #available(macOS 13.0, *) {
            return try await track.load(.formatDescriptions)
        } else {
            return (track.formatDescriptions as? [CMFormatDescription]) ?? []
        }
    }

    func loadEstimatedDataRate(for track: AVAssetTrack) async throws -> Double {
        if #available(macOS 13.0, *) {
            return Double(try await track.load(.estimatedDataRate))
        } else {
            return Double(track.estimatedDataRate)
        }
    }
}

struct FFmpegFormatDecoder: FormatDecoder {
    let name = "FFmpeg"
    let supportedExtensions: Set<String> = AudioFormats.ffmpegSupportedExtensions

    func canDecode(filePath: String) -> Bool {
        let fileExtension = URL(fileURLWithPath: filePath).pathExtension.lowercased()
        return supportedExtensions.contains(fileExtension)
    }

    func decode(filePath: String) async throws -> DecodedAudioFormat {
        let url = URL(fileURLWithPath: filePath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw FormatDecoderError.decoderFailed(decoder: name, reason: "File not found")
        }

        let fileExtension = url.pathExtension.lowercased()
        switch fileExtension {
        case "flac":
            return try decodeFLAC(url: url)
        default:
            throw FormatDecoderError.decoderFailed(decoder: name, reason: "Unsupported format .\(fileExtension)")
        }
    }

    private func decodeFLAC(url: URL) throws -> DecodedAudioFormat {
        let data = try Data(contentsOf: url)
        guard data.count >= 4, data.starts(with: [0x66, 0x4C, 0x61, 0x43]) else {
            throw FormatDecoderError.decoderFailed(decoder: name, reason: "Invalid FLAC header")
        }

        var offset = 4
        var streamInfoBlock: Data?

        while offset + 4 <= data.count {
            let headerByte = data[offset]
            let isLastBlock = (headerByte & 0x80) != 0
            let blockType = headerByte & 0x7F
            let blockLength = Int(data[offset + 1]) << 16
                | Int(data[offset + 2]) << 8
                | Int(data[offset + 3])
            offset += 4

            guard offset + blockLength <= data.count else {
                throw FormatDecoderError.decoderFailed(decoder: name, reason: "Malformed FLAC metadata")
            }

            let blockData = data.subdata(in: offset..<(offset + blockLength))
            if blockType == 0 { // STREAMINFO
                streamInfoBlock = blockData
            }

            offset += blockLength
            if isLastBlock { break }
        }

        guard let streamInfo = streamInfoBlock, streamInfo.count >= 34 else {
            throw FormatDecoderError.decoderFailed(decoder: name, reason: "STREAMINFO block missing")
        }

        let statsBytes = streamInfo[10..<18]
        let combined = statsBytes.reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }

        let sampleRate = Int((combined >> 44) & 0xFFFFF)
        let channels = Int((combined >> 41) & 0x7) + 1
        let bitsPerSample = Int((combined >> 36) & 0x1F) + 1
        let totalSamples = UInt64(combined & 0xFFFFFFFFF)

        let duration: TimeInterval
        if sampleRate > 0 && totalSamples > 0 {
            duration = Double(totalSamples) / Double(sampleRate)
        } else {
            duration = 0
        }

        let bitRate = sampleRate > 0 ? Int(Double(sampleRate * bitsPerSample * channels) / 1000.0) : 0

        return DecodedAudioFormat(
            codec: "FLAC",
            sampleRate: sampleRate,
            channelCount: channels,
            bitRate: bitRate,
            duration: duration
        )
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
