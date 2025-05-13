//
//  ResetTodosView.swift
//  Daily
//
//  Created by Stelios Georgiou on 08/05/2025.
//

import SwiftUI
import SwiftData

/// A button view that allows users to manually reset all todos to incomplete
struct ResetTodosView: View {
    // MARK: - Properties
    
    /// Reference to the todo reset manager for handling reset operations
    @EnvironmentObject private var todoResetManager: TodoResetManager
    
    /// The notification manager for handling notification synchronization
    @EnvironmentObject private var notificationManager: NotificationManager
    
    /// The model context for database operations (used for syncing notifications)
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Body
    
    var body: some View {
        Button(action: resetTodos) {
            Image(systemName: "arrow.clockwise")
                .font(.footnote)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.blue)
                )
        }
        #if os(macOS)
        .help("Reset all todos to incomplete")
        #endif
        .accessibilityLabel("Reset all todos")
        .accessibilityHint("Marks all todos as incomplete to start a new day")
    }
    
    // MARK: - Actions
    
    /// Resets todos and synchronizes notifications
    private func resetTodos() {
        // First reset the todos
        todoResetManager.resetTodosNow()
        
        // Then synchronize notifications with the database
        Task {
            do {
                let todos = try modelContext.fetchTodos()
                await notificationManager.synchronizeNotificationsWithDatabase(todos: todos)
            } catch {
                print("Error syncing notifications after reset: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Previews

#Preview {
    // Use a simple preview container with in-memory storage
    let previewContainer = try! ModelContainer(
        for: Todo.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    return ResetTodosView()
        .environmentObject(TodoResetManager(modelContext: previewContainer.mainContext))
        .environmentObject(NotificationManager.shared)
        .modelContainer(previewContainer)
        .padding()
}
