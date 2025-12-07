//
//  NativeAudioEngineProtocol.swift
//  AudioCore
//
//  Abstraction for the low-level audio playback bridge (CAudioEngine).
//

import Foundation

@MainActor
protocol NativeAudioEngineProtocol: AnyObject {
    var currentPosition: TimeInterval { get }
    var duration: TimeInterval { get }

    func loadFile(_ path: String) async -> Bool
    func play() async -> Bool
    func pause()
    func stop()
    func seek(to position: TimeInterval) async -> Bool
    func setVolume(_ volume: Float)
    func setRate(_ rate: Float)
    func getRate() -> Float
}
