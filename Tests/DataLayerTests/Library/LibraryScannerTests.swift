@testable import DataLayer
import Foundation
import Testing

@Suite("LibraryScanner")
struct LibraryScannerTests {

    private func makeTempDirectory() throws -> URL {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let dir = tempRoot.appendingPathComponent("LibraryScannerTests_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func writeDummyFile(at url: URL) throws {
        let data = Data("test".utf8)
        try data.write(to: url)
    }

    @Test("Scans only supported audio extensions")
    func testScansOnlySupportedExtensions() async throws {
        let root = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        // Files at root
        let mp3 = root.appendingPathComponent("song1.mp3")
        let flac = root.appendingPathComponent("track2.flac")
        let txt = root.appendingPathComponent("notes.txt")
        let hidden = root.appendingPathComponent(".hidden.m4a")

        try writeDummyFile(at: mp3)
        try writeDummyFile(at: flac)
        try writeDummyFile(at: txt)
        try writeDummyFile(at: hidden)

        // Nested dir
        let subdir = root.appendingPathComponent("Sub", isDirectory: true)
        try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)
        let m4a = subdir.appendingPathComponent("inside.m4a")
        let jpg = subdir.appendingPathComponent("image.jpg")
        try writeDummyFile(at: m4a)
        try writeDummyFile(at: jpg)

        let scanner = LibraryScanner()
        let tracks = try await scanner.scan(directory: root)

        // Expect only mp3, flac, m4a (hidden file should be skipped by enumerator options)
        #expect(tracks.count == 3, "Expected 3 supported audio files, got \(tracks.count)")
        let paths = Set(tracks.map { URL(fileURLWithPath: $0.filePath).lastPathComponent })
        #expect(paths.contains("song1.mp3"))
        #expect(paths.contains("track2.flac"))
        #expect(paths.contains("inside.m4a"))
        #expect(!paths.contains(".hidden.m4a"))
        #expect(!paths.contains("notes.txt"))
        #expect(!paths.contains("image.jpg"))

        // Basic fallback metadata checks
        let titles = Set(tracks.map { $0.title })
        #expect(titles.contains("song1"))
        #expect(titles.contains("track2"))
        #expect(titles.contains("inside"))
        let rootResolved = root.resolvingSymlinksInPath().path
        for track in tracks {
            #expect(track.artist == "Unknown Artist")
            #expect(track.album == "Unknown Album")
            #expect(track.duration == 0.0)
            #expect(track.bitrate == 0)
            #expect(track.sampleRate == 0)
            let trackPath = URL(fileURLWithPath: track.filePath).resolvingSymlinksInPath().path
            #expect(trackPath.hasPrefix(rootResolved))
        }
    }

    @Test("Scans nested directories recursively")
    func testScansNestedDirectories() async throws {
        let root = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        // Create nested directories
        let level1 = root.appendingPathComponent("Level1", isDirectory: true)
        let level2 = level1.appendingPathComponent("Level2", isDirectory: true)
        try FileManager.default.createDirectory(at: level2, withIntermediateDirectories: true)

        let l1file = level1.appendingPathComponent("a.mp3")
        let l2file = level2.appendingPathComponent("b.m4a")
        try writeDummyFile(at: l1file)
        try writeDummyFile(at: l2file)

        let scanner = LibraryScanner()
        let tracks = try await scanner.scan(directory: root)

        let names = Set(tracks.map { URL(fileURLWithPath: $0.filePath).lastPathComponent })
        #expect(names == ["a.mp3", "b.m4a"])
    }

    @Test("Throws directoryNotFound for missing directory")
    func testDirectoryNotFound() async throws {
        let missing = URL(fileURLWithPath: "/this/path/should/not/exist/\(UUID().uuidString)", isDirectory: true)

        let scanner = LibraryScanner()
        do {
            _ = try await scanner.scan(directory: missing)
            Issue.record("Expected to throw LibraryScannerError.directoryNotFound")
        } catch {
            if let err = error as? LibraryScannerError {
                #expect(err == .directoryNotFound)
            } else {
                Issue.record("Unexpected error: \(error)")
            }
        }
    }
}
