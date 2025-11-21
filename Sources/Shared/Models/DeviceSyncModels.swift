//
//  DeviceSyncModels.swift
//  Shared
//
//  Shared models for Device Sync (Feature 4.1)
//

import Foundation

// MARK: - Device Models

public enum DeviceType: String, Codable, Equatable, Sendable {
    case usb
    case mtp
    case smb
}

public enum DeviceStatus: Equatable, Hashable, Codable, Sendable {
    case ready
    case syncing(progress: Double)
    case disconnected
    case error(String)
}

public struct Device: Identifiable, Hashable, Codable, Sendable {
    public var id: UUID
    public var name: String
    public var type: DeviceType
    public var capacity: Int64
    public var availableSpace: Int64
    public var mountPath: String?
    public var status: DeviceStatus
    
    public init(
        id: UUID = UUID(),
        name: String,
        type: DeviceType,
        capacity: Int64,
        availableSpace: Int64,
        mountPath: String? = nil,
        status: DeviceStatus = .ready
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.capacity = capacity
        self.availableSpace = availableSpace
        self.mountPath = mountPath
        self.status = status
    }
}

// MARK: - Sync Request / Options

public enum SyncDirection: String, Codable, Equatable, Sendable {
    case desktopToDevice
    case deviceToDesktop
    case bidirectional
}

public struct SyncOptions: Codable, Equatable, Sendable {
    public var autoResolveConflicts: Bool
    public var verifyChecksums: Bool
    public var enforceFreeSpace: Bool
    public var deleteMissingFromDevice: Bool
    public var createFolderStructure: Bool
    public var folderStructure: FolderStructure
    
    public init(
        autoResolveConflicts: Bool = true,
        verifyChecksums: Bool = false,
        enforceFreeSpace: Bool = true,
        deleteMissingFromDevice: Bool = false,
        createFolderStructure: Bool = true,
        folderStructure: FolderStructure = .artistAlbum
    ) {
        self.autoResolveConflicts = autoResolveConflicts
        self.verifyChecksums = verifyChecksums
        self.enforceFreeSpace = enforceFreeSpace
        self.deleteMissingFromDevice = deleteMissingFromDevice
        self.createFolderStructure = createFolderStructure
        self.folderStructure = folderStructure
    }
    
    public static let `default` = SyncOptions()
}

public struct SyncRequest: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let device: Device
    public let tracks: [Track]
    public let direction: SyncDirection
    public let options: SyncOptions
    
    public init(
        id: UUID = UUID(),
        device: Device,
        tracks: [Track],
        direction: SyncDirection,
        options: SyncOptions = .default
    ) {
        self.id = id
        self.device = device
        self.tracks = tracks
        self.direction = direction
        self.options = options
    }
}

// MARK: - Sync Progress / Job

public struct SyncProgress: Codable, Equatable, Sendable {
    public var completed: Int
    public var total: Int
    
    public init(completed: Int = 0, total: Int = 0) {
        self.completed = completed
        self.total = total
    }
    
    public var percentage: Double {
        guard total > 0 else { return 0.0 }
        return min(1.0, Double(completed) / Double(total))
    }
}

public enum SyncJobStatus: String, Codable, Equatable, Sendable {
    case queued
    case analyzing
    case waitingForConflictResolution
    case syncing
    case completed
    case failed
    case cancelled
}

public struct SyncJob: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var request: SyncRequest
    public var status: SyncJobStatus
    public var progress: SyncProgress
    public var conflicts: [SyncConflict]?
    public var errorDescription: String?
    
    public init(
        id: UUID = UUID(),
        request: SyncRequest,
        status: SyncJobStatus = .queued,
        progress: SyncProgress = SyncProgress(),
        conflicts: [SyncConflict]? = nil,
        errorDescription: String? = nil
    ) {
        self.id = id
        self.request = request
        self.status = status
        self.progress = progress
        self.conflicts = conflicts
        self.errorDescription = errorDescription
    }
}

// MARK: - Conflicts

public struct SyncConflict: Identifiable, Codable, Equatable, Sendable {
    public enum Reason: String, Codable, Sendable {
        case missingOnDevice
        case changedOnDevice
        case deletedOnDevice
        case insufficientSpace
    }
    
    public let id: UUID
    public let track: Track
    public let reason: Reason
    public let deviceChecksum: String?
    public let libraryChecksum: String?
    
    public init(
        id: UUID = UUID(),
        track: Track,
        reason: Reason,
        deviceChecksum: String? = nil,
        libraryChecksum: String? = nil
    ) {
        self.id = id
        self.track = track
        self.reason = reason
        self.deviceChecksum = deviceChecksum
        self.libraryChecksum = libraryChecksum
    }
}

public struct SyncConflictResolution: Equatable, Sendable {
    public enum Action: String, Sendable {
        case keepLibraryVersion
        case keepDeviceVersion
        case skipTrack
    }
    
    public let conflictId: UUID
    public let action: Action
    
    public init(conflictId: UUID, action: Action) {
        self.conflictId = conflictId
        self.action = action
    }
}

// MARK: - Device Track Snapshot

public struct DeviceTrackSnapshot: Sendable {
    public let track: Track
    public let relativePath: String
    public let libraryChecksum: String?
    public let deviceChecksum: String?
    public let isPresentOnDevice: Bool
    
    public init(
        track: Track,
        relativePath: String,
        libraryChecksum: String?,
        deviceChecksum: String?,
        isPresentOnDevice: Bool
    ) {
        self.track = track
        self.relativePath = relativePath
        self.libraryChecksum = libraryChecksum
        self.deviceChecksum = deviceChecksum
        self.isPresentOnDevice = isPresentOnDevice
    }
}

// MARK: - Errors

public enum DeviceSyncError: LocalizedError, Equatable, Sendable {
    case deviceNotFound
    case deviceDisconnected
    case insufficientSpace
    case transferFailed(String)
    case conflictsPending
    
    public var errorDescription: String? {
        switch self {
        case .deviceNotFound:
            return "Device not found."
        case .deviceDisconnected:
            return "The device disconnected during sync."
        case .insufficientSpace:
            return "The device does not have enough free space."
        case let .transferFailed(reason):
            return reason
        case .conflictsPending:
            return "Conflicts must be resolved before syncing."
        }
    }
}

// MARK: - Device Configuration Types

public enum ConflictResolutionStrategy: String, Codable, CaseIterable, Sendable {
    case keepLibrary = "keep_library"
    case keepDevice = "keep_device"
    case keepNewer = "keep_newer"
    case keepLarger = "keep_larger"
}

public enum FolderStructure: String, Codable, CaseIterable, Sendable {
    case artistAlbum = "artist_album"
    case albumArtist = "album_artist"
    case genreArtistAlbum = "genre_artist_album"
    case flat = "flat"
}

public enum AudioFormat: String, Codable, CaseIterable, Sendable {
    case mp3
    case aac
    case flac
    case original
}
