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
        let service = DeviceDiscoveryService(provider: provider)
        
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
        let config = DeviceDiscoveryService.Config(ignoredVolumeNames: ["Macintosh HD"], includeSystemVolumes: false)
        let service = DeviceDiscoveryService(provider: provider, config: config)
        
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
        let config = DeviceDiscoveryService.Config(ignoredVolumeNames: [], includeSystemVolumes: true)
        let service = DeviceDiscoveryService(provider: provider, config: config)
        
        let devices = await service.currentDevices()
        
        XCTAssertEqual(devices.count, 1)
        XCTAssertEqual(devices.first?.name, "Internal")
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
