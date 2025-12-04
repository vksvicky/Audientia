//
//  DeviceSidebarViewModelTests.swift
//  Audientia
//
//  TDD tests for DeviceSidebarViewModel following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import Audientia
@testable import DataLayer
@testable import Shared
import XCTest

@MainActor
final class DeviceSidebarViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockDeviceSyncManager: MockDeviceSyncManager!
    private var viewModel: DeviceSidebarViewModel!
    
    // MARK: - Setup & Teardown
    
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
    
    // MARK: - Right: Are the Results Right?
    
    func testLoadDevices_WhenDevicesExist_LoadsAllDevices() async {
        // Given: DeviceSyncManager has devices
        let device1 = createTestDevice(name: "USB Drive 1", type: .usb)
        let device2 = createTestDevice(name: "USB Drive 2", type: .usb)
        await mockDeviceSyncManager.setDevices([device1, device2])
        
        // When: Loading devices
        await viewModel.loadDevices()
        
        // Then: All devices should be loaded
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.devices.count, 2)
        XCTAssertEqual(viewModel.devices[0].name, "USB Drive 1")
        XCTAssertEqual(viewModel.devices[1].name, "USB Drive 2")
    }
    
    func testLoadDevices_WhenNoDevices_ReturnsEmptyArray() async {
        // Given: DeviceSyncManager has no devices
        await mockDeviceSyncManager.setDevices([])
        
        // When: Loading devices
        await viewModel.loadDevices()
        
        // Then: Should return empty array
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertTrue(viewModel.devices.isEmpty)
    }
    
    func testLoadDevices_OrdersDevicesByName() async {
        // Given: Devices in random order
        let deviceC = createTestDevice(name: "C Device")
        let deviceA = createTestDevice(name: "A Device")
        let deviceB = createTestDevice(name: "B Device")
        await mockDeviceSyncManager.setDevices([deviceC, deviceA, deviceB])
        
        // When: Loading devices
        await viewModel.loadDevices()
        
        // Then: Devices should be ordered by name
        XCTAssertEqual(viewModel.devices.count, 3)
        XCTAssertEqual(viewModel.devices[0].name, "A Device")
        XCTAssertEqual(viewModel.devices[1].name, "B Device")
        XCTAssertEqual(viewModel.devices[2].name, "C Device")
    }
    
    // MARK: - Boundary Conditions
    
    func testLoadDevices_WhenManagerThrowsError_HandlesError() async {
        // Given: DeviceSyncManager throws error
        await mockDeviceSyncManager.setShouldThrowError(true)
        
        // When: Loading devices
        await viewModel.loadDevices()
        
        // Then: Error should be set
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.devices.isEmpty)
    }
    
    func testLoadDevices_WithLargeNumberOfDevices_LoadsAll() async {
        // Given: Large number of devices
        let devices = (0..<100).map { createTestDevice(name: "Device \($0)") }
        await mockDeviceSyncManager.setDevices(devices)
        
        // When: Loading devices
        await viewModel.loadDevices()
        
        // Then: All devices should be loaded
        XCTAssertEqual(viewModel.devices.count, 100)
    }
    
    // MARK: - Inverse Relationships
    
    func testLoadDevices_WhenCalledMultipleTimes_RefreshesList() async {
        // Given: Initial devices
        let device1 = createTestDevice(name: "Device 1")
        await mockDeviceSyncManager.setDevices([device1])
        await viewModel.loadDevices()
        let initialCount = viewModel.devices.count
        
        // When: Adding more devices and reloading
        let device2 = createTestDevice(name: "Device 2")
        await mockDeviceSyncManager.setDevices([device1, device2])
        await viewModel.loadDevices()
        
        // Then: List should be refreshed
        XCTAssertEqual(viewModel.devices.count, initialCount + 1)
        XCTAssertTrue(viewModel.devices.contains { $0.name == "Device 2" })
    }
    
    // MARK: - Cross-Check Using Other Means
    
    func testLoadDevices_ResultsMatchDirectManagerCall() async {
        // Given: Devices in manager
        let device1 = createTestDevice(name: "Device 1")
        let device2 = createTestDevice(name: "Device 2")
        await mockDeviceSyncManager.setDevices([device1, device2])
        
        // When: Loading via ViewModel
        await viewModel.loadDevices()
        
        // Then: Results should match direct manager call
        let directResults = await mockDeviceSyncManager.availableDevices()
        XCTAssertEqual(viewModel.devices.count, directResults.count)
        XCTAssertEqual(Set(viewModel.devices.map { $0.id }), Set(directResults.map { $0.id }))
    }
    
    // MARK: - Error Conditions
    
    func testLoadDevices_WhenManagerIsNil_HandlesGracefully() async {
        // Given: Manager that throws error
        await mockDeviceSyncManager.setShouldThrowError(true)
        
        // When: Loading devices
        await viewModel.loadDevices()
        
        // Then: Should handle error without crashing
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
    }
    
    // MARK: - Performance Characteristics
    
    func testLoadDevices_PerformanceWithManyDevices() async {
        // Given: Large number of devices
        let devices = (0..<1000).map { createTestDevice(name: "Device \($0)") }
        await mockDeviceSyncManager.setDevices(devices)
        
        // When: Loading devices
        let startTime = CFAbsoluteTimeGetCurrent()
        await viewModel.loadDevices()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then: Should complete within reasonable time
        XCTAssertLessThan(duration, 0.1, "Should load 1000 devices within 100ms")
        XCTAssertEqual(viewModel.devices.count, 1000)
    }
    
    // MARK: - Edge Cases
    
    func testLoadDevices_HandlesDevicesWithSpecialCharacters() async {
        // Given: Devices with special characters in names
        let device1 = createTestDevice(name: "Device & More")
        let device2 = createTestDevice(name: "Device \"Quoted\"")
        let device3 = createTestDevice(name: "Device 'Single'")
        await mockDeviceSyncManager.setDevices([device1, device2, device3])
        
        // When: Loading devices
        await viewModel.loadDevices()
        
        // Then: Should handle special characters correctly
        XCTAssertEqual(viewModel.devices.count, 3)
        XCTAssertTrue(viewModel.devices.contains { $0.name == "Device & More" })
    }
    
    func testLoadDevices_HandlesEmptyDeviceNames() async {
        // Given: Device with empty name (edge case)
        let device = createTestDevice(name: "")
        await mockDeviceSyncManager.setDevices([device])
        
        // When: Loading devices
        await viewModel.loadDevices()
        
        // Then: Should load device even with empty name
        XCTAssertEqual(viewModel.devices.count, 1)
        XCTAssertEqual(viewModel.devices[0].name, "")
    }
    
    func testRefreshDevices_ReloadsDevices() async {
        // Given: Initial devices loaded
        let device1 = createTestDevice(name: "Device 1")
        await mockDeviceSyncManager.setDevices([device1])
        await viewModel.loadDevices()
        
        // When: Refreshing devices
        let device2 = createTestDevice(name: "Device 2")
        await mockDeviceSyncManager.setDevices([device1, device2])
        await viewModel.refreshDevices()
        
        // Then: Should reload devices
        XCTAssertEqual(viewModel.devices.count, 2)
        XCTAssertTrue(viewModel.devices.contains { $0.name == "Device 2" })
    }
    
    // MARK: - Sync Content Type Tests
    
    func testSetSyncContentType_UpdatesContentType() {
        // Given: Initial content type
        XCTAssertEqual(viewModel.syncContentType, .entireLibrary)
        
        // When: Setting to selected playlists
        viewModel.setSyncContentType(.selectedPlaylists)
        
        // Then: Content type should be updated
        XCTAssertEqual(viewModel.syncContentType, .selectedPlaylists)
    }
    
    func testSetSyncContentType_AllTypes() {
        // Given: All sync content types
        let allTypes: [SyncContentType] = [.entireLibrary, .selectedPlaylists, .checkedTracksOnly]
        
        // When: Setting each type
        for type in allTypes {
            viewModel.setSyncContentType(type)
            
            // Then: Content type should match
            XCTAssertEqual(viewModel.syncContentType, type)
        }
    }
    
    func testSyncContentType_DefaultIsEntireLibrary() {
        // Given: New ViewModel
        // When: ViewModel is initialized
        // Then: Default should be entire library
        XCTAssertEqual(viewModel.syncContentType, .entireLibrary)
    }
    
    // MARK: - Search Functionality Tests
    
    func testUpdateSearchText_WhenTextMatches_FiltersDevices() async {
        // Given: Devices loaded
        let device1 = createTestDevice(name: "USB Drive 1")
        let device2 = createTestDevice(name: "USB Drive 2")
        let device3 = createTestDevice(name: "External HD")
        await mockDeviceSyncManager.setDevices([device1, device2, device3])
        await viewModel.loadDevices()
        
        // When: Searching for "USB"
        await viewModel.updateSearchText("USB")
        
        // Then: Only matching devices should be shown
        XCTAssertEqual(viewModel.devices.count, 2)
        XCTAssertTrue(viewModel.devices.contains { $0.name == "USB Drive 1" })
        XCTAssertTrue(viewModel.devices.contains { $0.name == "USB Drive 2" })
        XCTAssertEqual(viewModel.searchText, "USB")
    }
    
    func testUpdateSearchText_WhenTextDoesNotMatch_ReturnsEmptyArray() async {
        // Given: Devices loaded
        let device1 = createTestDevice(name: "USB Drive")
        await mockDeviceSyncManager.setDevices([device1])
        await viewModel.loadDevices()
        
        // When: Searching for non-matching text
        await viewModel.updateSearchText("iPhone")
        
        // Then: Should return empty array
        XCTAssertTrue(viewModel.devices.isEmpty)
    }
    
    func testUpdateSearchText_IsCaseInsensitive() async {
        // Given: Devices loaded
        let device1 = createTestDevice(name: "USB Drive")
        await mockDeviceSyncManager.setDevices([device1])
        await viewModel.loadDevices()
        
        // When: Searching with different case
        await viewModel.updateSearchText("usb")
        
        // Then: Should match regardless of case
        XCTAssertEqual(viewModel.devices.count, 1)
        XCTAssertEqual(viewModel.devices[0].name, "USB Drive")
    }
    
    func testUpdateSearchText_WhenTextIsEmpty_ShowsAllDevices() async {
        // Given: Devices loaded and filtered
        let device1 = createTestDevice(name: "USB Drive 1")
        let device2 = createTestDevice(name: "USB Drive 2")
        await mockDeviceSyncManager.setDevices([device1, device2])
        await viewModel.loadDevices()
        await viewModel.updateSearchText("USB")
        
        // When: Clearing search
        await viewModel.updateSearchText("")
        
        // Then: Should show all devices
        XCTAssertEqual(viewModel.devices.count, 2)
        XCTAssertEqual(viewModel.searchText, "")
    }
    
    func testUpdateSearchText_MatchesPartialNames() async {
        // Given: Devices loaded
        let device1 = createTestDevice(name: "My USB Drive")
        let device2 = createTestDevice(name: "My External HD")
        await mockDeviceSyncManager.setDevices([device1, device2])
        await viewModel.loadDevices()
        
        // When: Searching for partial match
        await viewModel.updateSearchText("USB")
        
        // Then: Should match device with "USB" in name
        XCTAssertEqual(viewModel.devices.count, 1)
        XCTAssertEqual(viewModel.devices[0].name, "My USB Drive")
    }
    
    func testUpdateSearchText_TrimsWhitespace() async {
        // Given: Devices loaded
        let device1 = createTestDevice(name: "USB Drive")
        await mockDeviceSyncManager.setDevices([device1])
        await viewModel.loadDevices()
        
        // When: Searching with whitespace
        await viewModel.updateSearchText("  USB  ")
        
        // Then: Should match after trimming
        XCTAssertEqual(viewModel.devices.count, 1)
    }
    
    // MARK: - Helper Methods
    
    private func createTestDevice(
        name: String,
        type: DeviceType = .usb,
        capacity: Int64 = 1000000000,
        availableSpace: Int64 = 500000000,
        status: DeviceStatus = .ready
    ) -> Device {
        Device(
            id: UUID(),
            name: name,
            type: type,
            capacity: capacity,
            availableSpace: availableSpace,
            mountPath: "/Volumes/\(name)",
            status: status
        )
    }
}

