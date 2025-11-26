//
//  TrackSelectionStore.swift
//  Audientia
//
//  Shared state object for coordinating selected track between panes
//

import Shared
import SwiftUI

/// Observable store for tracking the currently focused track across UI panes.
/// Multi-pane layout injects this store so Library, Playlist, and Track Details
/// can react to the same selection.
@MainActor
public final class TrackSelectionStore: ObservableObject {
    @Published public private(set) var selectedTrack: Track?

    public init() {}

    /// Update the currently selected track.
    public func select(_ track: Track?) {
        selectedTrack = track
    }

    /// Clear the current selection.
    public func clear() {
        selectedTrack = nil
    }
}
