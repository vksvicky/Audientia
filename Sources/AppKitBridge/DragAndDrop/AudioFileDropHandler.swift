//
//  AudioFileDropHandler.swift
//  AppKitBridge
//
//  Drag-and-drop handler for audio files
//

import AppKit
import Foundation
import Shared
import SwiftUI

/// View modifier for handling audio file drag-and-drop
public struct AudioFileDropHandler: ViewModifier {
    let onFilesDropped: ([URL]) -> Void

    public func body(content: Content) -> some View {
        content.onDrop(of: [.fileURL], isTargeted: nil) { providers in
            var _: [URL] = []
            let group = DispatchGroup()
            var loadedURLs: [URL] = []

            for provider in providers {
                group.enter()
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    defer { group.leave() }
                    if let url = item as? URL {
                        loadedURLs.append(url)
                    } else if let data = item as? Data,
                              let urlString = String(data: data, encoding: .utf8),
                              let url = URL(string: urlString) {
                        loadedURLs.append(url)
                    }
                }
            }

            group.notify(queue: .main) {
                onFilesDropped(loadedURLs)
            }

            return true
        }
    }
}

public extension View {
    /// Handle audio file drag-and-drop
    /// - Parameter onFilesDropped: Callback with dropped file URLs
    /// - Returns: Modified view
    func onAudioFilesDropped(_ onFilesDropped: @escaping ([URL]) -> Void) -> some View {
        modifier(AudioFileDropHandler(onFilesDropped: onFilesDropped))
    }
}
