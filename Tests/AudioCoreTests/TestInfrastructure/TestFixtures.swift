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
        // First, try to find fixtures in the test bundle (production case)
        let testBundle = Bundle(for: AudioCoreTestsBundle.self)
        if let bundleFixturesURL = testBundle.url(forResource: "Fixtures", withExtension: nil),
           FileManager.default.fileExists(atPath: bundleFixturesURL.path) {
            return bundleFixturesURL
        }
        
        // Fallback: Try to find fixtures relative to source file location (development case)
        // This helps when running tests directly or when bundle resources aren't set up yet
        let sourceFile = #file
        let sourceURL = URL(fileURLWithPath: sourceFile)
        let sourceDir = sourceURL.deletingLastPathComponent() // TestInfrastructure/
        let projectDir = sourceDir.deletingLastPathComponent() // Tests/AudioCoreTests/
        let fallbackFixturesURL = projectDir.appendingPathComponent("Fixtures")
        
        if FileManager.default.fileExists(atPath: fallbackFixturesURL.path) {
            return fallbackFixturesURL
        }
        
        // Last resort: Try common test fixture locations
        let commonPaths = [
            projectDir.appendingPathComponent("Fixtures"),
            sourceDir.appendingPathComponent("Fixtures"),
            sourceDir.appendingPathComponent("../Fixtures")
        ]
        
        for path in commonPaths where FileManager.default.fileExists(atPath: path.path) {
            return path
        }
        
        // If all else fails, provide a helpful error message
        let errorMessage = """
        Test fixtures directory not found.
        
        Please ensure:
        1. The Fixtures directory exists at: \(projectDir.appendingPathComponent("Fixtures").path)
        2. Files are added to the AudioCoreTests target
        3. Files are in the "Copy Bundle Resources" build phase
        
        Current search locations:
        - Bundle: \(testBundle.bundlePath)
        - Source relative: \(fallbackFixturesURL.path)
        """
        
        fatalError(errorMessage)
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
    
    /// Get path to a valid MP3 file
    static func sampleMP3() -> URL? {
        audioFile(filename: "valid.mp3", format: "mp3")
    }
    
    /// Get path to a valid FLAC file
    static func sampleFLAC() -> URL? {
        audioFile(filename: "valid.flac", format: "flac")
    }
    
    /// Get path to a valid AAC file
    static func sampleAAC() -> URL? {
        audioFile(filename: "valid.aac", format: "aac")
    }
    
    /// Get path to a valid WAV file
    static func sampleWAV() -> URL? {
        audioFile(filename: "valid.wav", format: "wav")
    }
    
    /// Get path to a valid M4A file
    static func sampleM4A() -> URL? {
        audioFile(filename: "valid.m4a", format: "m4a")
    }
    
    /// Get path to a valid OGG file
    static func sampleOGG() -> URL? {
        audioFile(filename: "valid.ogg", format: "ogg")
    }
    
    /// Get path to a valid Opus file
    static func sampleOpus() -> URL? {
        audioFile(filename: "valid.opus", format: "opus")
    }
    
    /// Get path to a valid ALAC file
    static func sampleALAC() -> URL? {
        audioFile(filename: "valid.alac", format: "alac")
    }
    
    /// Get path to a valid APE file
    static func sampleAPE() -> URL? {
        audioFile(filename: "valid.ape", format: "ape")
    }
    
    /// Get path to a valid AIFF file
    static func sampleAIFF() -> URL? {
        audioFile(filename: "valid.aiff", format: "aiff")
    }
    
    /// Get path to a valid CAF file
    static func sampleCAF() -> URL? {
        audioFile(filename: "valid.caf", format: "caf")
    }
    
    /// Get path to a valid MP4 file
    static func sampleMP4() -> URL? {
        audioFile(filename: "valid.mp4", format: "mp4")
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
    
    // MARK: - Invalid/Corrupt File Fixtures
    
    /// Get path to an invalid empty file
    /// - Parameters:
    ///   - format: Audio format (mp3, flac, aac, etc.)
    /// - Returns: URL to the invalid empty file, or nil if not found
    static func invalidEmptyFile(format: String) -> URL? {
        audioFile(filename: "invalid_empty.\(format)", format: format)
    }
    
    /// Get path to an invalid header file
    /// - Parameters:
    ///   - format: Audio format (mp3, flac, aac, etc.)
    /// - Returns: URL to the invalid header file, or nil if not found
    static func invalidHeaderFile(format: String) -> URL? {
        audioFile(filename: "invalid_header.\(format)", format: format)
    }
    
    /// Get path to a truncated file
    /// - Parameters:
    ///   - format: Audio format (mp3, flac, aac, etc.)
    /// - Returns: URL to the truncated file, or nil if not found
    static func truncatedFile(format: String) -> URL? {
        audioFile(filename: "invalid_truncated.\(format)", format: format)
    }
    
    /// Get path to a zero-size file
    /// - Parameters:
    ///   - format: Audio format (mp3, flac, aac, etc.)
    /// - Returns: URL to the zero-size file, or nil if not found
    static func zeroSizeFile(format: String) -> URL? {
        audioFile(filename: "invalid_zero_size.\(format)", format: format)
    }
    
    /// Get path to a file with no audio data (header only)
    /// - Parameters:
    ///   - format: Audio format (mp3, flac, aac, etc.)
    /// - Returns: URL to the no-audio-data file, or nil if not found
    static func noAudioDataFile(format: String) -> URL? {
        audioFile(filename: "invalid_no_audio_data.\(format)", format: format)
    }
    
    /// Get path to a corrupt payload file (valid header, corrupted data)
    /// - Parameters:
    ///   - format: Audio format (mp3, flac, aac, etc.)
    /// - Returns: URL to the corrupt payload file, or nil if not found
    static func corruptPayloadFile(format: String) -> URL? {
        audioFile(filename: "corrupt_payload.\(format)", format: format)
    }
    
    /// Get path to a corrupt magic bytes file
    /// - Parameters:
    ///   - format: Audio format (mp3, flac, aac, etc.)
    /// - Returns: URL to the corrupt magic file, or nil if not found
    static func corruptMagicFile(format: String) -> URL? {
        audioFile(filename: "corrupt_magic.\(format)", format: format)
    }
    
    /// Get path to a corrupt middle file (byte corruption in middle)
    /// - Parameters:
    ///   - format: Audio format (mp3, flac, aac, etc.)
    /// - Returns: URL to the corrupt middle file, or nil if not found
    static func corruptMiddleFile(format: String) -> URL? {
        audioFile(filename: "corrupt_middle.\(format)", format: format)
    }
    
    /// Get all invalid/corrupt file types for a format
    /// - Parameter format: Audio format (mp3, flac, aac, etc.)
    /// - Returns: Array of tuples (type, URL) for all available invalid/corrupt files
    static func allInvalidFiles(for format: String) -> [(type: String, url: URL)] {
        var files: [(type: String, url: URL)] = []
        
        if let url = invalidEmptyFile(format: format) { files.append(("invalid_empty", url)) }
        if let url = invalidHeaderFile(format: format) { files.append(("invalid_header", url)) }
        if let url = truncatedFile(format: format) { files.append(("invalid_truncated", url)) }
        if let url = zeroSizeFile(format: format) { files.append(("invalid_zero_size", url)) }
        if let url = noAudioDataFile(format: format) { files.append(("invalid_no_audio_data", url)) }
        if let url = corruptPayloadFile(format: format) { files.append(("corrupt_payload", url)) }
        if let url = corruptMagicFile(format: format) { files.append(("corrupt_magic", url)) }
        if let url = corruptMiddleFile(format: format) { files.append(("corrupt_middle", url)) }
        
        return files
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
