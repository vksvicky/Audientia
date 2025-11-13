# Performance Tests

Comprehensive performance test suite for Audientia, ensuring all components meet the performance benchmarks defined in the roadmap.

## Overview

This test suite validates that all major operations meet their SLA (Service Level Agreement) requirements as defined in `Documentation/05-roadmap-and-testing-strategy.md`.

## Performance Benchmarks

### Library Operations
- **Scan 10,000 tracks**: < 5 minutes
- **Search 100,000 tracks**: < 100ms (P95)
- **Search 1,000,000 tracks**: < 200ms (P95)
- **Load playlist (1000 tracks)**: < 200ms
- **Indexing 100,000 tracks**: < 30s

### Search Performance
- **Different query types**: < 100ms (P95)
- **Concurrent searches**: 10 searches < 1s
- **Long query strings**: < 100ms (P95)
- **Unicode/special characters**: < 100ms (P95)

### Playback
- **Start playback**: < 100ms
- **Seek accuracy**: ±10ms
- **UI responsiveness**: < 16ms (60fps)

### Tagging
- **Single tag write**: < 100ms
- **Batch 100 tracks**: < 10s
- **Tag read**: < 10ms

### DSP Operations
- **Gain calculation (1000 tracks)**: < 100ms
- **Normalization analysis (44.1kHz, 1s)**: < 50ms
- **Peak/RMS calculations**: < 10ms

### Concurrent Operations
- **Concurrent library operations**: < 5s
- **Concurrent searches**: < 1s for 10 searches

### Database Operations
- **Database queries**: < 1ms per query

### UI Operations
- **UI data updates (filter & sort)**: < 16ms for 60fps

## Test Infrastructure

### PerformanceTestHelpers

Utilities for measuring and reporting performance:

- `measureAsync()` - Measure async operation execution time
- `measureSync()` - Measure sync operation execution time
- `measureMemoryUsage()` - Measure memory usage before/after operations
- `assertPerformanceSLA()` - Assert that performance meets SLA requirements
- `assertAveragePerformance()` - Assert that average performance meets requirements
- `generateReport(slaMetric:)` - Generate human-readable performance reports with configurable SLA metric comparisons

### PerformanceMetrics

Structured metrics including:
- Duration (total, average, min, max)
- Percentiles (P50, P95, P99)
- Memory usage
- CPU usage
- Iteration count

## Running Performance Tests

```bash
# Run all performance tests
xcodebuild test -scheme Audientia -only-testing:AudioCoreTests/PerformanceTestSuite

# Run specific performance test
xcodebuild test -scheme Audientia -only-testing:AudioCoreTests/PerformanceTestSuite/testLibraryScanPerformance
```

## CI Integration

Performance tests are integrated into the CI pipeline to detect performance regressions. Tests that exceed their SLA will fail the build.

## Best Practices

1. **Warm-up iterations**: Some tests include warm-up iterations to account for JIT compilation and caching
2. **Multiple iterations**: Tests run multiple iterations to get statistical significance (P50, P95, P99)
3. **Memory profiling**: Memory usage is tracked to detect memory leaks
4. **Realistic data**: Tests use realistic data sizes and patterns

## Adding New Performance Tests

When adding new performance tests:

1. Define the SLA requirement based on roadmap benchmarks
2. Use `PerformanceTestHelpers.measureAsync()` or `measureSync()`
3. Use `assertPerformanceSLA()` or `assertAveragePerformance()` to validate
4. Include `generateReport(slaMetric:)` for visibility in test output and consistent SLA evaluation
5. Document the SLA in both the test and the roadmap

Example:

```swift
import os.log

func testNewFeaturePerformance() async {
    let (_, metrics) = await PerformanceTestHelpers.measureAsync(iterations: 100) {
        // Your operation here
    }
    
    PerformanceTestHelpers.assertPerformanceSLA(
        metrics: metrics,
        maxDuration: 0.1, // 100ms
        maxP95Duration: 0.1
    )
    
    let report = PerformanceTestHelpers.generateReport(
        testName: "New Feature",
        metrics: metrics,
        sla: 0.1,
        slaMetric: .p95
    )
    Logger.testing.info("\(report)")
}
```

