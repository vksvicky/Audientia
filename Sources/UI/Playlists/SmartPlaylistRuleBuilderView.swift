//
//  SmartPlaylistRuleBuilderView.swift
//  Audientia - Smart Playlist Rule Builder View
//
//  View for building smart playlist rules
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import DataLayer
import os.log
import Shared
import SwiftUI

/// Smart playlist rule builder view
/// BDD: As a user, I want to create a playlist of 5-star songs from 2020
@MainActor
public struct SmartPlaylistRuleBuilderView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel: SmartPlaylistRuleBuilderViewModel
    @State private var selectedField: SmartPlaylistRule.Field = .title
    @State private var selectedOperator: SmartPlaylistRule.Operator = .equals
    @State private var ruleValue: String = ""
    @State private var selectedLogicalOperator: SmartPlaylistRule.LogicalOperator?
    @State private var editingRuleIndex: Int?
    
    // MARK: - Initialisation
    
    /// Initialise the rule builder
    /// - Parameter viewModel: Optional ViewModel (for testing)
    public init(viewModel: SmartPlaylistRuleBuilderViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: SmartPlaylistRuleBuilderViewModel())
        }
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView
            
            // Rules list
            if viewModel.rules.isEmpty {
                emptyStateView
            } else {
                rulesListView
            }
            
            // Add rule form
            addRuleFormView
            
            // Build button
            buildButtonView
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            Logger.userInterface.info("SmartPlaylistRuleBuilderView appeared")
        }
        .onDisappear {
            Logger.userInterface.debug("SmartPlaylistRuleBuilderView disappeared")
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Text("Smart Playlist Rules")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            if !viewModel.rules.isEmpty {
                Button(action: {
                    viewModel.clearRules()
                }, label: {
                    Label("Clear All", systemImage: "trash")
                })
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "gearshape")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Rules")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Add rules to create a smart playlist")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Rules List View
    
    private var rulesListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rules")
                .font(.headline)
            
            ForEach(Array(viewModel.rules.enumerated()), id: \.offset) { index, rule in
                RuleRowView(
                    rule: rule,
                    index: index,
                    onEdit: {
                        editingRuleIndex = index
                        selectedField = rule.field
                        selectedOperator = rule.operator
                        ruleValue = rule.value
                        selectedLogicalOperator = rule.logicalOperator
                    },
                    onDelete: {
                        viewModel.removeRule(at: index)
                    }
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Add Rule Form View
    
    private var addRuleFormView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(editingRuleIndex == nil ? "Add Rule" : "Edit Rule")
                .font(.headline)
            
            HStack(spacing: 12) {
                // Field selector
                Picker("Field", selection: $selectedField) {
                    ForEach([
                        SmartPlaylistRule.Field.title,
                        .artist,
                        .album,
                        .genre,
                        .year,
                        .rating,
                        .duration
                    ], id: \.self) { field in
                        Text(fieldDisplayName(field)).tag(field)
                    }
                }
                .frame(width: 120)
                
                // Operator selector
                Picker("Operator", selection: $selectedOperator) {
                    ForEach([
                        SmartPlaylistRule.Operator.equals,
                        .contains,
                        .startsWith,
                        .endsWith,
                        .greaterThan,
                        .lessThan,
                        .greaterThanOrEqual,
                        .lessThanOrEqual,
                        .notEquals
                    ], id: \.self) { op in
                        Text(operatorDisplayName(op)).tag(op)
                    }
                }
                .frame(width: 140)
                
                // Value input
                TextField("Value", text: $ruleValue)
                    .textFieldStyle(.roundedBorder)
                
                // Logical operator (only show if there are existing rules)
                if !viewModel.rules.isEmpty {
                    Picker("", selection: $selectedLogicalOperator) {
                        Text("None").tag(nil as SmartPlaylistRule.LogicalOperator?)
                        Text("AND").tag(SmartPlaylistRule.LogicalOperator.and as SmartPlaylistRule.LogicalOperator?)
                        Text("OR").tag(SmartPlaylistRule.LogicalOperator.or as SmartPlaylistRule.LogicalOperator?)
                    }
                    .frame(width: 80)
                }
            }
            
            HStack {
                if editingRuleIndex != nil {
                    Button("Cancel") {
                        editingRuleIndex = nil
                        resetForm()
                    }
                }
                
                Spacer()
                
                Button(editingRuleIndex == nil ? "Add Rule" : "Update Rule") {
                    if let index = editingRuleIndex {
                        viewModel.updateRule(
                            at: index,
                            field: selectedField,
                            operator: selectedOperator,
                            value: ruleValue,
                            logicalOperator: selectedLogicalOperator
                        )
                        editingRuleIndex = nil
                    } else {
                        viewModel.addRule(
                            field: selectedField,
                            operator: selectedOperator,
                            value: ruleValue,
                            logicalOperator: selectedLogicalOperator
                        )
                    }
                    resetForm()
                }
                .buttonStyle(.borderedProminent)
                .disabled(ruleValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Build Button View
    
    private var buildButtonView: some View {
        HStack {
            Spacer()
            
            Button(action: {
                let rules = viewModel.buildRules()
                Logger.userInterface.info("Built smart playlist rules: \(rules.rules.count) rules")
                // In a full implementation, this would create the smart playlist
            }, label: {
                Label("Create Smart Playlist", systemImage: "checkmark.circle.fill")
            })
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isValid)
        }
    }
    
    // MARK: - Helper Methods
    
    private func resetForm() {
        selectedField = .title
        selectedOperator = .equals
        ruleValue = ""
        selectedLogicalOperator = nil
    }
    
    private func fieldDisplayName(_ field: SmartPlaylistRule.Field) -> String {
        switch field {
        case .title: return "Title"
        case .artist: return "Artist"
        case .album: return "Album"
        case .genre: return "Genre"
        case .year: return "Year"
        case .rating: return "Rating"
        case .playCount: return "Play Count"
        case .dateAdded: return "Date Added"
        case .duration: return "Duration"
        }
    }
    
    private func operatorDisplayName(_ op: SmartPlaylistRule.Operator) -> String {
        switch op {
        case .equals: return "equals"
        case .contains: return "contains"
        case .startsWith: return "starts with"
        case .endsWith: return "ends with"
        case .greaterThan: return ">"
        case .lessThan: return "<"
        case .greaterThanOrEqual: return ">="
        case .lessThanOrEqual: return "<="
        case .notEquals: return "not equals"
        }
    }
}

// MARK: - Rule Row View

private struct RuleRowView: View {
    let rule: SmartPlaylistRule
    let index: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            // Rule number
            Text("\(index + 1).")
                .foregroundColor(.secondary)
                .frame(width: 30)
            
            // Rule display
            VStack(alignment: .leading, spacing: 4) {
                Text(ruleDisplayText)
                    .font(.body)
                
                if let logicalOp = rule.logicalOperator {
                    Text(logicalOp == .and ? "AND" : "OR")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Edit button
            Button(action: onEdit, label: {
                Label("Edit", systemImage: "pencil")
            })
            .buttonStyle(.borderless)
            
            // Delete button
            Button(role: .destructive, action: onDelete, label: {
                Label("Delete", systemImage: "trash")
            })
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(6)
    }
    
    private var ruleDisplayText: String {
        let fieldName = fieldDisplayName(rule.field)
        let opName = operatorDisplayName(rule.operator)
        return "\(fieldName) \(opName) \"\(rule.value)\""
    }
    
    private func fieldDisplayName(_ field: SmartPlaylistRule.Field) -> String {
        switch field {
        case .title: return "Title"
        case .artist: return "Artist"
        case .album: return "Album"
        case .genre: return "Genre"
        case .year: return "Year"
        case .rating: return "Rating"
        case .playCount: return "Play Count"
        case .dateAdded: return "Date Added"
        case .duration: return "Duration"
        }
    }
    
    private func operatorDisplayName(_ op: SmartPlaylistRule.Operator) -> String {
        switch op {
        case .equals: return "equals"
        case .contains: return "contains"
        case .startsWith: return "starts with"
        case .endsWith: return "ends with"
        case .greaterThan: return ">"
        case .lessThan: return "<"
        case .greaterThanOrEqual: return ">="
        case .lessThanOrEqual: return "<="
        case .notEquals: return "not equals"
        }
    }
}
