//
//  MP4ParserTests.swift
//  MetadataEngineTests
//
//  TDD tests for MP4/M4A tag parser
//  Following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for MP4Parser
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class MP4ParserTests: XCTestCase {
    
    var parser: MP4Parser!
    
    override func setUp() async throws {
        try await super.setUp()
        parser = MP4Parser()
    }
    
    override func tearDown() async throws {
        parser = nil
        try await super.tearDown()
    }
    
    // MARK: - Right: Are the Results Right?
    
    /// Test that MP4 parser supports MP4 and M4A files
    func testMP4ParserSupportsMP4AndM4AFiles() {
        // Given - MP4 and M4A file extensions
        let mp4URL = URL(fileURLWithPath: "/test/song.mp4")
        let m4aURL = URL(fileURLWithPath: "/test/song.m4a")
        
        // When - Check if parser can handle them
        let canParseMP4 = parser.canParse(fileURL: mp4URL)
        let canParseM4A = parser.canParse(fileURL: m4aURL)
        
        // Then - Should support both
        XCTAssertTrue(canParseMP4, "MP4 parser should support MP4 files")
        XCTAssertTrue(canParseM4A, "MP4 parser should support M4A files")
        XCTAssertTrue(parser.supportedExtensions.contains("mp4"), "Supported extensions should include mp4")
        XCTAssertTrue(parser.supportedExtensions.contains("m4a"), "Supported extensions should include m4a")
    }
    
    /// Test that MP4 parser does not support non-MP4 files
    func testMP4ParserDoesNotSupportNonMP4Files() {
        // Given - Non-MP4 file extensions
        let mp3URL = URL(fileURLWithPath: "/test/song.mp3")
        let flacURL = URL(fileURLWithPath: "/test/song.flac")
        
        // When - Check if parser can handle them
        let canParseMP3 = parser.canParse(fileURL: mp3URL)
        let canParseFLAC = parser.canParse(fileURL: flacURL)
        
        // Then - Should not support them
        XCTAssertFalse(canParseMP3, "MP4 parser should not support MP3 files")
        XCTAssertFalse(canParseFLAC, "MP4 parser should not support FLAC files")
    }
    
    /// Test parsing a valid MP4 file with common metadata atoms
    func testParseValidMP4FileWithCommonMetadata() async throws {
        // Given - A mock MP4 file with metadata atoms
        let fileURL = createMockMP4File(
            atoms: [
                "©nam": "Test Title",
                "©ART": "Test Artist",
                "©alb": "Test Album",
                "©day": "2023",
                "trkn": Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x05, 0x00, 0x0C]), // Track 5 of 12
                "disk": Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x02]), // Disc 1 of 2
                "©gen": "Pop"
            ]
        )
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When - Parse the file
        let track = try await parser.parse(fileURL: fileURL)
        
        // Then - Metadata should be correctly extracted
        XCTAssertNotNil(track)
        XCTAssertEqual(track?.title, "Test Title")
        XCTAssertEqual(track?.artist, "Test Artist")
        XCTAssertEqual(track?.album, "Test Album")
        XCTAssertEqual(track?.year, 2023)
        XCTAssertEqual(track?.trackNumber, 5)
        XCTAssertEqual(track?.discNumber, 1)
        XCTAssertEqual(track?.genre, "Pop")
    }
    
    /// Test parsing a file with no MP4 metadata
    func testParseFileWithNoMP4Metadata() async throws {
        // Given - A mock MP4 file with no metadata atoms (just ftyp and minimal structure)
        let fileURL = createMockMP4File(atoms: [:])
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When - Parse the file
        let track = try await parser.parse(fileURL: fileURL)
        
        // Then - Should return nil as no metadata is present
        XCTAssertNil(track, "Should return nil if no MP4 metadata is found")
    }
    
    // MARK: - Boundary Conditions
    
    /// Test parsing an empty file
    func testParseEmptyFile() async {
        // Given - An empty file
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("empty.mp4")
        FileManager.default.createFile(atPath: fileURL.path, contents: Data())
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When - Parse the empty file
        do {
            _ = try await parser.parse(fileURL: fileURL)
            XCTFail("Parsing an empty file should throw an error")
        } catch let error as TagParserError {
            XCTAssertTrue(
                error.localizedDescription.contains("Invalid") || error.localizedDescription.contains("Corrupted"),
                "Should throw invalid or corrupted tag error"
            )
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    /// Test parsing a file with only ftyp box, no moov box
    func testParseFileWithOnlyFtypBox() async throws {
        // Given - A mock MP4 file with only ftyp box
        let fileURL = createMockMP4FileWithOnlyFtyp()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When - Parse the file
        let track = try await parser.parse(fileURL: fileURL)
        
        // Then - Should return nil as no metadata is present
        XCTAssertNil(track, "Should return nil if no moov box is found")
    }
    
    /// Test parsing with very long metadata values
    func testParseWithVeryLongMetadataValues() async throws {
        // Given - A mock MP4 file with very long metadata
        let longTitle = String(repeating: "A", count: 1000)
        let longArtist = String(repeating: "B", count: 1000)
        let fileURL = createMockMP4File(
            atoms: [
                "©nam": longTitle,
                "©ART": longArtist
            ]
        )
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When - Parse the file
        let track = try await parser.parse(fileURL: fileURL)
        
        // Then - Should extract long metadata correctly
        XCTAssertNotNil(track)
        XCTAssertEqual(track?.title, longTitle)
        XCTAssertEqual(track?.artist, longArtist)
    }
    
    // MARK: - Inverse Relationships
    
    /// Test that parsing twice yields consistent results
    func testParseTwiceYieldsConsistentResults() async throws {
        // Given - A mock MP4 file
        let fileURL = createMockMP4File(
            atoms: ["©nam": "Consistent Song"]
        )
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When - Parse twice
        let track1 = try await parser.parse(fileURL: fileURL)
        let track2 = try await parser.parse(fileURL: fileURL)
        
        // Then - Results should be identical (compare metadata, not IDs since each parse creates a new UUID)
        XCTAssertNotNil(track1, "First parse should succeed")
        XCTAssertNotNil(track2, "Second parse should succeed")
        XCTAssertEqual(track1?.title, track2?.title, "Title should be consistent")
        XCTAssertEqual(track1?.artist, track2?.artist, "Artist should be consistent")
        XCTAssertEqual(track1?.album, track2?.album, "Album should be consistent")
        XCTAssertEqual(track1?.year, track2?.year, "Year should be consistent")
        XCTAssertEqual(track1?.trackNumber, track2?.trackNumber, "Track number should be consistent")
        XCTAssertEqual(track1?.discNumber, track2?.discNumber, "Disc number should be consistent")
        XCTAssertEqual(track1?.genre, track2?.genre, "Genre should be consistent")
    }
    
    // MARK: - Error Conditions
    
    /// Test parsing a non-existent file
    func testParseNonExistentFile() async {
        // Given - A non-existent file URL
        let fileURL = URL(fileURLWithPath: "/path/to/nonexistent/file.mp4")
        
        // When - Attempt to parse
        do {
            _ = try await parser.parse(fileURL: fileURL)
            XCTFail("Parsing a non-existent file should throw fileNotFound error")
        } catch let error as TagParserError {
            XCTAssertEqual(error.localizedDescription, TagParserError.fileNotFound(fileURL).localizedDescription)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    /// Test parsing a corrupted MP4 file (invalid box structure)
    func testParseCorruptedMP4File() async {
        // Given - A file with corrupted box structure
        let fileURL = createCorruptedMP4File(corruptionType: .invalidBoxStructure)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When - Attempt to parse
        do {
            _ = try await parser.parse(fileURL: fileURL)
            XCTFail("Parsing a corrupted MP4 file should throw corruptedTag error")
        } catch let error as TagParserError {
            XCTAssertTrue(
                error.localizedDescription.contains("Corrupted") || error.localizedDescription.contains("Invalid"),
                "Should throw corrupted or invalid tag error"
            )
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    /// Test parsing a file with malformed atom data
    func testParseMalformedAtomData() async {
        // Given - A file with valid structure but malformed atom data
        let fileURL = createCorruptedMP4File(corruptionType: .malformedAtomData)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When - Attempt to parse
        do {
            _ = try await parser.parse(fileURL: fileURL)
            // Should either return nil or throw error gracefully
        } catch {
            // Error is acceptable for malformed data
            XCTAssertTrue(error is TagParserError, "Should throw TagParserError")
        }
    }
    
    // MARK: - Performance Characteristics
    
    /// Test parsing performance for a large file with many tags
    func testParsePerformanceWithManyTags() async throws {
        // Given - A large mock MP4 file with many metadata atoms
        var atoms: [String: Any] = [
            "©nam": String(repeating: "A", count: 500),
            "©ART": String(repeating: "B", count: 500),
            "©alb": String(repeating: "C", count: 500)
        ]
        // Add many additional atoms
        for i in 1...50 {
            atoms["©cmt\(i)"] = String(repeating: "D", count: 100)
        }
        let fileURL = createMockMP4File(atoms: atoms)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When - Parse the file and measure time
        let startTime = Date()
        _ = try await parser.parse(fileURL: fileURL)
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete within reasonable time (e.g., < 1 second)
        XCTAssertLessThan(duration, 1.0, "Parsing should complete within 1 second")
    }
    
    // MARK: - Edge Cases
    
    /// Test parsing with special characters in metadata
    func testParseWithSpecialCharacters() async throws {
        // Given - A mock MP4 file with special characters
        let fileURL = createMockMP4File(
            atoms: [
                "©nam": "Title with special chars: éàüö",
                "©ART": "Artist with special chars: ñç",
                "©alb": "Album with special chars: ß"
            ]
        )
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When - Parse the file
        let track = try await parser.parse(fileURL: fileURL)
        
        // Then - Metadata should be correctly extracted
        XCTAssertNotNil(track)
        XCTAssertEqual(track?.title, "Title with special chars: éàüö")
        XCTAssertEqual(track?.artist, "Artist with special chars: ñç")
        XCTAssertEqual(track?.album, "Album with special chars: ß")
    }
    
    /// Test parsing with empty atom content
    func testParseEmptyAtomContent() async throws {
        // Given - A mock MP4 file with an empty title atom
        let fileURL = createMockMP4File(
            atoms: ["©nam": ""]
        )
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // When - Parse the file
        let track = try await parser.parse(fileURL: fileURL)
        
        // Then - Title should fallback to filename or be empty
        XCTAssertNotNil(track)
        // Empty title is acceptable, or should fallback to filename
    }
    
    /// Test parsing track number with various formats
    func testParseTrackNumberWithVariousFormats() async throws {
        // Given - MP4 files with different track number formats
        let fileURL1 = createMockMP4File(
            atoms: [
                "trkn": Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00]) // Track 1, no total
            ]
        )
        defer { try? FileManager.default.removeItem(at: fileURL1) }
        
        let fileURL2 = createMockMP4File(
            atoms: [
                "trkn": Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x0A, 0x00, 0x14]) // Track 10 of 20
            ]
        )
        defer { try? FileManager.default.removeItem(at: fileURL2) }
        
        // When - Parse both files
        let track1 = try await parser.parse(fileURL: fileURL1)
        let track2 = try await parser.parse(fileURL: fileURL2)
        
        // Then - Track numbers should be correctly extracted
        XCTAssertEqual(track1?.trackNumber, 1)
        XCTAssertEqual(track2?.trackNumber, 10)
    }
    
    // MARK: - Helper Methods for Mock Files
    
    enum CorruptionType {
        case invalidBoxStructure
        case malformedAtomData
    }
    
    /// Creates a mock MP4 file with metadata atoms
    /// - Parameters:
    ///   - atoms: Dictionary of atom names to values (String or Data for binary atoms)
    /// - Returns: URL of the created file
    private func createMockMP4File(atoms: [String: Any]) -> URL {
        let fileName = "mock_mp4_file_\(UUID().uuidString).mp4"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        var mp4Data = createFtypBox()
        let moovData = createMoovBox(with: atoms)
        mp4Data.append(moovData)
        try? mp4Data.write(to: fileURL)
        return fileURL
    }
    
    /// Creates a mock MP4 file with only ftyp box
    private func createMockMP4FileWithOnlyFtyp() -> URL {
        let fileName = "mock_mp4_ftyp_only_\(UUID().uuidString).mp4"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        let mp4Data = createFtypBox()
        try? mp4Data.write(to: fileURL)
        return fileURL
    }
    
    /// Creates a corrupted mock MP4 file for error testing
    private func createCorruptedMP4File(corruptionType: CorruptionType) -> URL {
        let fileName = "corrupted_mp4_file_\(UUID().uuidString).mp4"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        let data = createCorruptedData(corruptionType: corruptionType)
        try? data.write(to: fileURL)
        return fileURL
    }
    
    private func createCorruptedData(corruptionType: CorruptionType) -> Data {
        var data = Data()
        switch corruptionType {
        case .invalidBoxStructure:
            data = createInvalidBoxStructure()
        case .malformedAtomData:
            data = createMalformedAtomData()
        }
        return data
    }
    
    private func createInvalidBoxStructure() -> Data {
        var data = Data()
        data.append(contentsOf: withUnsafeBytes(of: UInt32.max.bigEndian) { Data($0) })
        data.append(Data("ftyp".utf8))
        data.append(Data("mp4 ".utf8))
        return data
    }
    
    private func createMalformedAtomData() -> Data {
        var data = createFtypBox()
        let moovSize: UInt32 = 20
        data.append(contentsOf: withUnsafeBytes(of: moovSize.bigEndian) { Data($0) })
        data.append(Data("moov".utf8))
        data.append(Data([0xFF, 0xFF, 0xFF, 0xFF])) // Invalid size
        return data
    }
}

// MARK: - Helper Methods Extension

private extension MP4ParserTests {
    func createFtypBox() -> Data {
        var ftypData = Data()
        let ftypSize: UInt32 = 32
        ftypData.append(contentsOf: withUnsafeBytes(of: ftypSize.bigEndian) { Data($0) })
        ftypData.append(Data("ftyp".utf8))
        ftypData.append(Data("mp4 ".utf8))
        ftypData.append(Data([0x00, 0x00, 0x00, 0x00]))
        ftypData.append(Data("mp4 ".utf8))
        ftypData.append(Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]))
        return ftypData
    }
    
    func createMoovBox(with atoms: [String: Any]) -> Data {
        let ilstBox = createIlstBox(with: atoms)
        let metaBox = createMetaBox(ilstBox: ilstBox)
        let udtaBox = createUdtaBox(metaBox: metaBox)
        return createBox(type: "moov", content: udtaBox)
    }
    
    func createIlstBox(with atoms: [String: Any]) -> Data {
        var ilstData = Data()
        for (atomName, value) in atoms {
            let atomData = createAtom(name: atomName, value: value)
            ilstData.append(atomData)
        }
        return createBox(type: "ilst", content: ilstData)
    }
    
    func createAtom(name: String, value: Any) -> Data {
        if let stringValue = value as? String {
            return createTextAtom(name: name, text: stringValue)
        } else if let binaryValue = value as? Data {
            return createBinaryAtom(name: name, data: binaryValue)
        }
        return Data()
    }
    
    func createTextAtom(name: String, text: String) -> Data {
        let dataAtom = createTextDataAtom(text: text)
        return createAtomHeader(name: name, content: dataAtom)
    }
    
    func createBinaryAtom(name: String, data: Data) -> Data {
        createAtomHeader(name: name, content: data)
    }
    
    func createAtomHeader(name: String, content: Data) -> Data {
        var atomData = Data()
        let atomSize: UInt32 = UInt32(8 + content.count)
        atomData.append(contentsOf: withUnsafeBytes(of: atomSize.bigEndian) { Data($0) })
        if let atomNameData = name.data(using: .isoLatin1) {
            atomData.append(atomNameData)
        } else {
            atomData.append(Data(name.utf8))
        }
        atomData.append(content)
        return atomData
    }
    
    func createTextDataAtom(text: String) -> Data {
        var dataAtom = Data()
        let textData = text.data(using: .utf8) ?? Data()
        let dataSize: UInt32 = UInt32(16 + textData.count)
        dataAtom.append(contentsOf: withUnsafeBytes(of: dataSize.bigEndian) { Data($0) })
        dataAtom.append(Data("data".utf8))
        dataAtom.append(Data([0x00, 0x00, 0x00, 0x01]))
        dataAtom.append(Data([0x00, 0x00, 0x00, 0x00]))
        dataAtom.append(textData)
        return dataAtom
    }
    
    func createMetaBox(ilstBox: Data) -> Data {
        var metaData = Data()
        let metaSize: UInt32 = UInt32(12 + ilstBox.count)
        metaData.append(contentsOf: withUnsafeBytes(of: metaSize.bigEndian) { Data($0) })
        metaData.append(Data("meta".utf8))
        metaData.append(Data([0x00, 0x00, 0x00, 0x00]))
        metaData.append(ilstBox)
        return metaData
    }
    
    func createUdtaBox(metaBox: Data) -> Data {
        createBox(type: "udta", content: metaBox)
    }
    
    func createBox(type: String, content: Data) -> Data {
        var boxData = Data()
        let boxSize: UInt32 = UInt32(8 + content.count)
        boxData.append(contentsOf: withUnsafeBytes(of: boxSize.bigEndian) { Data($0) })
        boxData.append(Data(type.utf8))
        boxData.append(content)
        return boxData
    }
}
