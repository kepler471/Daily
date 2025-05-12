//
//  TodoCardView.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import SwiftUI
import SwiftData
import UserNotifications

// MARK: - Todo Card View

/// A card view that displays a single todo with its details and actions
///
/// TodoCardView is responsible for:
/// - Displaying the todo's title, category, and scheduled time (if any)
/// - Showing a different visual appearance for completed vs. incomplete todos
/// - Providing a button to toggle the todo's completion status
/// - Creating a visually attractive card with appropriate styling based on todo properties
struct TodoView: View {
    // MARK: Properties

    /// The todo to display, using @Bindable for two-way binding
    @Bindable var todo: Todo

    /// Settings manager for notification preferences
    @EnvironmentObject private var settingsManager: SettingsManager

    /// Callback that's invoked when the completion status is toggled
    var onToggleComplete: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: Header Row
            
            // Todo title and metadata in a row
            HStack {
                // Todo title with strikethrough when completed
                Text(todo.title)
                    .font(.headline)
                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                    .strikethrough(todo.isCompleted)
                
                Spacer()
                
                // Scheduled time with clock icon (if available)
                if let scheduledTime = todo.scheduledTime {
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
    
    /// Background for the card that changes based on todo completion status
    private var cardBackground: some View {
        Group {
            if todo.isCompleted {
                // Completed todo style - faded with gray border
                Color(.windowBackgroundColor).opacity(0.8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else {
                // Active todo style - gradient border based on category
                Color(.windowBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        todo.category == .required ? .blue.opacity(0.5) : .purple.opacity(0.5),
                                        todo.category == .required ? .teal.opacity(0.3) : .pink.opacity(0.3)
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
    
    /// Badge that displays the todo category (Required/Suggested)
    private var categoryBadge: some View {
        Text(todo.category == .required ? "Required" : "Suggested")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(todo.category == .required ? Color.blue.opacity(0.2) : Color.purple.opacity(0.2))
            )
            .foregroundColor(todo.category == .required ? .blue : .purple)
    }
    
    /// Button for toggling todo completion status
    private var completionButton: some View {
        Button(action: onToggleComplete) {
            HStack(spacing: 4) {
                Image(systemName: todo.isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle")
                Text(todo.isCompleted ? "Reopen" : "Complete")
            }
            .font(.footnote)
            .fontWeight(.medium)
            .foregroundColor(todo.isCompleted ? .orange : .green)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(todo.isCompleted ? Color.orange.opacity(0.1) : Color.green.opacity(0.1))
            )
        }
    }
}

// MARK: - Previews

#Preview("Todo Card") {
    let container = TodoMockData.createPreviewContainer()
    let context = ModelContext(container)
    let todo = Todo(
        title: "Morning Meditation",
        order: 1,
        category: .required,
        scheduledTime: Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date())
    )
    context.insert(todo)

    return TodoView(todo: todo, onToggleComplete: {})
        .frame(width: 350)
        .padding()
        .environmentObject(SettingsManager())
}
