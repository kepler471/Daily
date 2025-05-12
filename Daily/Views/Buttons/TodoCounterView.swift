//
//  TodoCounterView.swift
//  Daily
//
//  Created by Stelios Georgiou on 06/05/2025.
//

import SwiftUI
import SwiftData

// MARK: - Todo Counter View

/// A view that displays the count of completed todos compared to total todos
///
/// TodoCounterView provides a clickable counter that shows todo completion status
/// in the format "X/Y" where X is the number of completed todos and Y is the total.
/// When clicked, it triggers the display of the completed todos view.
struct TodoCounterView: View {
    // MARK: Properties
    
    /// Live query for all todos in the specified category (or all todos if nil)
    @Query private var allTodos: [Todo]
    
    /// Live query for completed todos in the specified category (or all completed todos if nil)
    @Query private var completedTodos: [Todo]
    
    /// Optional category filter - if nil, counts all todos
    let category: TodoCategory?
    
    /// Binding to control the display of the completed todos view
    @Binding var showCompletedTodos: Bool
    
    // MARK: - Initialization
    
    /// Creates a new todo counter view with optional category filtering
    /// - Parameters:
    ///   - category: Optional category to filter todos by
    ///   - showCompletedTodos: Binding to control the display of completed todos view
    init(category: TodoCategory? = nil, showCompletedTodos: Binding<Bool> = .constant(false)) {
        self.category = category
        self._showCompletedTodos = showCompletedTodos
        
        // Configure sorting to ensure consistent display order
        let sortDescriptors = [SortDescriptor(\Todo.order)]
        
        // Set up the appropriate queries based on category
        if let category = category {
            // Category-specific queries using predefined predicates
            _allTodos = Query(
                filter: Todo.Predicates.byCategory(category),
                sort: sortDescriptors
            )
            _completedTodos = Query(
                filter: Todo.Predicates.byCategoryAndCompletion(category: category, isCompleted: true),
                sort: sortDescriptors
            )
        } else {
            // All todos and completed todos across categories
            _allTodos = Query(sort: sortDescriptors)
            _completedTodos = Query(
                filter: Todo.Predicates.byCompletion(isCompleted: true),
                sort: sortDescriptors
            )
        }
    }
    
    // MARK: - View Body
    
    var body: some View {
        Button(action: {
            // When clicked, show the completed todos view
            showCompletedTodos = true
        }) {
            // Display the counter in "completed/total" format
            Text("\(completedTodos.count)/\(allTodos.count)")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .id(UUID()) // Force refresh on state changes
                .animation(.easeInOut, value: completedTodos.count)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle()) // Make the entire area clickable
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Tap to view completed todos")
    }
    
    // MARK: - Accessibility
    
    /// Generates an accessibility label for the counter
    private var accessibilityLabel: String {
        let categoryName = category?.rawValue.capitalized ?? "all"
        return "\(completedTodos.count) of \(allTodos.count) \(categoryName) todos completed"
    }
}

// MARK: - Preview

#Preview("Todo Counter") {
    TodoCounterView(category: .required, showCompletedTodos: .constant(false))
        .modelContainer(TodoMockData.createPreviewContainer())
        .padding()
}