// MARK: - Mock Device Sync Manager

actor MockDeviceSyncManager: DeviceSyncManagerProtocol {
    private var devices: [Device] = []
    private var shouldThrowError = false
    
    func setDevices(_ devices: [Device]) async {
        self.devices = devices
    }
    
    func setShouldThrowError(_ shouldThrow: Bool) async {
        shouldThrowError = shouldThrow
    }
    
    func availableDevices() async -> [Device] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        return devices
    }
    
    // MARK: - Unused Protocol Methods (required for conformance)
    
    func jobs() async -> [SyncJob] {
        []
    }
    
    func startSync(request: SyncRequest) async throws -> SyncJob {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
    }
    
    func cancel(jobId: UUID) async {
        // No-op
    }
    
    func resolveConflicts(jobId: UUID, resolutions: [SyncConflictResolution]) async throws -> SyncJob {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
    }
    
    func waitForIdle() async {
        // No-op
    }
}

// MARK: - BDD Tests

/// BDD-style tests for DeviceSidebarViewModel scenarios
@MainActor
final class DeviceSidebarViewModelBDDTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockDeviceSyncManager: MockDeviceSyncManager!
    private var viewModel: DeviceSidebarViewModel!
    
    // MARK: - Setup & Teardown
    
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
    
    // MARK: - Scenario: User views connected devices in sidebar
    
    func testScenario_UserViewsConnectedDevicesInSidebar() async {
        // Given: User has connected devices
        let device1 = createTestDevice(name: "USB Drive")
        let device2 = createTestDevice(name: "External HD")
        let device3 = createTestDevice(name: "iPhone")
        await mockDeviceSyncManager.setDevices([device1, device2, device3])
        
        // When: User opens the Devices tab
        await viewModel.loadDevices()
        
        // Then: User sees all connected devices listed in the sidebar, sorted alphabetically
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.devices.count, 3)
        XCTAssertEqual(viewModel.devices[0].name, "External HD")
        XCTAssertEqual(viewModel.devices[1].name, "iPhone")
        XCTAssertEqual(viewModel.devices[2].name, "USB Drive")
    }
    
    // MARK: - Scenario: User has no connected devices
    
    func testScenario_UserHasNoConnectedDevices() async {
        // Given: User has not connected any devices
        await mockDeviceSyncManager.setDevices([])
        
        // When: User opens the Devices tab
        await viewModel.loadDevices()
        
        // Then: User sees an empty state indicating no devices are connected
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertTrue(viewModel.devices.isEmpty)
    }
    
    // MARK: - Scenario: User refreshes device list
    
    func testScenario_UserRefreshesDeviceList() async {
        // Given: User has some devices loaded
        let device1 = createTestDevice(name: "Device 1")
        await mockDeviceSyncManager.setDevices([device1])
        await viewModel.loadDevices()
        
        // When: User connects a new device and refreshes the list
        let device2 = createTestDevice(name: "Device 2")
        await mockDeviceSyncManager.setDevices([device1, device2])
        await viewModel.refreshDevices()
        
        // Then: User sees the new device in the updated list
        XCTAssertEqual(viewModel.devices.count, 2)
        XCTAssertTrue(viewModel.devices.contains { $0.name == "Device 2" })
    }
    
    // MARK: - Scenario: User encounters error loading devices
    
    func testScenario_UserEncountersErrorLoadingDevices() async {
        // Given: DeviceSyncManager encounters an error
        await mockDeviceSyncManager.setShouldThrowError(true)
        
        // When: User opens the Devices tab
        await viewModel.loadDevices()
        
        // Then: Error is captured and displayed to user
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.devices.isEmpty)
    }
    
    // MARK: - Scenario: User changes sync content type
    
    func testScenario_UserChangesSyncContentType() {
        // Given: User has devices loaded
        // When: User selects "Selected Playlists" from sync options
        viewModel.setSyncContentType(.selectedPlaylists)
        
        // Then: Sync content type is updated to selected playlists
        XCTAssertEqual(viewModel.syncContentType, .selectedPlaylists)
    }
    
    // MARK: - Scenario: User switches between sync options
    
    func testScenario_UserSwitchesBetweenSyncOptions() {
        // Given: User starts with entire library
        XCTAssertEqual(viewModel.syncContentType, .entireLibrary)
        
        // When: User switches to checked tracks only
        viewModel.setSyncContentType(.checkedTracksOnly)
        
        // Then: Sync content type is updated
        XCTAssertEqual(viewModel.syncContentType, .checkedTracksOnly)
        
        // When: User switches back to entire library
        viewModel.setSyncContentType(.entireLibrary)
        
        // Then: Sync content type is updated back
        XCTAssertEqual(viewModel.syncContentType, .entireLibrary)
    }
    
    // MARK: - Scenario: User searches for devices
    
    func testScenario_UserSearchesForDevices() async {
        // Given: User has several devices connected
        let device1 = createTestDevice(name: "USB Drive")
        let device2 = createTestDevice(name: "External HD")
        let device3 = createTestDevice(name: "iPhone")
        await mockDeviceSyncManager.setDevices([device1, device2, device3])
        await viewModel.loadDevices()
        
        // When: User types "USB" in the search field
        await viewModel.updateSearchText("USB")
        
        // Then: User sees only devices matching "USB"
        XCTAssertEqual(viewModel.devices.count, 1)
        XCTAssertEqual(viewModel.devices[0].name, "USB Drive")
    }
    
    // MARK: - Scenario: User clears device search
    
    func testScenario_UserClearsDeviceSearch() async {
        // Given: User has searched for devices
        let device1 = createTestDevice(name: "USB Drive")
        let device2 = createTestDevice(name: "External HD")
        await mockDeviceSyncManager.setDevices([device1, device2])
        await viewModel.loadDevices()
        await viewModel.updateSearchText("USB")
        
        // When: User clears the search field
        await viewModel.updateSearchText("")
        
        // Then: User sees all devices again
        XCTAssertEqual(viewModel.devices.count, 2)
    }
    
    // MARK: - Helper Methods
    
    private func createTestDevice(
        name: String,
        type: DeviceType = .usb,
        capacity: Int64 = 1000000000,
        availableSpace: Int64 = 500000000,
        status: DeviceStatus = .ready
    ) -> Device {
        Device(
            id: UUID(),
            name: name,
            type: type,
            capacity: capacity,
            availableSpace: availableSpace,
            mountPath: "/Volumes/\(name)",
            status: status
        )
    }
}
