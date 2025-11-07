// FormatDecoderCoordinatorTests.swift
// AudioCoreTests
//
// BDD/TDD coverage for format decoder coordination with mocking
//

@testable import AudioCore
import Foundation
import XCTest

/// BDD-style tests for the format decoder coordination layer
/// Ensures TDD + Right-BICEP coverage with mocking
final class FormatDecoderCoordinatorTests: XCTestCase {

    // MARK: - Test Doubles

    private final class MockFormatDecoder: FormatDecoder {
        enum Behaviour {
            case success(DecodedAudioFormat)
            case failure(Error)
        }

        let name: String
        let supportedExtensions: Set<String>
        var behaviour: Behaviour
        private(set) var canDecodeCallCount = 0
        private(set) var decodeCallCount = 0

        init(name: String, supportedExtensions: Set<String>, behaviour: Behaviour) {
            self.name = name
            self.supportedExtensions = supportedExtensions
            self.behaviour = behaviour
        }

        func canDecode(filePath: String) -> Bool {
            canDecodeCallCount += 1
            let fileExtension = URL(fileURLWithPath: filePath).pathExtension.lowercased()
            return supportedExtensions.contains(fileExtension)
        }

        func decode(filePath: String) throws -> DecodedAudioFormat {
            decodeCallCount += 1
            switch behaviour {
            case let .success(format):
                return format
            case let .failure(error):
                throw error
            }
        }
    }

    // MARK: - Helpers

    private func makeCoordinator(decoders: [FormatDecoder]) -> FormatDecodingCoordinating {
        DefaultFormatDecodingCoordinator(decoders: decoders)
    }

    private let sampleMP3Path = "/tmp/sample.mp3"
    private let sampleFLACPath = "/tmp/sample.flac"

    private let defaultFormat = DecodedAudioFormat(
        codec: "MockMP3",
        sampleRate: 44_100,
        channelCount: 2,
        bitRate: 320,
        duration: 180
    )

    // MARK: - Tests

    /// Given multiple decoders, when the first supports the file, then it should be selected
    func testSelectsFirstSupportingDecoder() throws {
        // Given
        let primary = MockFormatDecoder(
            name: "Primary",
            supportedExtensions: ["mp3"],
            behaviour: .success(defaultFormat)
        )
        let secondary = MockFormatDecoder(
            name: "Secondary",
            supportedExtensions: ["flac"],
            behaviour: .failure(TestError.unexpected)
        )
        let coordinator = makeCoordinator(decoders: [primary, secondary])

        // When
        let format = try coordinator.decodeFormat(for: sampleMP3Path)

        // Then (Right-BICEP: Right, Performance - call counts kept minimal)
        XCTAssertEqual(format, defaultFormat, "Should return the format produced by the first decoder")
        XCTAssertEqual(primary.decodeCallCount, 1, "Primary decoder should be used once")
        XCTAssertEqual(secondary.decodeCallCount, 0, "Secondary decoder should not be invoked")
    }

    /// Given the first decoder supports but fails, when decoding, then fall back to the next decoder
    func testFallsBackWhenPrimaryDecoderFails() throws {
        // Given
        let failingFormatError = FormatDecoderError.decoderFailed(decoder: "Primary", reason: "Mock failure")
        let primary = MockFormatDecoder(
            name: "Primary",
            supportedExtensions: ["mp3"],
            behaviour: .failure(failingFormatError)
        )
        let expectedFormat = DecodedAudioFormat(
            codec: "MockFLAC",
            sampleRate: 96_000,
            channelCount: 2,
            bitRate: 1_000,
            duration: 240
        )
        let secondary = MockFormatDecoder(
            name: "Secondary",
            supportedExtensions: ["mp3", "flac"],
            behaviour: .success(expectedFormat)
        )
        let coordinator = makeCoordinator(decoders: [primary, secondary])

        // When
        let format = try coordinator.decodeFormat(for: sampleMP3Path)

        // Then (Right-BICEP: Error handling, Cross-check via fallback)
        XCTAssertEqual(format, expectedFormat, "Fallback decoder should provide the format")
        XCTAssertEqual(primary.decodeCallCount, 1, "Primary decoder should be attempted once")
        XCTAssertEqual(secondary.decodeCallCount, 1, "Secondary decoder should be attempted once after failure")
    }

    /// Given no decoder can handle the file, when decoding, then throw .noDecoderAvailable
    func testThrowsWhenNoDecoderCanHandleFile() {
        // Given
        let primary = MockFormatDecoder(
            name: "Primary",
            supportedExtensions: ["aac"],
            behaviour: .failure(TestError.unexpected)
        )
        let secondary = MockFormatDecoder(
            name: "Secondary",
            supportedExtensions: ["wav"],
            behaviour: .failure(TestError.unexpected)
        )
        let coordinator = makeCoordinator(decoders: [primary, secondary])

        // When
        XCTAssertThrowsError(try coordinator.decodeFormat(for: sampleFLACPath)) { error in
            // Then (Right-BICEP: Error path)
            guard case FormatDecoderError.noDecoderAvailable(let attempted, _) = error else {
                XCTFail("Expected noDecoderAvailable error, got \(error)")
                return
            }
            XCTAssertEqual(attempted, ["Primary", "Secondary"], "Should report attempted decoders in order")
        }
    }
}

// MARK: - Test Scaffolding

private enum TestError: Error {
    case unexpected
}
