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
}

public enum DeviceSyncComposer {
    public static func makeDefaultEnvironment() -> DeviceSyncEnvironment {
        let discovery = DeviceDiscoveryService()
        let connector = LocalDeviceConnector()
        let queue = InMemorySyncJobQueue()
        let conflictDetector = BasicSyncConflictDetector()
        let manager = DeviceSyncManager(
            discovery: discovery,
            connector: connector,
            queue: queue,
            conflictDetector: conflictDetector
        )
        let trackProvider = DeviceSyncTrackProvider()
        return DeviceSyncEnvironment(manager: manager, trackProvider: trackProvider)
    }
    
    public static func makeDefaultManager() -> DeviceSyncManager {
        makeDefaultEnvironment().manager
    }
    
    public static func makeDefaultTrackProvider() -> DeviceSyncTrackProvider {
        makeDefaultEnvironment().trackProvider
    }
}
