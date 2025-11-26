//
//  TrackArtwork.swift
//  Shared
//
//  Represents artwork data associated with a track.
//

import Foundation

public struct TrackArtwork: Equatable, Sendable {
    public enum Source: Equatable, Sendable {
        case sidecar(url: URL)
        case embedded
    }

    public let data: Data
    public let mimeType: String
    public let source: Source

    public init(data: Data, mimeType: String, source: Source) {
        self.data = data
        self.mimeType = mimeType
        self.source = source
    }
}
