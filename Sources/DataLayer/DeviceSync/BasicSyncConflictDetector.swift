//
//  BasicSyncConflictDetector.swift
//  DataLayer
//
//  Lightweight conflict detector based on manifest snapshots.
//

import Foundation
import Shared

public actor BasicSyncConflictDetector: SyncConflictDetectorProtocol {
    public init() {}
    
    public func detectConflicts(
        job: SyncJob,
        deviceTracks: [DeviceTrackSnapshot]
    ) async -> [SyncConflict] {
        var conflicts: [SyncConflict] = []
        let snapshotMap = Dictionary(uniqueKeysWithValues: deviceTracks.map { ($0.track.id, $0) })
        
        for track in job.request.tracks {
            guard let snapshot = snapshotMap[track.id] else {
                continue // new track, no previous sync
            }
            
            if snapshot.isPresentOnDevice == false {
                conflicts.append(
                    SyncConflict(
                        track: track,
                        reason: .missingOnDevice,
                        deviceChecksum: snapshot.deviceChecksum,
                        libraryChecksum: snapshot.libraryChecksum
                    )
                )
                continue
            }
            
            if let deviceChecksum = snapshot.deviceChecksum,
               let libraryChecksum = snapshot.libraryChecksum,
               deviceChecksum != libraryChecksum {
                conflicts.append(
                    SyncConflict(
                        track: track,
                        reason: .changedOnDevice,
                        deviceChecksum: deviceChecksum,
                        libraryChecksum: libraryChecksum
                    )
                )
            }
        }
        
        return conflicts
    }
}
