//
//  AudioEngineNativeBridgeTests.swift
//  AudioCoreTests
//
//  Verifies that the high-level AudioEngine delegates playback work to the native bridge.
//

@testable import AudioCore
@testable import Shared
import XCTest

@MainActor
final class AudioEngineNativeBridgeTests: XCTestCase {
    func testLoadTrackDelegatesToNativeEngine() async throws {
        // Given
        let track = MockFactory.makeTrack(filePath: "/tmp/native-bridge.mp3")
        let fileSystem = MockFileSystem()
        fileSystem.addFile(track.filePath)
        let nativeEngine = MockNativeAudioEngine()
        nativeEngine.nextLoadDuration = track.duration
        let formatCoordinator = MockFormatDecodingCoordinator()
        let engine = AudioEngine(
            fileSystem: fileSystem,
            formatCoordinator: formatCoordinator,
            nativeEngine: nativeEngine
        )

        // When
        try await engine.loadTrack(track)

        // Then
        XCTAssertEqual(nativeEngine.loadFileCalls, [track.filePath])
        XCTAssertEqual(engine.state, .stopped)
    }

    func testPlayPauseAndStopDelegateToNativeEngine() async throws {
        // Given
        let track = MockFactory.makeTrack(filePath: "/tmp/native-play.mp3")
        let fileSystem = MockFileSystem()
        fileSystem.addFile(track.filePath)
        let nativeEngine = MockNativeAudioEngine()
        nativeEngine.nextLoadDuration = track.duration
        let engine = AudioEngine(
            fileSystem: fileSystem,
            formatCoordinator: MockFormatDecodingCoordinator(),
            nativeEngine: nativeEngine
        )

        try await engine.loadTrack(track)

        // When
        try await engine.play()
        await engine.pause()
        await engine.stop()

        // Then
        XCTAssertEqual(nativeEngine.playCallCount, 1)
        XCTAssertEqual(nativeEngine.pauseCallCount, 1)
        XCTAssertEqual(nativeEngine.stopCallCount, 1)
    }

    func testPauseDelegatesToNativeEngine() async throws {
        let fixture = try await makePlayingEngine(title: "PauseTrack")

        await fixture.engine.pause()

        XCTAssertEqual(fixture.nativeEngine.pauseCallCount, 1)
        XCTAssertEqual(fixture.engine.state, .paused)
    }

    func testResumeDelegatesToNativeEngine() async throws {
        let fixture = try await makePlayingEngine(title: "ResumeTrack")
        await fixture.engine.pause()
        let initialPlayCount = fixture.nativeEngine.playCallCount

        try await fixture.engine.resume()

        XCTAssertEqual(fixture.nativeEngine.playCallCount, initialPlayCount + 1)
        XCTAssertEqual(fixture.engine.state, .playing)
    }

    func testSkipForwardUsesNativeSeek() async throws {
        let fixture = try await makePlayingEngine(title: "SkipForward", duration: 120)
        try await fixture.engine.seek(to: 5)
        fixture.nativeEngine.seekCalls.removeAll()

        try await fixture.engine.skipForward(seconds: 10)

        XCTAssertEqual(fixture.nativeEngine.seekCalls.last, 15)
    }

    func testSkipForwardClampsToDuration() async throws {
        let fixture = try await makePlayingEngine(title: "SkipForwardClamp", duration: 20)
        try await fixture.engine.seek(to: 15)
        fixture.nativeEngine.seekCalls.removeAll()

        try await fixture.engine.skipForward(seconds: 10)

        XCTAssertEqual(fixture.nativeEngine.seekCalls.last, fixture.nativeEngine.duration)
    }

    func testSkipBackwardUsesNativeSeek() async throws {
        let fixture = try await makePlayingEngine(title: "SkipBackward", duration: 60)
        try await fixture.engine.seek(to: 5)
        fixture.nativeEngine.seekCalls.removeAll()

        try await fixture.engine.skipBackward(seconds: 10)

        XCTAssertEqual(fixture.nativeEngine.seekCalls.last, 0)
    }

