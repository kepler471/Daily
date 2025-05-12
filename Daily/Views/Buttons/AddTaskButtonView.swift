//
//  AddTaskView.swift
//  Daily
//
//  Created by Stelios Georgiou on 06/05/2025.
//

import SwiftUI
import SwiftData
import UserNotifications

/// A button view that triggers the task creation overlay
struct AddTaskButtonView: View {
    // MARK: - Properties

    /// State to control the presentation of the add task overlay
    @State private var showingAddTask = false

    /// The color theme for the button (defaults to blue)
    var color: Color = .blue

    // MARK: - Body

    var body: some View {
        ZStack {
            // Add task button
            Button {
                showingAddTask = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(color.opacity(0.15))
                    )
                    .padding(4)
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            .focusable(false)
            .accessibilityLabel("Add new task")

            // Add task overlay when active
            if showingAddTask {
                AddTaskView(isPresented: $showingAddTask)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingAddTask)
    }
}

// MARK: - Previews
#Preview("Add Task Button") {
    AddTaskButtonView()
        .padding()
}
