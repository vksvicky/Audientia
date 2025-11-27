//
//  DeviceDiscoveryServiceTests.swift
//  DataLayerTests
//

@testable import DataLayer
@testable import Shared
import XCTest

final class DeviceDiscoveryServiceTests: XCTestCase {
    
    func testReturnsDevicesFromProvider() async {
        guard let uuid = UUID(uuidString: "E8CE62A6-6E79-4D76-8F46-2E678A1B3A0A") else {
            XCTFail("Invalid UUID string")
            return
        }
        let volume = MountedVolumeInfo(
            id: uuid,
            name: "USB Studio",
            path: "/Volumes/USBStudio",
            capacity: 128 * 1024 * 1024,
            available: 64 * 1024 * 1024,
            type: .usb,
            isSystemVolume: false
        )
        let provider = StubVolumeProvider(volumes: [volume])
        let validator = MockWritabilityValidator(isWritable: true)
        let service = DeviceDiscoveryService(
            provider: provider,
            writabilityValidator: DeviceWritabilityValidatorWithSpaceCheck(
                baseValidator: validator,
                volumeProvider: provider,
                minimumRequiredSpace: 0
            )
        )
        
        let devices = await service.currentDevices()
        
        XCTAssertEqual(devices.count, 1)
        XCTAssertEqual(devices.first?.name, "USB Studio")
        XCTAssertEqual(devices.first?.type, .usb)
        XCTAssertEqual(devices.first?.mountPath, "/Volumes/USBStudio")
    }
    
    func testIgnoresConfiguredVolumes() async {
        let volumes = [
            MountedVolumeInfo(
                id: UUID(),
                name: "Macintosh HD",
                path: "/",
                capacity: 512,
                available: 256,
                type: .usb,
                isSystemVolume: true
            ),
            MountedVolumeInfo(
                id: UUID(),
                name: "Music Drive",
                path: "/Volumes/Music",
                capacity: 256,
                available: 200,
                type: .usb,
                isSystemVolume: false
            )
        ]
        let provider = StubVolumeProvider(volumes: volumes)
        let validator = MockWritabilityValidator(isWritable: true)
        let config = DeviceDiscoveryService.Config(ignoredVolumeNames: ["Macintosh HD"], includeSystemVolumes: false)
        let service = DeviceDiscoveryService(
            provider: provider,
            writabilityValidator: DeviceWritabilityValidatorWithSpaceCheck(
                baseValidator: validator,
                volumeProvider: provider,
                minimumRequiredSpace: 0
            ),
            config: config
        )
        
        let devices = await service.currentDevices()
        
        XCTAssertEqual(devices.map(\.name), ["Music Drive"])
    }
    
    func testIncludesSystemVolumesWhenConfigured() async {
        let provider = StubVolumeProvider(
            volumes: [
                MountedVolumeInfo(
                    id: UUID(),
                    name: "Internal",
                    path: "/",
                    capacity: 100,
                    available: 50,
                    type: .usb,
                    isSystemVolume: true
                )
            ]
        )
        let validator = MockWritabilityValidator(isWritable: true)
        let config = DeviceDiscoveryService.Config(ignoredVolumeNames: [], includeSystemVolumes: true)
        let service = DeviceDiscoveryService(
            provider: provider,
            writabilityValidator: DeviceWritabilityValidatorWithSpaceCheck(
                baseValidator: validator,
                volumeProvider: provider,
                minimumRequiredSpace: 0
            ),
            config: config
        )
        
        let devices = await service.currentDevices()
        
        XCTAssertEqual(devices.count, 1)
        XCTAssertEqual(devices.first?.name, "Internal")
    }
    
    // MARK: - Writability Validation Tests
    
