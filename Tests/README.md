# Tests Directory

Test code for Audientia, organized by module.

## Structure

```
Tests/
├── SharedTests/      # Tests for Shared framework
│   ├── Models/      # Model tests (Track, Album, Artist, Playlist)
│   └── TestInfrastructure/ # Test utilities, mocks, fixtures
└── [Future test targets]
    ├── UITests/
    ├── AudioCoreTests/
    ├── DataLayerTests/
    └── ...
```

## Testing Strategy

Audientia follows a comprehensive testing strategy using TDD, BDD, and ATDD principles with the Right-BICEP framework:

### Right-BICEP Principles

1. **[Right]** - Are the Results Right?
   - Verify expected outputs match actual outputs
   - Test happy paths and normal operations

2. **Right-[B]ICEP** - Boundary Conditions
   - Test edge cases (empty, null, max values)
   - Test boundary values (0, 1, -1, max, min)

3. **Right-B[I]CEP** - Inverse Relationships
   - Test reverse operations (encode/decode, save/load)
   - Verify bidirectional relationships

4. **Right-BI[C]EP** - Cross-Checking Using Other Means
   - Verify results using alternative methods
   - Compare with known good implementations

5. **Right-BIC[E]P** - Forcing Error Conditions
   - Test error handling and recovery
   - Test invalid inputs and failure modes

6. **Right-BICE[P]** - Performance Characteristics
   - Test performance with large datasets
   - Verify time and space complexity

7. **Edge Cases**
   - Test unusual but valid inputs
   - Test concurrent operations
   - Test resource constraints

## Test Infrastructure

### MockFactories
Provides factory methods for creating test data:
- `makeTrack()` - Create mock Track objects
- `makeAlbum()` - Create mock Album objects
- `makeArtist()` - Create mock Artist objects
- `makePlaylist()` - Create mock Playlist objects

### TestFixtures
JSON fixtures and helper methods for decoding:
- Sample JSON data for testing Codable conformance
- Helper methods for loading and parsing fixtures

## Running Tests

### All Tests
```bash
xcodebuild test -project Audientia.xcodeproj -scheme Audientia
```

### Specific Test Target
```bash
xcodebuild test -project Audientia.xcodeproj -scheme Audientia -only-testing:SharedTests
```

### In Xcode
- Press ⌘U to run all tests
- Use Test Navigator (⌘6) to run specific tests
- Enable parallel test execution in scheme settings

## Test Coverage Goals

- **Unit Tests**: 80%+ coverage for core logic
- **Integration Tests**: All major workflows
- **Performance Tests**: Critical paths (library scanning, search, playback)

## Best Practices

1. **Test First**: Write tests before implementation (TDD)
2. **Descriptive Names**: Test names should describe what they test
3. **One Assertion**: Each test should verify one behavior
4. **Isolation**: Tests should be independent and runnable in any order
5. **Mocking**: Use mocks for external dependencies
6. **Fixtures**: Use fixtures for complex test data

See [`../Documentation/05-roadmap-and-testing-strategy.md`](../Documentation/05-roadmap-and-testing-strategy.md) for detailed testing guidelines.

