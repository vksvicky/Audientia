//
//  DeviceSyncComposer.swift
//  DataLayer
//
//  Factory for building a production-ready DeviceSyncManager.
//

import Foundation
import Shared

public struct DeviceSyncEnvironment {
    public let manager: DeviceSyncManager
    public let trackProvider: DeviceSyncTrackProvider
    public let transcodeEngine: TranscodeEngineProtocol
    public let transcodeQueue: TranscodeQueueProtocol
}

public enum DeviceSyncComposer {
    public static func makeDefaultEnvironment() -> DeviceSyncEnvironment {
        makeEnvironment(usePersistentQueue: false)
    }
    
    public static func makeEnvironment(
        usePersistentQueue: Bool,
        connectorType: DeviceConnectorType = .auto
    ) -> DeviceSyncEnvironment {
        let discovery = DeviceDiscoveryService()
        let connector: DeviceConnectorProtocol = makeConnector(for: connectorType)
        let queue: SyncJobQueueProtocol
        if usePersistentQueue {
            let dbURL = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first?.appendingPathComponent("Audientia").appendingPathComponent("sync_queue.db")
            
            if let dbURL = dbURL {
                try? FileManager.default.createDirectory(
                    at: dbURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                queue = PersistentSyncJobQueue(databaseURL: dbURL)
            } else {
                queue = InMemorySyncJobQueue()
            }
        } else {
            queue = InMemorySyncJobQueue()
        }
        let conflictDetector = BasicSyncConflictDetector()
        
        // Create transcoding engine and queue
        let transcodeEngine = FFmpegTranscodeEngine()
        let transcodeQueue = TranscodeQueue(engine: transcodeEngine)
        
        let manager = DeviceSyncManager(
            discovery: discovery,
            connector: connector,
            queue: queue,
            conflictDetector: conflictDetector,
            transcodeEngine: transcodeEngine,
            transcodeQueue: transcodeQueue
        )
        
        // Restore jobs from persistent queue if using one
        if usePersistentQueue {
            Task {
                await manager.restoreJobsFromQueue()
            }
        }
        
        let trackProvider = DeviceSyncTrackProvider()
        return DeviceSyncEnvironment(
            manager: manager,
            trackProvider: trackProvider,
            transcodeEngine: transcodeEngine,
            transcodeQueue: transcodeQueue
        )
    }
    
    public static func makeDefaultManager() -> DeviceSyncManager {
        makeDefaultEnvironment().manager
    }
    
    public static func makeManager(usePersistentQueue: Bool) -> DeviceSyncManager {
        makeEnvironment(usePersistentQueue: usePersistentQueue).manager
    }
    
    public static func makeDefaultTrackProvider() -> DeviceSyncTrackProvider {
        makeDefaultEnvironment().trackProvider
    }
    
    // MARK: - Connector Factory
    
    public enum DeviceConnectorType {
        case auto
        case local
        case usb
        case mtp
        case smb
    }
    
    private static func makeConnector(for type: DeviceConnectorType) -> DeviceConnectorProtocol {
        switch type {
        case .auto, .local:
            return LocalDeviceConnector()
        case .usb:
            return USBDeviceConnector()
        case .mtp:
            return MTPDeviceConnector()
        case .smb:
            return SMBDeviceConnector()
        }
    }
}
