# Device Sync Integration Tests

This directory contains integration tests for the Device Sync feature, including hardware-in-the-loop testing with real physical devices.

## Test Structure

### Unit Tests
- `DeviceSyncManagerTests.swift` - Unit tests for DeviceSyncManager
- `DeviceSyncManagerBDDTests.swift` - BDD scenarios for DeviceSyncManager
- `PersistentSyncJobQueueTests.swift` - TDD tests for persistent queue
- `PersistentSyncJobQueueBDDTests.swift` - BDD scenarios for persistent queue
- `PersistentSyncJobQueueMigrationTests.swift` - Migration tests
- `DeviceSyncManagerPersistentQueueTests.swift` - Persistent queue integration

### Integration Tests
- `FullDeviceIntegrationTests.swift` - Full-device integration tests with real hardware
- `PhysicalDeviceHarnessBDDTests.swift` - BDD scenarios using physical device harness

## Physical Device Harness

The `PhysicalDeviceHarness` provides infrastructure for testing with real physical devices.

### Features

- **Device Discovery**: Automatically discovers available USB, MTP, and SMB devices
- **Device Validation**: Validates devices are ready for testing (mounted, writable, sufficient space)
- **Test Helpers**: Creates test sync requests and cleans up test artifacts
- **Conditional Testing**: Tests automatically skip if no suitable devices are available

### Usage

```swift
let harness = PhysicalDeviceHarness()

// Discover devices
await harness.discoverDevices()

// Find a device matching requirements
let device = try await skipIfNoDevice(
    harness: harness,
    matching: .usb  // or .mtp, .smb, .minimumCapacity(bytes), .any
)

// Validate device
let validation = await harness.validateDevice(device)
guard validation.isValid else {
    throw XCTSkip("Device validation failed")
}

// Create test sync request
let request = await harness.createTestSyncRequest(
    device: device,
    trackCount: 5,
    options: .default
)

// Cleanup after test
try await harness.cleanupDevice(device)
```

### Device Requirements

- **USB**: USB mass storage device (flash drive, external hard drive)
- **MTP**: MTP-compatible device (Android phones, some media players)
- **SMB**: Network share mounted on macOS
- **Minimum Capacity**: Device with at least specified bytes available

### Test Execution

#### Running All Tests
```bash
xcodebuild test -scheme Audientia -target DataLayerTests
```

#### Running Only Integration Tests
```bash
xcodebuild test -scheme Audientia -target DataLayerTests \
  -only-testing:DataLayerTests/FullDeviceIntegrationTests
```

#### Running with Physical Device
1. Connect a USB device, MTP device, or mount an SMB share
2. Ensure device has at least 10 MB free space
3. Run tests - they will automatically detect and use available devices
4. Tests will skip gracefully if no devices are available

### Test Behavior

- **Automatic Skipping**: Tests using `skipIfNoDevice()` will automatically skip if no suitable devices are available
- **Device Validation**: Tests validate devices before use (mount status, write permissions, available space)
- **Cleanup**: Tests automatically clean up test artifacts after execution
- **Timeout Handling**: Integration tests have reasonable timeouts for real hardware operations

### Best Practices

1. **Use Test Devices**: Use dedicated test devices, not production devices with important data
2. **Cleanup**: Always clean up test artifacts - the harness provides `cleanupDevice()` for this
3. **Error Handling**: Handle device disconnection gracefully - tests should not fail if device is removed
4. **Timeouts**: Use appropriate timeouts for real hardware operations (30-60 seconds for sync operations)
5. **Conditional Testing**: Use `skipIfNoDevice()` to make tests conditional on device availability

### Troubleshooting

**Tests Skip Unexpectedly**
- Check that a device is connected and mounted
- Verify device has sufficient free space (at least 10 MB)
- Check device write permissions
- Ensure device is not read-only

**Tests Fail with Permission Errors**
- Verify device is writable
- Check macOS permissions for the mount point
- Ensure device is not locked or encrypted

**Tests Timeout**
- Increase timeout values for slow devices
- Check device connection stability
- Verify device is not in use by other processes

### Example Test

```swift
func testGivenUSBDeviceWhenSyncingThenTracksAreTransferred() async throws {
    // Given: USB device
    let device = try await skipIfNoDevice(harness: harness, matching: .usb)
    try await harness.cleanupDevice(device)
    
    // When: Starting sync
    let request = await harness.createTestSyncRequest(device: device, trackCount: 3)
    let job = try await manager.startSync(request: request)
    
    // Wait for completion
    try await waitForJobCompletion(jobId: job.id, timeout: 30.0)
    
    // Then: Verify completion
    let jobs = await manager.jobs()
    let completedJob = try XCTUnwrap(jobs.first { $0.id == job.id })
    XCTAssertEqual(completedJob.status, .completed)
}
```

