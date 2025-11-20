//
//  DeviceSyncFixtures.swift
//  DataLayerTests
//
//  Shared builders for Device Sync tests
//

import Foundation

@testable import DataLayer
@testable import Shared

enum DeviceSyncFixtures {
    
    static func usbDevice(
        id: UUID = UUID(),
        name: String = "USB Drive",
        capacity: Int64 = 128 * 1024 * 1024 * 1024,
        available: Int64 = 64 * 1024 * 1024 * 1024
    ) -> Device {
        Device(
            id: id,
            name: name,
            type: .usb,
            capacity: capacity,
            availableSpace: available,
            mountPath: "/Volumes/\(name.replacingOccurrences(of: " ", with: ""))",
            status: .ready
        )
    }
    
    static func tracks(count: Int = 3) -> [Track] {
        (0..<count).map { index in
            Track(
                title: "Track \(index)",
                artist: "Artist \(index)",
                album: "Album",
                duration: 180,
                filePath: "/Music/track\(index).flac",
                fileSize: 5 * 1024 * 1024,
                bitrate: 320,
                sampleRate: 44_100
            )
        }
    }
    
    static func syncRequest(
        device: Device = usbDevice(),
        tracks: [Track] = tracks(),
        direction: SyncDirection = .desktopToDevice,
        options: SyncOptions = .default
    ) -> SyncRequest {
        SyncRequest(
            id: UUID(),
            device: device,
            tracks: tracks,
            direction: direction,
            options: options
        )
    }
    
    static func conflict(track: Track) -> SyncConflict {
        SyncConflict(
            id: UUID(),
            track: track,
            reason: .changedOnDevice,
            deviceChecksum: "device-\(track.id)",
            libraryChecksum: "lib-\(track.id)"
        )
    }
    
    static func snapshot(
        track: Track,
        relativePath: String? = nil,
        libraryChecksum: String? = nil,
        deviceChecksum: String? = nil,
        isPresent: Bool = true
    ) -> DeviceTrackSnapshot {
        DeviceTrackSnapshot(
            track: track,
            relativePath: relativePath ?? "Audientia/\(track.id.uuidString)/\(track.title).flac",
            libraryChecksum: libraryChecksum,
            deviceChecksum: deviceChecksum,
            isPresentOnDevice: isPresent
        )
    }
}
