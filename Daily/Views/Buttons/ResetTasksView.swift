//
//  ResetTasksView.swift
//  Daily
//
//  Created by Claude on 08/05/2025.
//

import SwiftUI
import SwiftData

struct ResetTasksView: View {
    @EnvironmentObject private var taskResetManager: TaskResetManager
    
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
    }
}

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