    func testSeekWhilePlayingKeepsStateAndCallsNativeEngine() async throws {
        let fixture = try await makePlayingEngine(title: "SeekDuringPlayback", duration: 90)
        fixture.nativeEngine.seekCalls.removeAll()

        try await fixture.engine.seek(to: 42)

        XCTAssertEqual(fixture.nativeEngine.seekCalls.last, 42)
        XCTAssertEqual(fixture.engine.state, .playing)
    }

    func testSeekClampsToDuration() async throws {
        let fixture = try await makePlayingEngine(title: "SeekClamp", duration: 30)
        fixture.nativeEngine.seekCalls.removeAll()

        try await fixture.engine.seek(to: 999)

        XCTAssertEqual(fixture.nativeEngine.seekCalls.last, fixture.nativeEngine.duration)
    }

    func testReplayFromPausedResetsPositionAndResumesPlayback() async throws {
        let fixture = try await makePlayingEngine(title: "ReplayTrack", duration: 45)
        await fixture.engine.pause()
        fixture.nativeEngine.seekCalls.removeAll()
        let initialPlayCount = fixture.nativeEngine.playCallCount

        try await fixture.engine.replay()

        XCTAssertEqual(fixture.nativeEngine.seekCalls.last, 0)
        XCTAssertEqual(fixture.nativeEngine.playCallCount, initialPlayCount + 1)
        XCTAssertEqual(fixture.engine.state, .playing)
    }

    func testTrackLoopModeReplaysCurrentTrack() async throws {
        let fixture = try await makePlayingEngine(title: "LoopTrack", duration: 1)
        fixture.engine.setLoopMode(.track)
        fixture.nativeEngine.seekCalls.removeAll()

        await simulateCompletion(nativeEngine: fixture.nativeEngine)

        XCTAssertTrue(fixture.nativeEngine.seekCalls.contains(0))
        XCTAssertEqual(fixture.engine.state, .playing)
    }

    func testQueueLoopModeRestartsPlaylistAfterFinalTrack() async throws {
        let track1 = MockFactory.makeTrack(title: "QueueLoop1", duration: 1.0, filePath: "/tmp/loop1.mp3")
        let track2 = MockFactory.makeTrack(title: "QueueLoop2", duration: 1.0, filePath: "/tmp/loop2.mp3")

        let fileSystem = MockFileSystem()
        [track1, track2].forEach { fileSystem.addFile($0.filePath) }
        let nativeEngine = MockNativeAudioEngine()
        nativeEngine.duration = 1.0
        nativeEngine.nextLoadDuration = 1.0

        let engine = AudioEngine(
            fileSystem: fileSystem,
            formatCoordinator: MockFormatDecodingCoordinator(),
            nativeEngine: nativeEngine
        )

        engine.setLoopMode(.queue)
        engine.addToQueue(track1)
        engine.addToQueue(track2)

        try await engine.play()

        // Completion for track 1 -> should advance to track 2, not loop yet
        nativeEngine.nextLoadDuration = track2.duration
        await simulateCompletion(nativeEngine: nativeEngine)
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(engine.currentTrack?.id, track2.id)

        // Completion for track 2 -> queue empty, should loop to first track
        nativeEngine.nextLoadDuration = track1.duration
        await simulateCompletion(nativeEngine: nativeEngine)
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(engine.currentTrack?.id, track1.id)
    }
}

// MARK: - Helpers

private struct EngineTestFixture {
    let engine: AudioEngine
    let nativeEngine: MockNativeAudioEngine
    let track: Track
}

private extension AudioEngineNativeBridgeTests {
    func makeLoadedEngine(
        title: String,
        duration: TimeInterval,
        path: String
    ) async throws -> EngineTestFixture {
        let track = MockFactory.makeTrack(title: title, duration: duration, filePath: path)
        let fileSystem = MockFileSystem()
        fileSystem.addFile(track.filePath)
        let nativeEngine = MockNativeAudioEngine()
        nativeEngine.duration = duration
        nativeEngine.nextLoadDuration = duration
        let engine = AudioEngine(
            fileSystem: fileSystem,
            formatCoordinator: MockFormatDecodingCoordinator(),
            nativeEngine: nativeEngine
        )
        try await engine.loadTrack(track)
        return EngineTestFixture(engine: engine, nativeEngine: nativeEngine, track: track)
    }

