//
//  PerformanceTestHelpers.swift
//  Audientia - Performance Test Infrastructure
//
//  Utilities for performance testing and benchmarking
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Darwin
import Foundation
import XCTest

/// Performance metrics collected during testing
public struct PerformanceMetrics {
    public let duration: TimeInterval
    public let memoryUsage: UInt64? // in bytes
    public let cpuUsage: Double? // percentage
    public let iterations: Int
    public let averageDuration: TimeInterval
    public let minDuration: TimeInterval
    public let maxDuration: TimeInterval
    public let p50Duration: TimeInterval
    public let p95Duration: TimeInterval
    public let p99Duration: TimeInterval
    
    public init(
        duration: TimeInterval,
        memoryUsage: UInt64? = nil,
        cpuUsage: Double? = nil,
        iterations: Int = 1,
        durations: [TimeInterval] = []
    ) {
        self.duration = duration
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
        self.iterations = iterations
        
        if !durations.isEmpty {
            let sorted = durations.sorted()
            self.averageDuration = durations.reduce(0, +) / Double(durations.count)
            self.minDuration = sorted.first ?? duration
            self.maxDuration = sorted.last ?? duration
            self.p50Duration = sorted[sorted.count / 2]
            self.p95Duration = sorted[Int(Double(sorted.count) * 0.95)]
            self.p99Duration = sorted[Int(Double(sorted.count) * 0.99)]
        } else {
            self.averageDuration = duration
            self.minDuration = duration
            self.maxDuration = duration
            self.p50Duration = duration
            self.p95Duration = duration
            self.p99Duration = duration
        }
    }
    
    /// Human-readable description of metrics
    public var description: String {
        var parts: [String] = []
        parts.append(String(format: "Duration: %.3fs", duration))
        if iterations > 1 {
            parts.append(String(format: "Iterations: %d", iterations))
            parts.append(String(format: "Avg: %.3fs", averageDuration))
            parts.append(String(format: "Min: %.3fs", minDuration))
            parts.append(String(format: "Max: %.3fs", maxDuration))
            parts.append(String(format: "P50: %.3fs", p50Duration))
            parts.append(String(format: "P95: %.3fs", p95Duration))
            parts.append(String(format: "P99: %.3fs", p99Duration))
        }
        if let memory = memoryUsage {
            parts.append(String(format: "Memory: %.2f MB", Double(memory) / 1_000_000.0))
        }
        if let cpu = cpuUsage {
            parts.append(String(format: "CPU: %.1f%%", cpu))
        }
        return parts.joined(separator: ", ")
    }
}

/// Helper for performance testing and benchmarking
@MainActor
public final class PerformanceTestHelpers {
    
    /// Measure execution time of an async operation
    public static func measureAsync<T>(
        operation: () async throws -> T,
        iterations: Int = 1
    ) async rethrows -> (result: T, metrics: PerformanceMetrics) {
        var durations: [TimeInterval] = []
        var result: T!
        
        for _ in 0..<iterations {
            let startTime = Date()
            result = try await operation()
            let duration = Date().timeIntervalSince(startTime)
            durations.append(duration)
        }
        
        let totalDuration = durations.reduce(0, +)
        let metrics = PerformanceMetrics(
            duration: totalDuration,
            iterations: iterations,
            durations: durations
        )
        
        return (result, metrics)
    }
    
    /// Measure execution time of a sync operation
    public static func measureSync<T>(
        operation: () throws -> T,
        iterations: Int = 1
    ) rethrows -> (result: T, metrics: PerformanceMetrics) {
        var durations: [TimeInterval] = []
        var result: T!
        
        for _ in 0..<iterations {
            let startTime = Date()
            result = try operation()
            let duration = Date().timeIntervalSince(startTime)
            durations.append(duration)
        }
        
        let totalDuration = durations.reduce(0, +)
        let metrics = PerformanceMetrics(
            duration: totalDuration,
            iterations: iterations,
            durations: durations
        )
        
        return (result, metrics)
    }
    
    /// Measure memory usage before and after an operation
    public static func measureMemoryUsage<T>(
        operation: () async throws -> T
    ) async rethrows -> MemoryUsageResult<T> {
        let before = getMemoryUsage()
        let result = try await operation()
        let after = getMemoryUsage()
        let delta = Int64(after) - Int64(before)
        
        return MemoryUsageResult(
            result: result,
            before: before,
            after: after,
            delta: delta
        )
    }
    
    /// Result of memory usage measurement
    public struct MemoryUsageResult<T> {
        public let result: T
        public let before: UInt64
        public let after: UInt64
        public let delta: Int64
    }
    
    /// Get current memory usage in bytes
    public static func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        
        if kerr == KERN_SUCCESS {
            return UInt64(info.resident_size)
        } else {
            return 0
        }
    }
    
    /// Assert that performance meets SLA requirements
    nonisolated public static func assertPerformanceSLA(
        metrics: PerformanceMetrics,
        maxDuration: TimeInterval,
        maxP95Duration: TimeInterval? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertLessThanOrEqual(
            metrics.duration,
            maxDuration,
            "Total duration exceeded SLA: \(metrics.description)",
            file: file,
            line: line
        )
        
        if let maxP95 = maxP95Duration, metrics.iterations > 1 {
            XCTAssertLessThanOrEqual(
                metrics.p95Duration,
                maxP95,
                "P95 duration exceeded SLA: \(metrics.description)",
                file: file,
                line: line
            )
        }
    }
    
    /// Assert that average performance meets requirements
    nonisolated public static func assertAveragePerformance(
        metrics: PerformanceMetrics,
        maxAverageDuration: TimeInterval,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertLessThanOrEqual(
            metrics.averageDuration,
            maxAverageDuration,
            "Average duration exceeded requirement: \(metrics.description)",
            file: file,
            line: line
        )
    }
    
    /// Generate performance report
    nonisolated public static func generateReport(
        testName: String,
        metrics: PerformanceMetrics,
        sla: TimeInterval? = nil
    ) -> String {
        var report = """
        Performance Report: \(testName)
        ==========================================
        \(metrics.description)
        """
        
        if let sla = sla {
            let meetsSLA = metrics.duration <= sla
            report += "\nSLA: \(String(format: "%.3fs", sla)) - \(meetsSLA ? "✅ PASS" : "❌ FAIL")"
        }
        
        return report
    }
}

// MARK: - XCTest Extensions

extension XCTestCase {
    /// Measure and assert performance with SLA
    public func measurePerformance<T>(
        operation: () async throws -> T,
        iterations: Int = 1,
        maxDuration: TimeInterval,
        maxP95Duration: TimeInterval? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) async rethrows -> T {
        let (result, metrics) = try await PerformanceTestHelpers.measureAsync(
            operation: operation,
            iterations: iterations
        )
        
        PerformanceTestHelpers.assertPerformanceSLA(
            metrics: metrics,
            maxDuration: maxDuration,
            maxP95Duration: maxP95Duration,
            file: file,
            line: line
        )
        
        return result
    }
    
    /// Measure and assert average performance
    public func measureAveragePerformance<T>(
        operation: () async throws -> T,
        iterations: Int = 10,
        maxAverageDuration: TimeInterval,
        file: StaticString = #file,
        line: UInt = #line
    ) async rethrows -> T {
        let (result, metrics) = try await PerformanceTestHelpers.measureAsync(
            operation: operation,
            iterations: iterations
        )
        
        PerformanceTestHelpers.assertAveragePerformance(
            metrics: metrics,
            maxAverageDuration: maxAverageDuration,
            file: file,
            line: line
        )
        
        return result
    }
}
