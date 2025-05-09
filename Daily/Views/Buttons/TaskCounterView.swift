//
//  TaskCounterView.swift
//  Daily
//
//  Created by Stelios Georgiou on 06/05/2025.
//

import SwiftUI
import SwiftData

// MARK: - Task Counter View

/// A view that displays the count of completed tasks compared to total tasks
///
/// TaskCounterView provides a clickable counter that shows task completion status
/// in the format "X/Y" where X is the number of completed tasks and Y is the total.
/// When clicked, it triggers the display of the completed tasks view.
struct TaskCounterView: View {
    // MARK: Properties
    
    /// Live query for all tasks in the specified category (or all tasks if nil)
    @Query private var allTasks: [Task]
    
    /// Live query for completed tasks in the specified category (or all completed tasks if nil)
    @Query private var completedTasks: [Task]
    
    /// Optional category filter - if nil, counts all tasks
    let category: TaskCategory?
    
    /// Binding to control the display of the completed tasks view
    @Binding var showCompletedTasks: Bool
    
    // MARK: - Initialization
    
    /// Creates a new task counter view with optional category filtering
    /// - Parameters:
    ///   - category: Optional category to filter tasks by
    ///   - showCompletedTasks: Binding to control the display of completed tasks view
    init(category: TaskCategory? = nil, showCompletedTasks: Binding<Bool> = .constant(false)) {
        self.category = category
        self._showCompletedTasks = showCompletedTasks
        
        // Configure sorting to ensure consistent display order
        let sortDescriptors = [SortDescriptor(\Task.order)]
        
        // Set up the appropriate queries based on category
        if let category = category {
            // Category-specific queries using predefined predicates
            _allTasks = Query(
                filter: Task.Predicates.byCategory(category),
                sort: sortDescriptors
            )
            _completedTasks = Query(
                filter: Task.Predicates.byCategoryAndCompletion(category: category, isCompleted: true),
                sort: sortDescriptors
            )
        } else {
            // All tasks and completed tasks across categories
            _allTasks = Query(sort: sortDescriptors)
            _completedTasks = Query(
                filter: Task.Predicates.byCompletion(isCompleted: true),
                sort: sortDescriptors
            )
        }
    }
    
    // MARK: - View Body
    
    var body: some View {
        Button(action: {
            // When clicked, show the completed tasks view
            showCompletedTasks = true
        }) {
            // Display the counter in "completed/total" format
            Text("\(completedTasks.count)/\(allTasks.count)")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .id(UUID()) // Force refresh on state changes
                .animation(.easeInOut, value: completedTasks.count)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle()) // Make the entire area clickable
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Tap to view completed tasks")
    }
    
    // MARK: - Accessibility
    
    /// Generates an accessibility label for the counter
    private var accessibilityLabel: String {
        let categoryName = category?.rawValue.capitalized ?? "all"
        return "\(completedTasks.count) of \(allTasks.count) \(categoryName) tasks completed"
    }
}

// MARK: - Preview

#Preview("Task Counter") {
    TaskCounterView(category: .required, showCompletedTasks: .constant(false))
        .modelContainer(TaskMockData.createPreviewContainer())
        .padding()
}
