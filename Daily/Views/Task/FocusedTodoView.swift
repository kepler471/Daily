//
//  FocusedTaskView.swift
//  Daily
//
//  Created by Stelios Georgiou on 09/05/2025.
//

import SwiftUI
import SwiftData

// MARK: - Focused Task View

/// A fullscreen overlay view that displays a task in detail
///
/// FocusedTaskView provides a modal interface for:
/// - Viewing a task in detail
/// - Marking the task as complete
/// - Interacting with the task with visual feedback
struct FocusedTodoView: View {
    // MARK: Properties

    /// Database context for saving task changes
    @Environment(\.modelContext) private var modelContext

    /// The specific task to display, or nil to show the top required task
    var selectedTask: Todo?

    /// Live query for required tasks, sorted by order (used when no specific task is provided)
    @Query private var requiredTasks: [Todo]

    /// Binding to control the visibility of this view
    @Binding var isPresented: Bool

    /// Tracks if the task is being hovered for hover effects
    @State private var isHovered: Bool = false

    /// Whether the edit task view is being displayed
    @State private var showingEditTask: Bool = false

    // MARK: - Initialization

    /// Creates a new focused task view that shows a specific task or the top required task
    /// - Parameters:
    ///   - task: Optional specific task to display
    ///   - isPresented: Binding to control the visibility of the view
    init(task: Todo? = nil, isPresented: Binding<Bool>) {
        self.selectedTask = task
        self._isPresented = isPresented

        // Configure sorting to ensure consistent display order
        let sortDescriptors = [
            SortDescriptor(\Todo.order),
            SortDescriptor(\Todo.createdAt)
        ]

        // Query to get required tasks that are not completed
        _requiredTasks = Query(
            filter: Todo.Predicates.byCategoryAndCompletion(category: .required, isCompleted: false),
            sort: sortDescriptors
        )
    }

    // MARK: - Computed Properties

    /// Returns the task to display - either the selected task or the top required task
    private var taskToDisplay: Todo? {
        return selectedTask ?? requiredTasks.first
    }
    
    // MARK: - View Body
    
    var body: some View {
        ZStack {
            // MARK: Background

            // Translucent blurred background overlay that can be tapped to dismiss
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    // Close the view when tapping on the background
                    isPresented = false
                }

            // MARK: Content

            VStack(spacing: 20) {
                // MARK: Task Display

                if let task = taskToDisplay {
                    // Display the task
                    focusedTaskCard(for: task)
                        .scaleEffect(isHovered ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
                        .onHover { hovering in
                            isHovered = hovering
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                } else {
                    // Empty state
                    Spacer()
                    Text("No required tasks")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                }
            }
            .padding(.top, 40)
        }
        .overlay {
            if let task = taskToDisplay, showingEditTask {
                EditTaskView(task: task, isPresented: $showingEditTask)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingEditTask)
        .withCloseButton(
            action: { isPresented = false },
            size: 36,           // Bigger button (default is 28)
            iconSize: 18        // Bigger X icon (default is 14)
        )
    }
    
    // MARK: - Task Card View
    
    /// Creates a card view for the focused task
    /// - Parameter task: The task to display
    /// - Returns: A SwiftUI view representing the task card
    @ViewBuilder
    private func focusedTaskCard(for task: Todo) -> some View {
        VStack(spacing: 20) {
            // MARK: Task Details
            
            // Task title and scheduled time (if exists)
            VStack(alignment: .center, spacing: 8) {
                Text(task.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                if let scheduledTime = task.scheduledTime {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        
                        Text(scheduledTime, format: .dateTime.hour().minute())
                            .foregroundColor(.secondary)
                    }
                    .font(.headline)
                }
            }
            .padding(.bottom, 20)
            
            // MARK: Category Badge

            Text(task.category == .required ? "Required" : "Suggested")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(task.category == .required ? Color.blue.opacity(0.2) : Color.purple.opacity(0.2))
                )
                .foregroundColor(task.category == .required ? .blue : .purple)
            
            // MARK: Action Buttons

            HStack(spacing: 20) {
                // Complete Button
                Button(action: {
                    toggleTaskCompletion(task)
                    // Close the view after marking as complete
                    isPresented = false
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                        Text("Mark as Complete")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.green)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Mark \(task.title) as complete")

                // Edit Button (Three Dots)
                Button(action: {
                    showingEditTask = true
                }) {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Edit task \(task.title)")
            }
        }
        .padding(40)
        .background(
            Rectangle()
                .fill(.regularMaterial)
                .opacity(0.9)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .contentShape(Rectangle())
        .allowsHitTesting(true) // Ensure taps on the card don't pass through
    }
    
    // MARK: - Actions
    
    /// Toggles the completion state of a task and saves the change
    /// - Parameter task: The task to toggle
    private func toggleTaskCompletion(_ task: Todo) {
        // Toggle task completion state
        task.isCompleted.toggle()

        do {
            // Save the changes to the model
            try modelContext.save()

            // Add a small delay to allow the UI to update
            // This helps the SwiftData change notifications propagate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // This is just to trigger a UI refresh
                withAnimation {
                    // No need to do anything here - just triggering a refresh
                }

                // If the task is being completed (not reopened), post notification for animation
                if task.isCompleted {
                    // Post a notification to trigger completion animation in TaskStackView
                    print("📣 FocusedTaskView: Posting taskCompletedExternally notification for task: \(task.title)")
                    print("📣 FocusedTaskView: Task UUID: \(task.uuid.uuidString)")

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        NotificationCenter.default.post(
                            name: .taskCompletedExternally,
                            object: nil,
                            userInfo: ["completedTaskId": task.uuid.uuidString]
                        )
                    }
                }
            }
        } catch {
            print("Error toggling task completion: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

#Preview("Focused Task") {
    FocusedTodoView(isPresented: .constant(true))
        .modelContainer(TaskMockData.createPreviewContainer())
}
