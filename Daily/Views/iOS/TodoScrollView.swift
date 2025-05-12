//
//  TodoScrollView.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/12/2025.
//

import SwiftUI
import SwiftData

#if os(iOS)

/// A scroll view that displays todos for iOS devices
///
/// TodoScrollView provides a simple, touch-friendly interface for displaying todos on iOS:
/// - Uses a standard vertical ScrollView instead of hover-based interactions
/// - Displays todos in a clean list format optimized for touch input
/// - Supports the same functionality as TodoStackView but with a mobile-first approach
/// - Includes swipe gestures for completing todos without tapping the checkbox
/// - Implements haptic feedback for a more engaging iOS touch experience
struct TodoScrollView: View {
    // MARK: - Properties

    /// Database context for saving todo changes
    @Environment(\.modelContext) private var modelContext

    /// Settings manager for notification preferences
    @EnvironmentObject private var settingsManager: SettingsManager

    /// Query for retrieving todos from the database
    @Query private var todos: [Todo]

    /// Optional category filter for the todos
    var category: TodoCategory?

    /// Callback when a todo is selected for focused view
    var onTodoSelected: ((Todo) -> Void)? = nil

    /// Store completed todos temporarily for animation purposes
    @State private var animatingTodos: [Todo] = []

    /// Todo IDs that are in the process of being swiped
    @State private var swipingTodoIds: Set<UUID> = []

    /// Haptic feedback generator for iOS
    #if os(iOS)
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    #endif

    // MARK: - Initialization

