//
//  DeviceWritabilityValidatorTests.swift
//  DataLayerTests
//
//  Tests for device writability validation
//

@testable import DataLayer
@testable import Shared
import XCTest

final class DeviceWritabilityValidatorTests: XCTestCase {
    
    // MARK: - DefaultDeviceWritabilityValidator Tests
    
    func testIsWritableReturnsTrueForWritablePath() throws {
        // Given - A writable temporary directory
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("writability_test_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        let validator = DefaultDeviceWritabilityValidator()
        
        // When - Checking writability
        let isWritable = validator.isWritable(path: tempDir.path)
        
        // Then - Should return true
        XCTAssertTrue(isWritable, "Writable directory should be detected as writable")
    }
    
    func testIsWritableReturnsFalseForNonExistentPath() {
        // Given - A non-existent path
        let nonExistentPath = "/nonexistent/path/\(UUID().uuidString)"
        let validator = DefaultDeviceWritabilityValidator()
        
        // When - Checking writability
        let isWritable = validator.isWritable(path: nonExistentPath)
        
        // Then - Should return false
        XCTAssertFalse(isWritable, "Non-existent path should not be writable")
    }
    
    func testIsWritableCleansUpTestFile() throws {
        // Given - A writable temporary directory
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("writability_test_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        let validator = DefaultDeviceWritabilityValidator()
        
        // When - Checking writability
        _ = validator.isWritable(path: tempDir.path)
        
        // Then - Test file should not remain
        let contents = try? FileManager.default.contentsOfDirectory(atPath: tempDir.path)
        let testFiles = contents?.filter { $0.hasPrefix(".audientia_writability_test_") } ?? []
        XCTAssertTrue(testFiles.isEmpty, "Test file should be cleaned up after validation")
    }
    
    // MARK: - DeviceWritabilityValidatorWithSpaceCheck Tests
    
    func testValidatorWithSpaceCheckFiltersOutZeroSpaceDevices() {
        // Given - A volume with 0 available space
        let volume = MountedVolumeInfo(
            id: UUID(),
            name: "Full Device",
            path: "/Volumes/Full",
            capacity: 1000,
            available: 0,
            type: .usb,
            isSystemVolume: false
        )
        let provider = StubVolumeProvider(volumes: [volume])
        let validator = DeviceWritabilityValidatorWithSpaceCheck(
            baseValidator: MockWritabilityValidator(isWritable: true),
            volumeProvider: provider,
            minimumRequiredSpace: 0
        )
        
        // When - Checking writability
        let isWritable = validator.isWritable(path: volume.path)
        
        // Then - Should return false due to zero space
        XCTAssertFalse(isWritable, "Device with 0 available space should not be writable")
    }
    
    func testValidatorWithSpaceCheckAllowsDevicesWithSufficientSpace() {
        // Given - A volume with available space
        let volume = MountedVolumeInfo(
            id: UUID(),
            name: "USB Drive",
            path: "/Volumes/USB",
            capacity: 1000,
            available: 500,
            type: .usb,
            isSystemVolume: false
        )
        let provider = StubVolumeProvider(volumes: [volume])
        let validator = DeviceWritabilityValidatorWithSpaceCheck(
            baseValidator: MockWritabilityValidator(isWritable: true),
            volumeProvider: provider,
            minimumRequiredSpace: 0
        )
        
        // When - Checking writability
        let isWritable = validator.isWritable(path: volume.path)
        
        // Then - Should return true
        XCTAssertTrue(isWritable, "Device with available space should be writable")
    }
    
    func testValidatorWithSpaceCheckRespectsMinimumRequiredSpace() {
        // Given - A volume with space but less than minimum required
        let volume = MountedVolumeInfo(
            id: UUID(),
            name: "Small Device",
            path: "/Volumes/Small",
            capacity: 1000,
            available: 100,
            type: .usb,
            isSystemVolume: false
        )
        let provider = StubVolumeProvider(volumes: [volume])
        let validator = DeviceWritabilityValidatorWithSpaceCheck(
            baseValidator: MockWritabilityValidator(isWritable: true),
            volumeProvider: provider,
            minimumRequiredSpace: 200
        )
        
        // When - Checking writability
        let isWritable = validator.isWritable(path: volume.path)
        
        // Then - Should return false due to insufficient space
        XCTAssertFalse(isWritable, "Device with less than minimum required space should not be writable")
    }
    
    func testValidatorWithSpaceCheckReturnsFalseWhenVolumeNotFound() {
        // Given - A validator with volumes that don't match the path
        let volume = MountedVolumeInfo(
            id: UUID(),
            name: "Other Device",
            path: "/Volumes/Other",
            capacity: 1000,
            available: 500,
            type: .usb,
            isSystemVolume: false
        )
        let provider = StubVolumeProvider(volumes: [volume])
        let validator = DeviceWritabilityValidatorWithSpaceCheck(
            baseValidator: MockWritabilityValidator(isWritable: true),
            volumeProvider: provider,
            minimumRequiredSpace: 0
        )
        
        // When - Checking writability for a different path
        let isWritable = validator.isWritable(path: "/Volumes/NotFound")
        
        // Then - Should return false
        XCTAssertFalse(isWritable, "Path not found in volumes should not be writable")
    }
}

// MARK: - Test Helpers

private final class MockWritabilityValidator: DeviceWritabilityValidator {
    private let isWritableResult: Bool
    
    init(isWritable: Bool) {
        self.isWritableResult = isWritable
    }
    
    func isWritable(path: String) -> Bool {
        isWritableResult
    }
}

private final class StubVolumeProvider: MountedVolumeProvider {
    private let volumes: [MountedVolumeInfo]
    
    init(volumes: [MountedVolumeInfo]) {
        self.volumes = volumes
    }
    
    func mountedVolumes() -> [MountedVolumeInfo] {
        volumes
    }
}
