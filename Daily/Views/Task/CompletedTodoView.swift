//
//  CompletedTodoView.swift
//  Daily
//
//  Created by Stelios Georgiou on 07/05/2025.
//

import SwiftUI
import SwiftData

// MARK: - Completed Todo View

/// A fullscreen overlay view that displays all completed todos
///
/// CompletedTodoView provides a modal interface for:
/// - Viewing all completed todos in a specific category (or all categories)
/// - Reopening completed todos when needed
/// - Showing todo details with interactive hover effects
struct CompletedTodoView: View {
    // MARK: Properties
    
    /// Database context for saving todo changes
    @Environment(\.modelContext) private var modelContext
    
    /// Live query for completed todos, sorted by order
    @Query private var completedTodos: [Todo]
    
    /// Optional category filter - if nil, shows all completed todos
    let category: TodoCategory?
    
    /// Binding to control the visibility of this view
    @Binding var isPresented: Bool
    
    /// Tracks the currently hovered todo for hover effects
    @State private var hoveredTodoId: PersistentIdentifier? = nil
    
    // MARK: - Initialization
    
    /// Creates a new completed todos view with optional category filtering
    /// - Parameters:
    ///   - category: Optional category to filter todos by
    ///   - isPresented: Binding to control the visibility of the view
    init(category: TodoCategory? = nil, isPresented: Binding<Bool>) {
        self.category = category
        self._isPresented = isPresented
        
        // Configure sorting to ensure consistent display order
        let sortDescriptors = [
            SortDescriptor(\Todo.order),
            SortDescriptor(\Todo.createdAt)
        ]
        
        // Set up the appropriate query based on category
        if let category = category {
            // Category-specific query using predefined predicates
            _completedTodos = Query(
                filter: Todo.Predicates.byCategoryAndCompletion(category: category, isCompleted: true),
                sort: sortDescriptors
            )
        } else {
            // All completed todos across categories
            _completedTodos = Query(
                filter: Todo.Predicates.byCompletion(isCompleted: true),
                sort: sortDescriptors
            )
        }
    }
    
    // MARK: - Computed Properties
    
    /// Generates the view title based on selected category
    private var categoryTitle: String {
        switch category {
        case .required:
            return "Completed Required Todos"
        case .suggested:
            return "Completed Suggested Todos"
        case nil:
            return "All Completed Todos"
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
                
                // MARK: Todo List
                
                if completedTodos.isEmpty {
                    // Empty state
                    Spacer()
                    Text("No completed todos")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                } else {
                    // Scrollable todo list
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(completedTodos) { todo in
                                completedTodoCard(for: todo)
                                    .scaleEffect(hoveredTodoId == todo.persistentModelID ? 1.05 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hoveredTodoId)
                                    .onHover { isHovered in
                                        hoveredTodoId = isHovered ? todo.persistentModelID : nil
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
    
    // MARK: - Todo Card View
    
    /// Creates a card view for a completed todo
    /// - Parameter todo: The completed todo to display
    /// - Returns: A SwiftUI view representing the todo card
    @ViewBuilder
    private func completedTodoCard(for todo: Todo) -> some View {
        HStack {
            // MARK: Todo Details
            
            // Todo title and scheduled time (if exists)
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .strikethrough(todo.isCompleted)
                
                if let scheduledTime = todo.scheduledTime {
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
            
            // MARK: Reopen Button
            
            Button(action: {
                toggleTodoCompletion(todo)
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
            .accessibilityLabel("Reopen \(todo.title)")
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
    
    /// Toggles the completion state of a todo and saves the change
    /// - Parameter todo: The todo to toggle
    private func toggleTodoCompletion(_ todo: Todo) {
        // Toggle todo completion state
        todo.isCompleted.toggle()
        
        do {
            // Save the changes to the model
            try modelContext.save()
            
            // Add a small delay to allow the UI to update
            // This helps the SwiftData change notifications propagate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // This is just to trigger a UI refresh
                // The actual todo toggling already happened above
                withAnimation {
                    // No need to do anything here - just triggering a refresh
                }
            }
        } catch {
            print("Error toggling todo completion: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

#Preview("Completed Todos") {
    CompletedTodoView(isPresented: .constant(true))
        .modelContainer(TodoMockData.createPreviewContainer())
}