    /// Initialize with optional category filter
    /// - Parameters:
    ///   - category: Optional category to filter todos by
    ///   - onTodoSelected: Optional callback when a todo is selected
    init(category: TodoCategory? = nil, onTodoSelected: ((Todo) -> Void)? = nil) {
        self.category = category
        self.onTodoSelected = onTodoSelected

        // Use a combined predicate to get only incomplete todos for this category
        if let category = category {
            _todos = Query(
                filter: Todo.Predicates.byCategoryAndCompletion(category: category, isCompleted: false),
                sort: [
                    SortDescriptor(\Todo.order, order: .forward),
                    SortDescriptor(\Todo.createdAt, order: .forward)
                ]
            )
        } else {
            _todos = Query(
                filter: Todo.Predicates.byCompletion(isCompleted: false),
                sort: [
                    SortDescriptor(\Todo.order, order: .forward),
                    SortDescriptor(\Todo.createdAt, order: .forward)
                ]
            )
        }

        #if os(iOS)
        // Prepare haptic feedback generators
        feedbackGenerator.prepare()
        impactGenerator.prepare()
        #endif
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Show empty state if no todos
                if todos.isEmpty {
                    emptyStateView
                } else {
                    // Show todos
                    ForEach(todos) { todo in
                        todoRow(for: todo)
                    }
                }
            }
            .padding(.vertical)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: todos.count)
        }
        .refreshable {
            // Pull to refresh functionality for iOS
            print("Refreshing todos list")
            try? modelContext.save() // Ensure any pending changes are saved
        }
        .onAppear {
            print("📋 TodoScrollView for category \(category?.rawValue ?? "all") initialized with \(todos.count) todos")

            #if os(iOS)
            // Prepare haptic feedback generators on view appear
            feedbackGenerator.prepare()
            impactGenerator.prepare()
            #endif
        }
        // Listen for todo reset notifications
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TodosResetNotification"))) { _ in
            // When todos are reset, just let the Query update naturally
        }
        // Listen for external todo completion notifications
        .onReceive(NotificationCenter.default.publisher(for: .todoCompletedExternally)) { notification in
            guard let completedTodoId = notification.userInfo?["completedTodoId"] as? String else { return }

            // Check if notification is for a todo in this category
            let todoCategoryStr = notification.userInfo?["category"] as? String
            let todoCategory = todoCategoryStr.flatMap { TodoCategory(rawValue: $0) }

            // Only handle if this is the right category or we're showing all todos
            if let todoCategory = todoCategory,
               (todoCategory == category || category == nil) {
                handleExternalTodoCompletion(todoId: completedTodoId)
            }
        }
    }

    // MARK: - Todo Row

    /// Create a row for a specific todo with swipe actions
    /// - Parameter todo: The todo to display
    /// - Returns: A configured row view with swipe actions
    private func todoRow(for todo: Todo) -> some View {
        let isSwiping = swipingTodoIds.contains(todo.uuid)

        return TodoView(todo: todo) {
            handleTodoCompletion(todo: todo)
        }
        .contentShape(Rectangle()) // Ensure the entire row is tappable
        .onTapGesture {
            if let onTodoSelected = onTodoSelected {
                #if os(iOS)
                // Trigger light haptic feedback on tap
                impactGenerator.impactOccurred(intensity: 0.4)
                #endif

                onTodoSelected(todo)
            }
        }
        // Apply a swipe gesture for completion on iOS
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                #if os(iOS)
                // Trigger success haptic feedback
                feedbackGenerator.notificationOccurred(.success)
                #endif

                handleTodoCompletion(todo: todo)
            } label: {
                Label("Complete", systemImage: "checkmark.circle.fill")
            }
            .tint(todo.category == .required ? .green : .blue)
        }
        // Add a leading edge swipe for focus action
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                #if os(iOS)
                // Trigger selection haptic feedback
                impactGenerator.impactOccurred(intensity: 0.6)
                #endif

                if let onTodoSelected = onTodoSelected {
                    onTodoSelected(todo)
                }
            } label: {
                Label("Focus", systemImage: "eye.fill")
            }
            .tint(.orange)
        }
        // Add custom swipe tracking for animations
        .onChange(of: isSwiping) { _, newValue in
            #if os(iOS)
            if newValue {
                // Light feedback when starting to swipe
                impactGenerator.impactOccurred(intensity: 0.3)
            }
            #endif
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
        .id(todo.id) // Ensure view refreshes when todo changes
    }

    // MARK: - Empty State

    /// View shown when there are no todos in this category
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            Text(emptyStateText)
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Tap + to add a new todo")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))

            #if os(iOS)
            // Add additional hint for iOS-specific gesture
            Text("Pull down to refresh your list")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.top, 8)
            #endif
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    /// Text to display in empty state based on category
    private var emptyStateText: String {
        if let category = category {
            return category == .required
                ? "No required todos left"
                : "No suggested todos left"
        } else {
            return "No todos left"
        }
    }

    // MARK: - Todo Completion

    /// Handle todo completion toggle
    /// - Parameter todo: The todo being completed or reopened
    private func handleTodoCompletion(todo: Todo) {
        let newCompletionState = !todo.isCompleted

        // Prepare for completion animation
        if newCompletionState {
            // Add to animating todos for visual feedback
            withAnimation(.easeOut(duration: 0.3)) {
                animatingTodos.append(todo)
            }

            // Schedule removal of the todo from animation array
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    animatingTodos.removeAll { $0.id == todo.id }
                }
            }
        }

        // Update the model
        todo.isCompleted = newCompletionState

        // Try to save the changes
        do {
            try modelContext.save()

            if newCompletionState {
                // Cancel notification for completed todo
                Task {
                    await todo.cancelNotification()

                    #if os(iOS)
                    // Trigger success haptic feedback on successful completion
                    DispatchQueue.main.async {
                        feedbackGenerator.notificationOccurred(.success)
                    }
                    #endif
                }
            } else if todo.scheduledTime != nil {
                // Reschedule notification for reopened todo
                Task {
                    await todo.scheduleNotification(settings: settingsManager)
                }
            }
        } catch {
            print("Error saving todo completion state: \(error.localizedDescription)")

            #if os(iOS)
            // Trigger error haptic feedback
            DispatchQueue.main.async {
                feedbackGenerator.notificationOccurred(.error)
            }
            #endif
        }
    }

    /// Handle a todo completion that happened outside this view
    /// - Parameter todoId: The UUID string of the completed todo
    private func handleExternalTodoCompletion(todoId: String) {
        // For iOS, we rely on the Query to update automatically
        // but we can still add subtle animation for better UX
        print("External todo completion handled for todo with ID: \(todoId)")

        // Find the todo in the list if it exists
        if let todo = todos.first(where: { $0.uuid.uuidString == todoId }) {
            // Add a brief animation
            withAnimation(.easeOut(duration: 0.3)) {
                animatingTodos.append(todo)
            }

            // Remove from animation array after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    animatingTodos.removeAll { $0.id == todo.id }
                }
            }
        }
    }

    // MARK: - Context Menu

    /// Create a context menu for a todo item
    /// - Parameter todo: The todo to create a menu for
    /// - Returns: A context menu with actions for the todo
    @ViewBuilder
    private func contextMenu(for todo: Todo) -> some View {
        Button {
            if let onTodoSelected = onTodoSelected {
                onTodoSelected(todo)
            }
        } label: {
            Label("Focus on this Todo", systemImage: "eye")
        }

        Button {
            handleTodoCompletion(todo: todo)
        } label: {
            if todo.isCompleted {
                Label("Mark as Incomplete", systemImage: "circle")
            } else {
                Label("Complete Todo", systemImage: "checkmark.circle")
            }
        }

        Divider()

        Button(role: .destructive) {
            // This would be implemented if delete functionality is added
            print("Delete operation requested for todo: \(todo.title)")
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

// MARK: - Previews

#Preview("Required Todos") {
    TodoScrollView(category: .required)
        .environmentObject(SettingsManager())
        .modelContainer(TodoMockData.createPreviewContainer())
}

#Preview("Suggested Todos") {
    TodoScrollView(category: .suggested)
        .environmentObject(SettingsManager())
        .modelContainer(TodoMockData.createPreviewContainer())
}

#Preview("Empty State") {
    TodoScrollView(category: .required)
        .environmentObject(SettingsManager())
        .modelContainer(ModelContainer(for: Todo.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
}

#endif