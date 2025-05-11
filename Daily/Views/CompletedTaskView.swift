//
//  CompletedTaskView.swift
//  Daily
//
//  Created by Stelios Georgiou on 07/05/2025.
//

import SwiftUI
import SwiftData

// MARK: - Completed Task View

/// A fullscreen overlay view that displays all completed tasks
///
/// CompletedTaskView provides a modal interface for:
/// - Viewing all completed tasks in a specific category (or all categories)
/// - Reopening completed tasks when needed
/// - Showing task details with interactive hover effects
struct CompletedTaskView: View {
    // MARK: Properties
    
    /// Database context for saving task changes
    @Environment(\.modelContext) private var modelContext
    
    /// Live query for completed tasks, sorted by order
    @Query private var completedTasks: [Task]
    
    /// Optional category filter - if nil, shows all completed tasks
    let category: TaskCategory?
    
    /// Binding to control the visibility of this view
    @Binding var isPresented: Bool
    
    /// Tracks the currently hovered task for hover effects
    @State private var hoveredTaskId: PersistentIdentifier? = nil
    
    // MARK: - Initialization
    
    /// Creates a new completed tasks view with optional category filtering
    /// - Parameters:
    ///   - category: Optional category to filter tasks by
    ///   - isPresented: Binding to control the visibility of the view
    init(category: TaskCategory? = nil, isPresented: Binding<Bool>) {
        self.category = category
        self._isPresented = isPresented
        
        // Configure sorting to ensure consistent display order
        let sortDescriptors = [
            SortDescriptor(\Task.order),
            SortDescriptor(\Task.createdAt)
        ]
        
        // Set up the appropriate query based on category
        if let category = category {
            // Category-specific query using predefined predicates
            _completedTasks = Query(
                filter: Task.Predicates.byCategoryAndCompletion(category: category, isCompleted: true),
                sort: sortDescriptors
            )
        } else {
            // All completed tasks across categories
            _completedTasks = Query(
                filter: Task.Predicates.byCompletion(isCompleted: true),
                sort: sortDescriptors
            )
        }
    }
    
    // MARK: - Computed Properties
    
    /// Generates the view title based on selected category
    private var categoryTitle: String {
        switch category {
        case .required:
            return "Completed Required Tasks"
        case .suggested:
            return "Completed Suggested Tasks"
        case nil:
            return "All Completed Tasks"
        }
    }
    
    // MARK: - View Body
    
    var body: some View {
        ZStack {
            // MARK: Background

            // Translucent blurred background overlay
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.85)
                .ignoresSafeArea()

            // MARK: Content

            VStack(spacing: 20) {
                // Title section
                Text(categoryTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
                
                // MARK: Task List
                
                if completedTasks.isEmpty {
                    // Empty state
                    Spacer()
                    Text("No completed tasks")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                } else {
                    // Scrollable task list
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(completedTasks) { task in
                                completedTaskCard(for: task)
                                    .scaleEffect(hoveredTaskId == task.persistentModelID ? 1.05 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hoveredTaskId)
                                    .onHover { isHovered in
                                        hoveredTaskId = isHovered ? task.persistentModelID : nil
                                    }
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                    }
                }
            }
            .padding(.top, 40)
        }
        .withCloseButton(
            action: { isPresented = false },
            size: 36,           // Bigger button (default is 28)
            iconSize: 18        // Bigger X icon (default is 14)
        )
    }
    
    // MARK: - Task Card View
    
    /// Creates a card view for a completed task
    /// - Parameter task: The completed task to display
    /// - Returns: A SwiftUI view representing the task card
    @ViewBuilder
    private func completedTaskCard(for task: Task) -> some View {
        HStack {
            // MARK: Task Details
            
            // Task title and scheduled time (if exists)
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .strikethrough(task.isCompleted)
                
                if let scheduledTime = task.scheduledTime {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        
                        Text(scheduledTime, format: .dateTime.hour().minute())
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                }
            }
            
            Spacer()
            
            // MARK: Category Badge
            
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
            
            // MARK: Reopen Button
            
            Button(action: {
                toggleTaskCompletion(task)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward.circle")
                    Text("Reopen")
                }
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.1))
                )
            }
            .accessibilityLabel("Reopen \(task.title)")
        }
        .padding()
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
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Actions
    
    /// Toggles the completion state of a task and saves the change
    /// - Parameter task: The task to toggle
    private func toggleTaskCompletion(_ task: Task) {
        // Toggle task completion state
        task.isCompleted.toggle()
        
        do {
            // Save the changes to the model
            try modelContext.save()
            
            // Add a small delay to allow the UI to update
            // This helps the SwiftData change notifications propagate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // This is just to trigger a UI refresh
                // The actual task toggling already happened above
                withAnimation {
                    // No need to do anything here - just triggering a refresh
                }
            }
        } catch {
            print("Error toggling task completion: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

#Preview("Completed Tasks") {
    CompletedTaskView(isPresented: .constant(true))
        .modelContainer(TaskMockData.createPreviewContainer())
}
