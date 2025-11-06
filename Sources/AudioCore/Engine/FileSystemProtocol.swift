//
//  FileSystemProtocol.swift
//  AudioCore
//
//  File system abstraction for dependency injection
//

import Foundation

/// Protocol for file system operations (to enable mocking and testing)
internal protocol FileSystemProtocol {
    func fileExists(atPath path: String) -> Bool
}

/// Real file system implementation using FileManager
internal struct RealFileSystem: FileSystemProtocol {
    func fileExists(atPath path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
}
