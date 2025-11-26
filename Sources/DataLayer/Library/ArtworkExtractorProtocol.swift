//
//  ArtworkExtractorProtocol.swift
//  DataLayer
//
//  Defines the contract for extracting artwork data for tracks.
//

import Foundation
import Shared

public protocol ArtworkExtractorProtocol: Sendable {
    func extractArtwork(for track: Track) async -> TrackArtwork?
}
