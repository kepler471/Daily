//
//  TaskCardView.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import SwiftUI
import SwiftData

// MARK: - Task Card View

/// A card view that displays a single task with its details and actions
///
/// TaskCardView is responsible for:
/// - Displaying the task's title, category, and scheduled time (if any)
/// - Showing a different visual appearance for completed vs. incomplete tasks
/// - Providing a button to toggle the task's completion status
/// - Creating a visually attractive card with appropriate styling based on task properties
struct TaskCardView: View {
    // MARK: Properties
    
    /// The task to display, using @Bindable for two-way binding
    @Bindable var task: Task
    
    /// Callback that's invoked when the completion status is toggled
    var onToggleComplete: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: Header Row
            
            // Task title and metadata in a row
            HStack {
                // Task title with strikethrough when completed
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)
                
                Spacer()
                
                // Scheduled time with clock icon (if available)
                if let scheduledTime = task.scheduledTime {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        
                        Text(scheduledTime, format: .dateTime.hour().minute())
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                }
                
                Spacer()
                
                // Category badge (Required/Suggested)
                categoryBadge
            }
            
            // MARK: Action Row
            
            // Action buttons row
            HStack {
                Spacer()
                
                // Complete/reopen button
                completionButton
            }
        }
        // MARK: Card Styling
        .padding()
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .contentShape(Rectangle()) // Makes the whole card tappable
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
    
    // MARK: - UI Components
    
    /// Background for the card that changes based on task completion status
    private var cardBackground: some View {
        Group {
            if task.isCompleted {
                // Completed task style - faded with gray border
                Color(.windowBackgroundColor).opacity(0.8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else {
                // Active task style - gradient border based on category
                Color(.windowBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        task.category == .required ? .blue.opacity(0.5) : .purple.opacity(0.5),
                                        task.category == .required ? .teal.opacity(0.3) : .pink.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            }
        }
    }
    
    /// Badge that displays the task category (Required/Suggested)
    private var categoryBadge: some View {
        Text(task.category == .required ? "Required" : "Suggested")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(task.category == .required ? Color.blue.opacity(0.2) : Color.purple.opacity(0.2))
            )
            .foregroundColor(task.category == .required ? .blue : .purple)
    }
    
    /// Button for toggling task completion status
    private var completionButton: some View {
        Button(action: onToggleComplete) {
            HStack(spacing: 4) {
                Image(systemName: task.isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle")
                Text(task.isCompleted ? "Reopen" : "Complete")
            }
            .font(.footnote)
            .fontWeight(.medium)
            .foregroundColor(task.isCompleted ? .orange : .green)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(task.isCompleted ? Color.orange.opacity(0.1) : Color.green.opacity(0.1))
            )
        }
    }
}

// MARK: - Previews

#Preview("Task Card") {
    let container = TaskMockData.createPreviewContainer()
    let context = ModelContext(container)
    let task = Task(
        title: "Morning Meditation",
        order: 1,
        category: .required,
        scheduledTime: Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date())
    )
    context.insert(task)
    
    return TaskCardView(task: task, onToggleComplete: {})
        .frame(width: 350)
        .padding()
}
