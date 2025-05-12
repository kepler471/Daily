//
//  ResetDataView.swift
//  Daily
//
//  Created by Stelios Georgiou on 06/05/2025.
//

import SwiftUI
import SwiftData

/// A button view that allows users to reset all data and recreate sample todos
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
        #if os(macOS)
        .help("Reset all data to default")
        #endif
        .accessibilityLabel("Reset all data")
        .accessibilityHint("Deletes all todos and recreates sample data")
    }
    
    // MARK: - Data Operations
    
    /// Resets all data by deleting all todos and recreating sample todos
    private func resetData() {
        // Delete all todos
        do {
            try modelContext.delete(model: Todo.self)
            
            // Re-add sample data
            try TodoMockData.createSampleTodos(in: modelContext)
            
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
