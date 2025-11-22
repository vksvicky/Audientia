//
//  SQLiteFingerprintCache.swift
//  MetadataEngine
//
//  SQLite-based fingerprint cache implementation
//

import Foundation
import SQLite3

// SQLITE_TRANSIENT tells SQLite to make its own copy of the data
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// SQLite-based implementation of fingerprint cache
public actor SQLiteFingerprintCache: FingerprintCacheProtocol {
    private let databaseURL: URL
    private var db: OpaquePointer?
    private var isInitialized = false
    
    // Current schema version
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
    
    // MARK: - FingerprintCacheProtocol
    
    public func get(filePath: String) async throws -> FingerprintCacheEntry? {
        try await ensureDatabaseOpen()
        
        let selectSQL = "SELECT file_path, file_modification_time, fingerprint, cached_at, expires_at FROM fingerprint_cache WHERE file_path = ?"
        var statement: OpaquePointer?
        
        guard let db = db else {
            throw FingerprintCacheError.databaseError("Database not open")
        }
        
        guard sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK else {
            throw FingerprintCacheError.databaseError(String(cString: sqlite3_errmsg(db)))
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, filePath, -1, SQLITE_TRANSIENT)
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            // No row found
            return nil
        }
        
        // Extract data from row
        guard let pathPtr = sqlite3_column_text(statement, 0) else {
            return nil
        }
        let storedPath = String(cString: pathPtr)
        
        let modificationTime = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_double(statement, 1)))
        
        guard let fingerprintPtr = sqlite3_column_text(statement, 2) else {
            return nil
        }
        let fingerprint = String(cString: fingerprintPtr)
        
        let cachedAt = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_double(statement, 3)))
        
        var expiresAt: Date?
        if sqlite3_column_type(statement, 4) != SQLITE_NULL {
            expiresAt = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_double(statement, 4)))
        }
        
        // Check if expired
        if let expiration = expiresAt, expiration < Date() {
            // Entry is expired, remove it and return nil
            try await remove(filePath: storedPath)
            return nil
        }
        
        return FingerprintCacheEntry(
            filePath: storedPath,
            fileModificationTime: modificationTime,
            fingerprint: fingerprint,
            cachedAt: cachedAt,
            expiresAt: expiresAt
        )
    }
    
    public func store(_ entry: FingerprintCacheEntry) async throws {
        try await ensureDatabaseOpen()
        
        guard let db = db else {
            throw FingerprintCacheError.databaseError("Database not open")
        }
        
        let insertSQL = """
            INSERT OR REPLACE INTO fingerprint_cache
            (file_path, file_modification_time, fingerprint, cached_at, expires_at)
            VALUES (?, ?, ?, ?, ?)
        """
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK else {
            throw FingerprintCacheError.databaseError(String(cString: sqlite3_errmsg(db)))
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, entry.filePath, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(statement, 2, entry.fileModificationTime.timeIntervalSince1970)
        sqlite3_bind_text(statement, 3, entry.fingerprint, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(statement, 4, entry.cachedAt.timeIntervalSince1970)
        
        if let expiresAt = entry.expiresAt {
            sqlite3_bind_double(statement, 5, expiresAt.timeIntervalSince1970)
        } else {
            sqlite3_bind_null(statement, 5)
        }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw FingerprintCacheError.databaseError(String(cString: sqlite3_errmsg(db)))
        }
    }
    
    public func remove(filePath: String) async throws {
        try await ensureDatabaseOpen()
        
        guard let db = db else {
            throw FingerprintCacheError.databaseError("Database not open")
        }
        
        let deleteSQL = "DELETE FROM fingerprint_cache WHERE file_path = ?"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK else {
            throw FingerprintCacheError.databaseError(String(cString: sqlite3_errmsg(db)))
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, filePath, -1, SQLITE_TRANSIENT)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw FingerprintCacheError.databaseError(String(cString: sqlite3_errmsg(db)))
        }
    }
    
    public func clear() async throws {
        try await ensureDatabaseOpen()
        
        guard let db = db else {
            throw FingerprintCacheError.databaseError("Database not open")
        }
        
        let deleteSQL = "DELETE FROM fingerprint_cache"
        var errMsg: UnsafeMutablePointer<CChar>?
        
        guard sqlite3_exec(db, deleteSQL, nil, nil, &errMsg) == SQLITE_OK else {
            if let errMsg = errMsg {
                let error = String(cString: errMsg)
                sqlite3_free(errMsg)
                throw FingerprintCacheError.databaseError(error)
            } else {
                throw FingerprintCacheError.databaseError("Unknown error")
            }
        }
    }
    
    public func isCached(filePath: String) async throws -> Bool {
        let entry = try await get(filePath: filePath)
        return entry != nil
    }
    
    public func getStatistics() async throws -> (total: Int, expired: Int) {
        try await ensureDatabaseOpen()
        
        guard let db = db else {
            throw FingerprintCacheError.databaseError("Database not open")
        }
        
        // Count total entries
        let countSQL = "SELECT COUNT(*) FROM fingerprint_cache"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, countSQL, -1, &statement, nil) == SQLITE_OK else {
            throw FingerprintCacheError.databaseError(String(cString: sqlite3_errmsg(db)))
        }
        
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw FingerprintCacheError.databaseError("Failed to count entries")
        }
        
        let total = Int(sqlite3_column_int(statement, 0))
        
        // Count expired entries
        let expiredSQL = "SELECT COUNT(*) FROM fingerprint_cache WHERE expires_at IS NOT NULL AND expires_at < ?"
        var expiredStatement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, expiredSQL, -1, &expiredStatement, nil) == SQLITE_OK else {
            throw FingerprintCacheError.databaseError(String(cString: sqlite3_errmsg(db)))
        }
        
        defer { sqlite3_finalize(expiredStatement) }
        
        let now = Date().timeIntervalSince1970
        sqlite3_bind_double(expiredStatement, 1, now)
        
        guard sqlite3_step(expiredStatement) == SQLITE_ROW else {
            throw FingerprintCacheError.databaseError("Failed to count expired entries")
        }
        
        let expired = Int(sqlite3_column_int(expiredStatement, 0))
        
        return (total: total, expired: expired)
    }
    
    // MARK: - Private Database Operations
    
    private func ensureDatabaseOpen() async throws {
        if !isInitialized {
            try await initializeDatabase()
            isInitialized = true
        }
    }
    
    private func initializeDatabase() async throws {
        let result = sqlite3_open_v2(
            databaseURL.path,
            &db,
            SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX,
            nil
        )
        
        guard result == SQLITE_OK, let db = db else {
            throw FingerprintCacheError.databaseError(
                result == SQLITE_OK ? "Failed to open database" : String(cString: sqlite3_errmsg(db))
            )
        }
        
        // Ensure synchronous writes for data integrity
        sqlite3_exec(db, "PRAGMA synchronous = FULL", nil, nil, nil)
        sqlite3_exec(db, "PRAGMA journal_mode = DELETE", nil, nil, nil)
        
        try await createSchema()
    }
    
    private func createSchema() async throws {
        guard let db = db else {
            throw FingerprintCacheError.databaseError("Database not open")
        }
        
        let createTableSQL = """
            CREATE TABLE IF NOT EXISTS fingerprint_cache (
                file_path TEXT PRIMARY KEY,
                file_modification_time REAL NOT NULL,
                fingerprint TEXT NOT NULL,
                cached_at REAL NOT NULL,
                expires_at REAL
            );
            CREATE INDEX IF NOT EXISTS idx_file_path ON fingerprint_cache(file_path);
            CREATE INDEX IF NOT EXISTS idx_expires_at ON fingerprint_cache(expires_at);
        """
        
        var errMsg: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(db, createTableSQL, nil, nil, &errMsg)
        
        guard result == SQLITE_OK else {
            if let errMsg = errMsg {
                let error = String(cString: errMsg)
                sqlite3_free(errMsg)
                throw FingerprintCacheError.databaseError("Failed to create schema: \(error)")
            } else {
                throw FingerprintCacheError.databaseError("Failed to create schema: Unknown error")
            }
        }
    }
}
