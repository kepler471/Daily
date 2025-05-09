//
//  ResetTasksView.swift
//  Daily
//
//  Created by Stelios Georgiou on 08/05/2025.
//

import SwiftUI
import SwiftData

/// A button view that allows users to manually reset all tasks to incomplete
struct ResetTasksView: View {
    // MARK: - Properties
    
    /// Reference to the task reset manager for handling reset operations
    @EnvironmentObject private var taskResetManager: TaskResetManager
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            taskResetManager.resetTasksNow()
        }) {
            Image(systemName: "arrow.clockwise")
                .font(.footnote)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.blue)
                )
        }
        .help("Reset all tasks to incomplete")
        .accessibilityLabel("Reset all tasks")
        .accessibilityHint("Marks all tasks as incomplete to start a new day")
    }
}

// MARK: - Previews

#Preview {
    // Use a simple preview container with in-memory storage
    let previewContainer = try! ModelContainer(
        for: Task.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    return ResetTasksView()
        .environmentObject(TaskResetManager(modelContext: previewContainer.mainContext))
        .padding()
}
