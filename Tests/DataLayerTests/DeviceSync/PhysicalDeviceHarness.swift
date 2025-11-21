//
//  PhysicalDeviceHarness.swift
//  DataLayerTests
//
//  Hardware-in-the-loop testing harness for real device integration tests
//

import Foundation
import XCTest

@testable import DataLayer
@testable import Shared

/// Harness for testing with real physical devices
/// Tests using this harness will be skipped if no suitable devices are available
public actor PhysicalDeviceHarness {
    
    public enum DeviceRequirement {
        case any
        case usb
        case mtp
        case smb
        case minimumCapacity(Int64) // bytes
    }
    
    private let discovery: DeviceDiscoveryProtocol
    private var availableDevices: [Device] = []
    
    public init(discovery: DeviceDiscoveryProtocol = DeviceDiscoveryService()) {
        self.discovery = discovery
    }
    
    // MARK: - Device Discovery
    
    /// Discovers available physical devices
    public func discoverDevices() async {
        availableDevices = await discovery.currentDevices()
    }
    
    /// Finds a device matching the requirements
    public func findDevice(matching requirement: DeviceRequirement) -> Device? {
        let candidates = availableDevices.filter { device in
            switch requirement {
            case .any:
                return true
            case .usb:
                return device.type == .usb
            case .mtp:
                return device.type == .mtp
            case .smb:
                return device.type == .smb
            case .minimumCapacity(let minCapacity):
                return device.availableSpace >= minCapacity
            }
        }
        return candidates.first
    }
    
    /// Validates that a device is ready for testing
    public func validateDevice(_ device: Device) -> DeviceValidationResult {
        var issues: [String] = []
        
        // Check device is mounted
        guard let mountPath = device.mountPath else {
            issues.append("Device is not mounted")
            return .invalid(issues)
        }
        
        // Check mount path exists
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: mountPath) else {
            issues.append("Mount path does not exist: \(mountPath)")
            return .invalid(issues)
        }
        
        // Check write permissions
        let testFile = URL(fileURLWithPath: mountPath).appendingPathComponent(".audientia_test_write")
        do {
            try "test".write(to: testFile, atomically: true, encoding: .utf8)
            try? fileManager.removeItem(at: testFile)
        } catch {
            issues.append("Cannot write to device: \(error.localizedDescription)")
            return .invalid(issues)
        }
        
        // Check available space
        if device.availableSpace < 10 * 1024 * 1024 { // 10 MB minimum
            issues.append("Insufficient space: \(device.availableSpace) bytes available")
        }
        
        return issues.isEmpty ? .valid : .invalid(issues)
    }
    
    /// Gets all available devices
    public func getAvailableDevices() -> [Device] {
        availableDevices
    }
    
    /// Checks if any devices are available
    public func hasDevices() -> Bool {
        !availableDevices.isEmpty
    }
    
    // MARK: - Test Helpers
    
    /// Creates a test sync request for a device
    public func createTestSyncRequest(
        device: Device,
        trackCount: Int = 1,
        options: SyncOptions = .default
    ) -> SyncRequest {
        let tracks = DeviceSyncFixtures.tracks(count: trackCount)
        return DeviceSyncFixtures.syncRequest(
            device: device,
            tracks: tracks,
            options: options
        )
    }
    
    /// Cleans up test artifacts from a device
    public func cleanupDevice(_ device: Device) async throws {
        guard let mountPath = device.mountPath else { return }
        
        let fileManager = FileManager.default
        let rootURL = URL(fileURLWithPath: mountPath)
        
        // Remove test manifest folder
        let manifestFolder = rootURL.appendingPathComponent(".audientia-sync", isDirectory: true)
        if fileManager.fileExists(atPath: manifestFolder.path) {
            try? fileManager.removeItem(at: manifestFolder)
        }
        
        // Remove test library folder
        let libraryFolder = rootURL.appendingPathComponent("Audientia", isDirectory: true)
        if fileManager.fileExists(atPath: libraryFolder.path) {
            try? fileManager.removeItem(at: libraryFolder)
        }
        
        // Remove any test files
        let testFile = rootURL.appendingPathComponent(".audientia_test_write")
        try? fileManager.removeItem(at: testFile)
    }
}

// MARK: - Validation Result

public enum DeviceValidationResult {
    case valid
    case invalid([String])
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    var issues: [String] {
        switch self {
        case .valid:
            return []
        case .invalid(let issues):
            return issues
        }
    }
}

// MARK: - XCTest Extensions

extension XCTestCase {
    /// Skips a test if no devices are available
    public func skipIfNoDevices(harness: PhysicalDeviceHarness) async throws {
        await harness.discoverDevices()
        guard await harness.hasDevices() else {
            throw XCTSkip("No physical devices available for testing")
        }
    }
    
    /// Skips a test if no device matching requirements is available
    public func skipIfNoDevice(
        harness: PhysicalDeviceHarness,
        matching requirement: PhysicalDeviceHarness.DeviceRequirement
    ) async throws -> Device {
        await harness.discoverDevices()
        guard let device = await harness.findDevice(matching: requirement) else {
            throw XCTSkip("No device matching requirements available for testing")
        }
        
        let validation = await harness.validateDevice(device)
        guard validation.isValid else {
            throw XCTSkip("Device validation failed: \(validation.issues.joined(separator: ", "))")
        }
        
        return device
    }
}
