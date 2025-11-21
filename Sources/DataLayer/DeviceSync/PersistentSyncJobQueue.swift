//
//  PersistentSyncJobQueue.swift
//  DataLayer
//
//  SQLite-based persistent job queue for Device Sync
//

import Foundation
import Shared
import SQLite3

// SQLITE_TRANSIENT tells SQLite to make its own copy of the data
// This is critical for async operations where the original buffer might be deallocated
// swiftlint:disable:next identifier_name
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

public actor PersistentSyncJobQueue: SyncJobQueueProtocol {
    private let databaseURL: URL
    private var db: OpaquePointer?
    private var waiters: [CheckedContinuation<SyncJob?, Never>] = []
    private var isInitialized = false
    
    // Current schema version - increment when schema changes
    private static let currentSchemaVersion: Int32 = 1
    
    public init(databaseURL: URL) {
        self.databaseURL = databaseURL
    }
    
    deinit {
        if let db = db {
            sqlite3_close(db)
            self.db = nil
        }
    }
    
    // MARK: - SyncJobQueueProtocol
    
    public func enqueue(_ job: SyncJob) async {
        await ensureDatabaseOpen()
        await insertJob(job)
        await resumeNextWaiterIfNeeded()
    }
    
    public func dequeue() async -> SyncJob? {
        await ensureDatabaseOpen()
        
        if let job = await popFirstJob() {
            return job
        }
        
        return await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
    
    public func remove(jobId: UUID) async {
        await ensureDatabaseOpen()
        await deleteJob(jobId: jobId)
    }
    
    public func isEmpty() async -> Bool {
        await ensureDatabaseOpen()
        return await getJobCount() == 0
    }
    
    public func snapshot() async -> [SyncJob] {
        await ensureDatabaseOpen()
        return await getAllJobs()
    }
    
    public func close() async {
        if let db = db {
            // Ensure all pending writes are committed and flushed to disk
            sqlite3_exec(db, "PRAGMA wal_checkpoint(FULL)", nil, nil, nil)
            
            let result = sqlite3_close(db)
            if result == SQLITE_BUSY {
                // If busy, finalize any remaining statements and try again
                sqlite3_close_v2(db)
            }
            self.db = nil
            isInitialized = false
        }
    }
    
    #if DEBUG
    public func debugJobCount() async -> Int {
        await ensureDatabaseOpen()
        return await getJobCount()
    }
    #endif
    
    // MARK: - Private Database Operations
    
    private func initializeDatabase() async {
        let result = sqlite3_open_v2(
            databaseURL.path,
            &db,
            SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX,
            nil
        )
        
        guard result == SQLITE_OK else {
            fatalError("Failed to open database: \(String(cString: sqlite3_errmsg(db)))")
        }
        
        // Ensure synchronous writes for data integrity
        sqlite3_exec(db, "PRAGMA synchronous = FULL", nil, nil, nil)
        // Disable WAL mode to ensure immediate writes to main database file
        sqlite3_exec(db, "PRAGMA journal_mode = DELETE", nil, nil, nil)
        
        await createSchema()
    }
    
    private func ensureDatabaseOpen() async {
        if !isInitialized {
            await initializeDatabase()
            isInitialized = true
        }
    }
    
    private func createSchema() async {
        // Create schema version table first
        let createVersionTableSQL = """
            CREATE TABLE IF NOT EXISTS schema_version (
                version INTEGER PRIMARY KEY
            );
        """
        
        var errMsg: UnsafeMutablePointer<CChar>?
        var result = sqlite3_exec(db, createVersionTableSQL, nil, nil, &errMsg)
        
        guard result == SQLITE_OK else {
            if let errMsg = errMsg {
                let error = String(cString: errMsg)
                sqlite3_free(errMsg)
                fatalError("Failed to create version table: \(error)")
            } else {
                fatalError("Failed to create version table: Unknown error")
            }
        }
        
        // Get current schema version
        let currentVersion = await getSchemaVersion()
        
        // Run migrations if needed
        if currentVersion < Self.currentSchemaVersion {
            await runMigrations(from: currentVersion, to: Self.currentSchemaVersion)
        }
        
        // Create main table (if it doesn't exist)
        let createTableSQL = """
            CREATE TABLE IF NOT EXISTS sync_jobs (
                id TEXT PRIMARY KEY,
                data BLOB NOT NULL,
                created_at INTEGER NOT NULL,
                position INTEGER NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_position ON sync_jobs(position);
        """
        
        result = sqlite3_exec(db, createTableSQL, nil, nil, &errMsg)
        
        guard result == SQLITE_OK else {
            if let errMsg = errMsg {
                let error = String(cString: errMsg)
                sqlite3_free(errMsg)
                fatalError("Failed to create schema: \(error)")
            } else {
                fatalError("Failed to create schema: Unknown error")
            }
        }
        
        // Update schema version
        await setSchemaVersion(Self.currentSchemaVersion)
    }
    
    private func getSchemaVersion() async -> Int32 {
        guard let db = db else { return 0 }
        
        let selectSQL = "SELECT version FROM schema_version LIMIT 1"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK else {
            return 0
        }
        
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            return 0
        }
        
        return sqlite3_column_int(statement, 0)
    }
    
    private func setSchemaVersion(_ version: Int32) async {
        guard let db = db else { return }
        
        let deleteSQL = "DELETE FROM schema_version"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
            sqlite3_finalize(statement)
        }
        
        let insertSQL = "INSERT INTO schema_version (version) VALUES (?)"
        statement = nil
        
        guard sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK else {
            return
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_int(statement, 1, version)
        sqlite3_step(statement)
    }
    
    private func runMigrations(from oldVersion: Int32, to newVersion: Int32) async {
        // Migration 0 -> 1: Initial schema (already handled by CREATE TABLE IF NOT EXISTS)
        // Future migrations would go here:
        // if oldVersion < 2 && newVersion >= 2 {
        //     await migrateToVersion2()
        // }
        // if oldVersion < 3 && newVersion >= 3 {
        //     await migrateToVersion3()
        // }
        
        // For now, we're at version 1, so no migrations needed
        // This structure allows for future schema changes
    }
    
    private func insertJob(_ job: SyncJob) async {
        guard let db = db else { return }
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(job) else {
            fatalError("Failed to encode job")
        }
        
        let position = await getNextPosition()
        // Use INSERT OR REPLACE to handle cases where a job with the same ID already exists
        // This can happen when jobs are restored from the queue and then enqueued again
        let insertSQL = "INSERT OR REPLACE INTO sync_jobs (id, data, created_at, position) VALUES (?, ?, ?, ?)"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK else {
            fatalError("Failed to prepare insert statement: \(String(cString: sqlite3_errmsg(db)))")
        }
        
        defer { sqlite3_finalize(statement) }
        
        let idString = job.id.uuidString
        let timestamp = Int64(Date().timeIntervalSince1970)
        
        sqlite3_bind_text(statement, 1, idString, -1, SQLITE_TRANSIENT)
        
        // Bind blob data - use SQLITE_TRANSIENT to ensure SQLite copies the data
        // This is critical because the data buffer might be deallocated before SQLite writes it
        let bindResult = data.withUnsafeBytes { bytes in
            sqlite3_bind_blob(statement, 2, bytes.baseAddress, Int32(bytes.count), SQLITE_TRANSIENT)
        }
        guard bindResult == SQLITE_OK else {
            fatalError("Failed to bind blob: \(String(cString: sqlite3_errmsg(db)))")
        }
        
        sqlite3_bind_int64(statement, 3, timestamp)
        sqlite3_bind_int64(statement, 4, Int64(position))
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            fatalError("Failed to insert job: \(String(cString: sqlite3_errmsg(db)))")
        }
    }
    
    private func popFirstJob() async -> SyncJob? {
        guard let db = db else { return nil }
        
        // Select both id and data to ensure we delete the exact row we read
        let selectSQL = "SELECT id, data FROM sync_jobs ORDER BY position ASC LIMIT 1"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }
        
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            return nil
        }
        
        // Get the ID from the database
        guard let idText = sqlite3_column_text(statement, 0) else {
            return nil
        }
        let idString = String(cString: idText)
        guard let jobId = UUID(uuidString: idString) else {
            return nil
        }
        
        // Get the data blob
        guard let blob = sqlite3_column_blob(statement, 1) else {
            return nil
        }
        
        let blobLength = sqlite3_column_bytes(statement, 1)
        let data = Data(bytes: blob, count: Int(blobLength))
        
        // Decode the job first to ensure we have valid data before deleting
        let decoder = JSONDecoder()
        guard let job = try? decoder.decode(SyncJob.self, from: data) else {
            return nil
        }
        
        // Delete the job after successful decoding
        // Use the ID from the database to ensure we delete the exact row we read
        await deleteJob(jobId: jobId)
        
        return job
    }
    
    private func deleteJob(jobId: UUID) async {
        guard let db = db else { return }
        
        let deleteSQL = "DELETE FROM sync_jobs WHERE id = ?"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK else {
            return
        }
        
        defer { sqlite3_finalize(statement) }
        
        let idString = jobId.uuidString
        sqlite3_bind_text(statement, 1, idString, -1, SQLITE_TRANSIENT)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            return
        }
    }
    
    private func getJobCount() async -> Int {
        guard let db = db else { return 0 }
        
        let countSQL = "SELECT COUNT(*) FROM sync_jobs"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, countSQL, -1, &statement, nil) == SQLITE_OK else {
            return 0
        }
        
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            return 0
        }
        
        return Int(sqlite3_column_int(statement, 0))
    }
    
    private func getAllJobs() async -> [SyncJob] {
        guard let db = db else { return [] }
        
        let selectSQL = "SELECT data FROM sync_jobs ORDER BY position ASC"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK else {
            return []
        }
        
        defer { sqlite3_finalize(statement) }
        
        var jobs: [SyncJob] = []
        let decoder = JSONDecoder()
        
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let blob = sqlite3_column_blob(statement, 0) else {
                continue
            }
            
            let blobLength = sqlite3_column_bytes(statement, 0)
            let data = Data(bytes: blob, count: Int(blobLength))
            
            if let job = try? decoder.decode(SyncJob.self, from: data) {
                jobs.append(job)
            }
        }
        
        return jobs
    }
    
    private func getNextPosition() async -> Int {
        guard let db = db else { return 0 }
        
        let maxSQL = "SELECT MAX(position) FROM sync_jobs"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, maxSQL, -1, &statement, nil) == SQLITE_OK else {
            return 0
        }
        
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            return 0
        }
        
        let maxPosition = sqlite3_column_int(statement, 0)
        return Int(maxPosition) + 1
    }
    
    private func resumeNextWaiterIfNeeded() async {
        guard !waiters.isEmpty else { return }
        let continuation = waiters.removeFirst()
        if let job = await popFirstJob() {
            continuation.resume(returning: job)
        } else {
            continuation.resume(returning: nil)
        }
    }
    
    /// Clear all waiters - useful for testing or when manager is deallocated
    /// This prevents jobs from being automatically dequeued when enqueued
    public func clearWaiters() async {
        waiters.removeAll()
    }
}