    func testFiltersOutNonWritableDevices() async {
        // Given - A writable and a non-writable device
        let writableVolume = MountedVolumeInfo(
            id: UUID(),
            name: "Writable USB",
            path: "/Volumes/Writable",
            capacity: 1000,
            available: 500,
            type: .usb,
            isSystemVolume: false
        )
        let nonWritableVolume = MountedVolumeInfo(
            id: UUID(),
            name: "Read-Only Disk",
            path: "/Volumes/ReadOnly",
            capacity: 1000,
            available: 0, // Zero space = non-writable
            type: .usb,
            isSystemVolume: false
        )
        let provider = StubVolumeProvider(volumes: [writableVolume, nonWritableVolume])
        let validator = MockWritabilityValidator(isWritable: true) // Base validator passes
        let service = DeviceDiscoveryService(
            provider: provider,
            writabilityValidator: DeviceWritabilityValidatorWithSpaceCheck(
                baseValidator: validator,
                volumeProvider: provider,
                minimumRequiredSpace: 0
            )
        )
        
        // When - Getting devices
        let devices = await service.currentDevices()
        
        // Then - Only writable device should be returned
        XCTAssertEqual(devices.count, 1, "Should filter out non-writable device")
        XCTAssertEqual(devices.first?.name, "Writable USB", "Should only return writable device")
    }
    
    func testFiltersOutDevicesWithZeroAvailableSpace() async {
        // Given - A device with zero available space
        let zeroSpaceVolume = MountedVolumeInfo(
            id: UUID(),
            name: "Full Disk",
            path: "/Volumes/Full",
            capacity: 1000,
            available: 0,
            type: .usb,
            isSystemVolume: false
        )
        let provider = StubVolumeProvider(volumes: [zeroSpaceVolume])
        let service = DeviceDiscoveryService(provider: provider)
        
        // When - Getting devices
        let devices = await service.currentDevices()
        
        // Then - Device should be filtered out
        XCTAssertEqual(devices.count, 0, "Device with zero space should be filtered out")
    }
    
    func testIncludesWritableDevices() async {
        // Given - A writable device with available space
        let writableVolume = MountedVolumeInfo(
            id: UUID(),
            name: "USB Drive",
            path: "/Volumes/USB",
            capacity: 1000,
            available: 500,
            type: .usb,
            isSystemVolume: false
        )
        let provider = StubVolumeProvider(volumes: [writableVolume])
        let validator = MockWritabilityValidator(isWritable: true)
        let service = DeviceDiscoveryService(
            provider: provider,
            writabilityValidator: DeviceWritabilityValidatorWithSpaceCheck(
                baseValidator: validator,
                volumeProvider: provider,
                minimumRequiredSpace: 0
            )
        )
        
        // When - Getting devices
        let devices = await service.currentDevices()
        
        // Then - Writable device should be included
        XCTAssertEqual(devices.count, 1, "Writable device should be included")
        XCTAssertEqual(devices.first?.name, "USB Drive")
    }
    
    func testCanDisableWritabilityValidation() async {
        // Given - A non-writable device and validation disabled
        let nonWritableVolume = MountedVolumeInfo(
            id: UUID(),
            name: "Read-Only",
            path: "/Volumes/ReadOnly",
            capacity: 1000,
            available: 0,
            type: .usb,
            isSystemVolume: false
        )
        let provider = StubVolumeProvider(volumes: [nonWritableVolume])
        let config = DeviceDiscoveryService.Config(validateWritability: false)
        let service = DeviceDiscoveryService(provider: provider, config: config)
        
        // When - Getting devices
        let devices = await service.currentDevices()
        
        // Then - Device should be included when validation is disabled
        XCTAssertEqual(devices.count, 1, "Device should be included when validation is disabled")
        XCTAssertEqual(devices.first?.name, "Read-Only")
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

private final class MockWritabilityValidator: DeviceWritabilityValidator {
    private let isWritableResult: Bool
    
    init(isWritable: Bool) {
        self.isWritableResult = isWritable
    }
    
    func isWritable(path: String) -> Bool {
        isWritableResult
    }
}
