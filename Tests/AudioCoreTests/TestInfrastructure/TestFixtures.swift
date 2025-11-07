//
//  TestFixtures.swift
//  AudioCoreTests
//
//  Test fixtures and sample files for integration testing
//

import Foundation

/// Test fixtures for integration testing with real audio files
enum TestFixtures {
    /// Base directory for test fixtures
    static var fixturesDirectory: URL {
        let testBundle = Bundle(for: AudioCoreTestsBundle.self)
        guard let fixturesURL = testBundle.url(forResource: "Fixtures", withExtension: nil) else {
            fatalError("Test fixtures directory not found. Please add Fixtures directory to test bundle.")
        }
        return fixturesURL
    }
    
    /// Get path to a test audio file
    /// - Parameters:
    ///   - filename: Name of the audio file
    ///   - format: Audio format (mp3, flac, aac, etc.)
    /// - Returns: URL to the test file, or nil if not found
    static func audioFile(filename: String, format: String) -> URL? {
        let fileURL = fixturesDirectory
            .appendingPathComponent("Audio")
            .appendingPathComponent(format)
            .appendingPathComponent(filename)
        
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    
    /// Get path to a sample MP3 file
    static func sampleMP3() -> URL? {
        audioFile(filename: "sample.mp3", format: "mp3")
    }
    
    /// Get path to a sample FLAC file
    static func sampleFLAC() -> URL? {
        audioFile(filename: "sample.flac", format: "flac")
    }
    
    /// Get path to a sample AAC file
    static func sampleAAC() -> URL? {
        audioFile(filename: "sample.aac", format: "aac")
    }
    
    /// Get path to a sample WAV file
    static func sampleWAV() -> URL? {
        audioFile(filename: "sample.wav", format: "wav")
    }
    
    /// Check if a test file exists
    /// - Parameter url: URL to check
    /// - Returns: True if file exists
    static func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    /// Create a temporary FLAC sample file containing a valid STREAMINFO block
    /// - Parameters:
    ///   - sampleRate: Sample rate in Hz
    ///   - channels: Number of audio channels
    ///   - bitsPerSample: Bits per sample
    ///   - durationSeconds: Duration in seconds (used to derive total samples)
    /// - Returns: URL to the generated FLAC file
    static func createTemporaryFLACSample(
        sampleRate: Int = 44_100,
        channels: Int = 2,
        bitsPerSample: Int = 16,
        durationSeconds: Double = 1.0
    ) throws -> URL {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AudioCoreTests-\(UUID().uuidString).flac")

        let data = try FLACSampleBuilder.buildSample(
            sampleRate: sampleRate,
            channels: channels,
            bitsPerSample: bitsPerSample,
            durationSeconds: durationSeconds
        )

        try data.write(to: tempURL)
        return tempURL
    }

    /// Remove a temporary file if it exists (best-effort)
    static func removeTemporaryFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}

/// Bundle marker class for finding test resources
private class AudioCoreTestsBundle {}

// MARK: - FLAC Sample Builder

private enum FLACSampleBuilder {
    static func buildSample(
        sampleRate: Int,
        channels: Int,
        bitsPerSample: Int,
        durationSeconds: Double
    ) throws -> Data {
        precondition(sampleRate > 0)
        precondition(channels > 0)
        precondition(bitsPerSample > 0)

        let totalSamples = UInt64(Double(sampleRate) * durationSeconds)

        var streamInfo = Data()
        // Min/Max block size (set to defaults)
        streamInfo.append(contentsOf: [0x10, 0x00]) // min block size 4096
        streamInfo.append(contentsOf: [0x10, 0x00]) // max block size 4096

        // Min/Max frame size (unknown -> 0)
        streamInfo.append(contentsOf: [0x00, 0x00, 0x00])
        streamInfo.append(contentsOf: [0x00, 0x00, 0x00])

        let channelsMinusOne = UInt64(channels - 1)
        let bitsPerSampleMinusOne = UInt64(bitsPerSample - 1)
        let sampleRateBits = UInt64(sampleRate & 0xFFFFF)
        let packed: UInt64 = (sampleRateBits << (3 + 5 + 36))
            | (channelsMinusOne << (5 + 36))
            | (bitsPerSampleMinusOne << 36)
            | (UInt64(totalSamples) & 0xFFFFFFFFF)

        var packedBytes = [UInt8](repeating: 0, count: 8)
        for index in 0..<8 {
            packedBytes[index] = UInt8((packed >> (8 * (7 - index))) & 0xFF)
        }
        streamInfo.append(contentsOf: packedBytes)

        // MD5 signature (set to zeroes)
        streamInfo.append(contentsOf: Array(repeating: UInt8(0), count: 16))

        guard streamInfo.count == 34 else {
            throw NSError(domain: "FLACSampleBuilder", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid STREAMINFO length"])
        }

        var flacData = Data([0x66, 0x4C, 0x61, 0x43]) // 'fLaC'
        // Metadata block header: last block flag + STREAMINFO + length 34 (24-bit big-endian)
        flacData.append(0x80) // last flag set, type 0
        flacData.append(0x00) // length byte 1 (high)
        flacData.append(0x00) // length byte 2 (middle)
        flacData.append(0x22) // length byte 3 (low) - 34 decimal
        flacData.append(streamInfo)

        return flacData
    }
}
