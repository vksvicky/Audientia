//
//  LibraryStatisticsViewModel.swift
//  Audientia
//
//  ViewModel for library statistics
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import DataLayer
import Foundation
import SwiftUI

/// ViewModel for library statistics
@MainActor
public final class LibraryStatisticsViewModel: ObservableObject {
    @Published public private(set) var statistics: LibraryStatistics?
    @Published public private(set) var isLoading = false
    
    private let statisticsCalculator: any LibraryStatisticsProtocol
    
    public init(statisticsCalculator: any LibraryStatisticsProtocol) {
        self.statisticsCalculator = statisticsCalculator
    }
    
    public func loadStatistics() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            statistics = try await statisticsCalculator.calculateStatistics()
        } catch {
            // Handle error silently for now - could add error state if needed
            statistics = nil
        }
    }
}