    func makePlayingEngine(
        title: String,
        duration: TimeInterval = 120
    ) async throws -> EngineTestFixture {
        let fixture = try await makeLoadedEngine(
            title: title,
            duration: duration,
            path: "/tmp/\(UUID()).mp3"
        )
        try await fixture.engine.play()
        return fixture
    }

    func simulateCompletion(nativeEngine: MockNativeAudioEngine) async {
        nativeEngine.currentPosition = nativeEngine.duration
        try? await Task.sleep(nanoseconds: 300_000_000)
    }

    // MARK: - Single Track Completion Tests

    /// BDD: Given a single track playing with loop mode off, when the track completes, then playback should stop (not replay)
    func testSingleTrackStopsOnCompletionWhenLoopModeOff() async throws {
        // Given - A single track loaded and playing with loop mode off
        let track = MockFactory.makeTrack(
            title: "Single Track",
            duration: 10.0,
            filePath: "/tmp/single-track.mp3"
        )
        let fileSystem = MockFileSystem()
        fileSystem.addFile(track.filePath)
        let nativeEngine = MockNativeAudioEngine()
        nativeEngine.duration = 10.0
        nativeEngine.nextLoadDuration = 10.0
        let engine = AudioEngine(
            fileSystem: fileSystem,
            formatCoordinator: MockFormatDecodingCoordinator(),
            nativeEngine: nativeEngine
        )

        // Add track to queue and load it
        engine.addToQueue(track)
        try await engine.loadTrack(track)
        try await engine.play()
        engine.setLoopMode(.none) // Explicitly set loop mode to none

        XCTAssertEqual(engine.state, .playing, "Should be playing")
        XCTAssertEqual(engine.queue.count, 1, "Queue should have 1 track")
        let initialLoadCount = nativeEngine.loadFileCalls.count

        // When - Track completes (simulate reaching end)
        nativeEngine.currentPosition = 10.0
        // Wait for position tracking to detect completion (position update interval is typically 100-200ms)
        try? await Task.sleep(nanoseconds: 500_000_000) // 500ms to ensure position tracking runs

        // Then - Playback should stop (not replay the same track)
        // The track should not be reloaded
        XCTAssertEqual(nativeEngine.loadFileCalls.count, initialLoadCount, "Track should only be loaded once, not reloaded")
        XCTAssertEqual(engine.state, .stopped, "Playback should stop when single track completes with loop mode off")
    }

    /// BDD: Given a single track playing with loop mode track, when the track completes, then it should replay
    func testSingleTrackReplaysOnCompletionWhenLoopModeTrack() async throws {
        // Given - A single track loaded and playing with loop mode track
        let track = MockFactory.makeTrack(
            title: "Single Track",
            duration: 10.0,
            filePath: "/tmp/single-track.mp3"
        )
        let fileSystem = MockFileSystem()
        fileSystem.addFile(track.filePath)
        let nativeEngine = MockNativeAudioEngine()
        nativeEngine.duration = 10.0
        nativeEngine.nextLoadDuration = 10.0
        let engine = AudioEngine(
            fileSystem: fileSystem,
            formatCoordinator: MockFormatDecodingCoordinator(),
            nativeEngine: nativeEngine
        )

        // Add track to queue and load it
        engine.addToQueue(track)
        try await engine.loadTrack(track)
        try await engine.play()
        engine.setLoopMode(.track) // Set loop mode to track

        XCTAssertEqual(engine.state, .playing, "Should be playing")

        // When - Track completes (simulate reaching end)
        nativeEngine.currentPosition = 10.0
        // Wait for position tracking to detect completion
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

        // Then - Track should replay (loop mode should handle it)
        // Loop mode handling happens before normal completion, so we check that replay was called
        // The replay() method calls seek(to: 0.0) and play(), which we can verify
        XCTAssertGreaterThanOrEqual(nativeEngine.seekCalls.count, 1, "Should seek to beginning for replay")
    }
}
