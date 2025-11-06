//
//  ModuleVersionConflictView.swift
//  Audientia
//
//  UI component to display module version conflicts
//

import Shared
import SwiftUI

struct ModuleVersionConflictView: View {
    @ObservedObject var settings: AppSettings
    @State private var isExpanded = false

    var body: some View {
        if !settings.moduleConflictWarnings.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Module Version Conflicts")
                        .font(.headline)
                    Spacer()
                    Button {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    }
                }

                if isExpanded {
                    ForEach(Array(settings.moduleConflictWarnings.values), id: \.id) { warning in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(warning.moduleName)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text("Kept: \(warning.latestVersion)")
                                .font(.caption)
                                .foregroundColor(.green)

                            Text("Removed: \(warning.removedVersions.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.red)

                            Text("Time: \(warning.timestamp, style: .time)")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Button("Dismiss") {
                                settings.clearConflictWarning(for: warning.moduleName)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
            .padding()
            .background(Color.orange.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    // Preview with sample data
    let warning = ModuleConflictWarning(
        moduleName: "AudioCore",
        latestVersion: "2025.01.0023",
        removedVersions: ["2025.01.0015", "2025.01.0010"],
        timestamp: Date()
    )
    let previewSettings = AppSettings.shared
    previewSettings.moduleConflictWarnings = ["AudioCore": warning]

    return ModuleVersionConflictView(settings: previewSettings)
        .padding()
}
