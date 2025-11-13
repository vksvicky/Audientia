import XCTest

final class PerformanceTestHelpersTests: XCTestCase {
    func testGenerateReportUsesAverageMetric() {
        let metrics = PerformanceMetrics(
            duration: 1.0,
            iterations: 2,
            durations: [0.4, 0.6]
        )

        let report = PerformanceTestHelpers.generateReport(
            testName: "Average SLA",
            metrics: metrics,
            sla: 0.7,
            slaMetric: .average
        )

        XCTAssertTrue(report.contains("SLA (average): 0.700s - ✅ PASS"))
        XCTAssertTrue(report.contains("Measured: 0.500s"))
    }

    func testGenerateReportUsesTotalMetricByDefault() {
        let metrics = PerformanceMetrics(
            duration: 1.0,
            iterations: 1,
            durations: [1.0]
        )

        let report = PerformanceTestHelpers.generateReport(
            testName: "Total SLA",
            metrics: metrics,
            sla: 0.5
        )

        XCTAssertTrue(report.contains("SLA (total): 0.500s - ❌ FAIL"))
        XCTAssertTrue(report.contains("Measured: 1.000s"))
    }
}
