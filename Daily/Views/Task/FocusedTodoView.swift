//
//  FocusedTodoView.swift
//  Daily
//
//  Created by Stelios Georgiou on 09/05/2025.
//

import SwiftUI
import SwiftData

// MARK: - Focused Todo View

/// A fullscreen overlay view that displays a todo in detail
///
/// FocusedTodoView provides a modal interface for:
/// - Viewing a todo in detail
/// - Marking the todo as complete
/// - Interacting with the todo with visual feedback
struct FocusedTodoView: View {
    // MARK: Properties

    /// Database context for saving todo changes
    @Environment(\.modelContext) private var modelContext

    /// The specific todo to display, or nil to show the top required todo
    var selectedTodo: Todo?

    /// Live query for required todos, sorted by order (used when no specific todo is provided)
    @Query private var requiredTodos: [Todo]

    /// Binding to control the visibility of this view
    @Binding var isPresented: Bool

    /// Tracks if the todo is being hovered for hover effects
    @State private var isHovered: Bool = false

    /// Whether the edit todo view is being displayed
    @State private var showingEditTodo: Bool = false

    // MARK: - Initialization

    /// Creates a new focused todo view that shows a specific todo or the top required todo
    /// - Parameters:
    ///   - todo: Optional specific todo to display
    ///   - isPresented: Binding to control the visibility of the view
    init(todo: Todo? = nil, isPresented: Binding<Bool>) {
        self.selectedTodo = todo
        self._isPresented = isPresented

        // Configure sorting to ensure consistent display order
        let sortDescriptors = [
            SortDescriptor(\Todo.order),
            SortDescriptor(\Todo.createdAt)
        ]

        // Query to get required todos that are not completed
        _requiredTodos = Query(
            filter: Todo.Predicates.byCategoryAndCompletion(category: .required, isCompleted: false),
            sort: sortDescriptors
        )
    }

    // MARK: - Computed Properties

    /// Returns the todo to display - either the selected todo or the top required todo
    private var todoToDisplay: Todo? {
        return selectedTodo ?? requiredTodos.first
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
                // MARK: Todo Display

                if let todo = todoToDisplay {
                    // Display the todo
                    focusedTodoCard(for: todo)
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
                    Text("No required todos")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                }
            }
            .padding(.top, 40)
        }
        .overlay {
            if let todo = todoToDisplay, showingEditTodo {
                EditTodoView(todo: todo, isPresented: $showingEditTodo)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingEditTodo)
        .withCloseButton(
            action: { isPresented = false },
            size: 36,           // Bigger button (default is 28)
            iconSize: 18        // Bigger X icon (default is 14)
        )
    }
    
    // MARK: - Todo Card View
    
    /// Creates a card view for the focused todo
    /// - Parameter todo: The todo to display
    /// - Returns: A SwiftUI view representing the todo card
    @ViewBuilder
    private func focusedTodoCard(for todo: Todo) -> some View {
        VStack(spacing: 20) {
            // MARK: Todo Details
            
            // Todo title and scheduled time (if exists)
            VStack(alignment: .center, spacing: 8) {
                Text(todo.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                if let scheduledTime = todo.scheduledTime {
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

            Text(todo.category == .required ? "Required" : "Suggested")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(todo.category == .required ? Color.blue.opacity(0.2) : Color.purple.opacity(0.2))
                )
                .foregroundColor(todo.category == .required ? .blue : .purple)
            
            // MARK: Action Buttons

            HStack(spacing: 20) {
                // Complete Button
                Button(action: {
                    toggleTodoCompletion(todo)
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
                .accessibilityLabel("Mark \(todo.title) as complete")

                // Edit Button (Three Dots)
                Button(action: {
                    showingEditTodo = true
                }) {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Edit todo \(todo.title)")
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
                withAnimation {
                    // No need to do anything here - just triggering a refresh
                }

                // If the todo is being completed (not reopened), post notification for animation
                if todo.isCompleted {
                    // Post a notification to trigger completion animation in TodoStackView
                    print("📣 FocusedTodoView: Posting todoCompletedExternally notification for todo: \(todo.title)")
                    print("📣 FocusedTodoView: Todo UUID: \(todo.uuid.uuidString)")

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        NotificationCenter.default.post(
                            name: .todoCompletedExternally,
                            object: nil,
                            userInfo: ["completedTodoId": todo.uuid.uuidString]
                        )
                    }
                }
            }
        } catch {
            print("Error toggling todo completion: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

#Preview("Focused Todo") {
    FocusedTodoView(isPresented: .constant(true))
        .modelContainer(TodoMockData.createPreviewContainer())
}
