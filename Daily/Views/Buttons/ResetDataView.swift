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
    
    /// The notification manager for handling notification cancellation
    @EnvironmentObject private var notificationManager: NotificationManager
    
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
        Task {
            // First cancel all notifications to prevent orphaned notifications
            await notificationManager.cancelAllTodoNotifications()
            
            // Delete all todos
            do {
                try modelContext.delete(model: Todo.self)
                
                // Re-add sample data
                try TodoMockData.createSampleTodos(in: modelContext)
                
                // Sync notifications with the database to handle the new todos
                let todos = try modelContext.fetchTodos()
                await notificationManager.synchronizeNotificationsWithDatabase(todos: todos)
                
                // Call the onReset callback if provided
                onReset?()
            } catch {
                print("Error resetting data: \(error)")
            }
        }
    }
}

// MARK: - Previews

#Preview {
    ResetDataView()
        .environmentObject(NotificationManager.shared)
        .padding()
}
