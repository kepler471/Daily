//
//  ResetDataView.swift
//  Daily
//
//  Created by Stelios Georgiou on 06/05/2025.
//

import SwiftUI
import SwiftData

/// A button view that allows users to reset all data and recreate sample tasks
struct ResetDataView: View {
    // MARK: - Properties
    
    /// The model context for database operations
    @Environment(\.modelContext) private var modelContext
    
    /// Optional callback that gets triggered after data reset
    var onReset: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        Button(action: resetData) {
            Image(systemName: "trash")
                .font(.footnote)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.red)
                )
        }
        .help("Reset all data to default")
        .accessibilityLabel("Reset all data")
        .accessibilityHint("Deletes all tasks and recreates sample data")
    }
    
    // MARK: - Data Operations
    
    /// Resets all data by deleting all tasks and recreating sample tasks
    private func resetData() {
        // Delete all tasks
        do {
            try modelContext.delete(model: Task.self)
            
            // Re-add sample data
            try TaskMockData.createSampleTasks(in: modelContext)
            
            // Call the onReset callback if provided
            onReset?()
        } catch {
            print("Error resetting data: \(error)")
        }
    }
}

// MARK: - Previews

#Preview {
    ResetDataView()
        .padding()
}
