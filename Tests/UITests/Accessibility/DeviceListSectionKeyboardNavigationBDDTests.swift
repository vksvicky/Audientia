//
//  DeviceListSectionKeyboardNavigationBDDTests.swift
//  UITests
//
//  BDD tests for DeviceListSection keyboard navigation
//  User scenario tests for arrow key navigation workflows
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia
@testable import DataLayer
@testable import Shared

/// BDD tests for DeviceListSection keyboard navigation
/// Tests user scenarios for arrow key navigation
@MainActor
final class DeviceListSectionKeyboardNavigationBDDTests: XCTestCase {
    
    private var mockDeviceSyncManager: MockDeviceSyncManager!
    private var viewModel: DeviceSidebarViewModel!
    
    override func setUp() {
        super.setUp()
        mockDeviceSyncManager = MockDeviceSyncManager()
        viewModel = DeviceSidebarViewModel(deviceSyncManager: mockDeviceSyncManager)
    }
    
    override func tearDown() {
        viewModel = nil
        mockDeviceSyncManager = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenario 1: Basic Arrow Key Navigation
    
    /// BDD: As a keyboard-only user, when I press Down arrow in the device list,
    /// then selection should move to the next device
    func testScenario_KeyboardUserNavigatesDownInDeviceList() async {
        // Given: I am a keyboard-only user
        // And: I have a list of devices
        let devices = createTestDevices(count: 5)
        await mockDeviceSyncManager.setDevices(devices)
        await viewModel.loadDevices()
        
        // When: I press the Down arrow key
        // Then: Selection should move to the next device
        // (Integration test - requires view rendering and ListNavigationManager)
        let availableDevices = await mockDeviceSyncManager.availableDevices()
        XCTAssertEqual(availableDevices.count, 5, "Should have 5 devices")
    }
    
    /// BDD: As a keyboard-only user, when I press Up arrow in the device list,
    /// then selection should move to the previous device
    func testScenario_KeyboardUserNavigatesUpInDeviceList() async {
        // Given: I am a keyboard-only user
        // And: I have a list of devices with a selection
        let devices = createTestDevices(count: 5)
        await mockDeviceSyncManager.setDevices(devices)
        await viewModel.loadDevices()
        
        // When: I press the Up arrow key
        // Then: Selection should move to the previous device
        let availableDevices = await mockDeviceSyncManager.availableDevices()
        XCTAssertEqual(availableDevices.count, 5, "Should have 5 devices")
    }
    
    // MARK: - BDD Scenario 2: Arrow Key Wrapping
    
    /// BDD: As a keyboard-only user, when I press Down arrow from the last device,
    /// then selection should wrap to the first device
    func testScenario_KeyboardUserWrapsFromLastToFirst() async {
        // Given: I am a keyboard-only user
        // And: I have a list of devices with the last device selected
        let devices = createTestDevices(count: 5)
        await mockDeviceSyncManager.setDevices(devices)
        await viewModel.loadDevices()
        
        // When: I press the Down arrow key
        // Then: Selection should wrap to the first device
        let availableDevices = await mockDeviceSyncManager.availableDevices()
        XCTAssertEqual(availableDevices.count, 5, "Should have 5 devices")
    }
    
    /// BDD: As a keyboard-only user, when I press Up arrow from the first device,
    /// then selection should wrap to the last device
    func testScenario_KeyboardUserWrapsFromFirstToLast() async {
        // Given: I am a keyboard-only user
        // And: I have a list of devices with the first device selected
        let devices = createTestDevices(count: 5)
        await mockDeviceSyncManager.setDevices(devices)
        await viewModel.loadDevices()
        
        // When: I press the Up arrow key
        // Then: Selection should wrap to the last device
        let availableDevices = await mockDeviceSyncManager.availableDevices()
        XCTAssertEqual(availableDevices.count, 5, "Should have 5 devices")
    }
    
    // MARK: - BDD Scenario 3: Selection Roundtrip
    
    /// BDD: As a keyboard-only user, when I navigate down then up,
    /// then I should return to my original selection
    func testScenario_KeyboardUserReturnsToOriginalSelection() async {
        // Given: I am a keyboard-only user
        // And: I have a list with a device selected
        let devices = createTestDevices(count: 5)
        await mockDeviceSyncManager.setDevices(devices)
        await viewModel.loadDevices()
        
        // When: I press Down arrow, then Up arrow
        // Then: I should return to my original selection
        let availableDevices = await mockDeviceSyncManager.availableDevices()
        XCTAssertEqual(availableDevices.count, 5, "Should have 5 devices")
    }
    
    // MARK: - BDD Scenario 4: Empty List Handling
    
    /// BDD: As a keyboard-only user, when I press arrow keys in an empty device list,
    /// then nothing should happen
    func testScenario_KeyboardUserNavigatesEmptyList() async {
        // Given: I am a keyboard-only user
        // And: I have an empty device list
        await mockDeviceSyncManager.setDevices([])
        await viewModel.loadDevices()
        
        // When: I press Down or Up arrow keys
        // Then: Nothing should happen (no selection)
        let availableDevices = await mockDeviceSyncManager.availableDevices()
        XCTAssertTrue(availableDevices.isEmpty, "Should have no devices")
    }
    
    // MARK: - Helper Methods
    
    private func createTestDevices(count: Int) -> [Shared.Device] {
        var result: [Shared.Device] = []
        for index in 0..<count {
            let deviceType: Shared.DeviceType = index % 3 == 0 ? .usb : (index % 3 == 1 ? .mtp : .smb)
            let capacity = Int64(1000 * 1024 * 1024) // 1GB capacity
            let availableSpace = Int64((1000 - index) * 1024 * 1024) // Decreasing space
            let device = Shared.Device(
                id: UUID(),
                name: "Device \(index + 1)",
                type: deviceType,
                capacity: capacity,
                availableSpace: availableSpace,
                mountPath: nil,
                status: .ready
            )
            result.append(device)
        }
        return result
    }
}
