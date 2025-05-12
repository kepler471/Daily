//
//  MainView.swift
//  Daily
//
//  Created by Stelios Georgiou on 08/05/2025.
//

import SwiftUI
import SwiftData

// MARK: - Main View

/// The primary interface view for the Daily app
///
/// MainView serves as the main content view displayed in the application window.
/// It manages:
/// - Two columns of todos (Required and Suggested)
/// - Displaying todo completion status
/// - Handling app notifications
/// - Navigation to sheets and overlays for todo management
struct MainView: View {
    // MARK: Environment & State

    /// The SwiftData model context for database operations
    @Environment(\.modelContext) private var modelContext

#if os(macOS)
    /// Access to the system settings API (macOS only)
    @Environment(\.openSettings) private var openSettings
#endif

    /// Whether the add todo sheet is being displayed
    @State private var showingAddTodo = false

    /// Whether the completed required todos overlay is being displayed
    @State private var showingRequiredCompletedTodos = false

    /// Whether the completed suggested todos overlay is being displayed
    @State private var showingSuggestedCompletedTodos = false

    /// Whether the focused todo view is being displayed
    @State private var showingFocusedTodo = false

    /// The currently selected todo for focused view
    @State private var focusedTodo: Todo? = nil

    /// Access to the todo reset functionality
    @EnvironmentObject private var resetTodoManager: TodoResetManager

    /// Query for checking if there are any required todos
    @Query(filter: Todo.Predicates.byCategoryAndCompletion(category: .required, isCompleted: false),
           sort: [SortDescriptor(\Todo.order)]) private var requiredTodos: [Todo]

    // MARK: - Initialization

    /// Default empty initializer required for SwiftUI previews
    init() {
        // This empty initializer is needed for SwiftUI previews
        // We'll set up notification handlers in onAppear
    }

    // MARK: - Computed Properties

    /// Returns true if any overlay is currently being shown
    private var isAnyOverlayVisible: Bool {
        showingAddTodo || showingRequiredCompletedTodos ||
        showingSuggestedCompletedTodos || showingFocusedTodo
    }

    // MARK: - Setup Methods

    /// Configure the view when it first appears
    private func setupView() {
        setupNotificationHandlers()

        // Check if we have a pending todo ID from a notification
        checkForPendingNotificationTodo()

        // Check if we have a pending todo completion
        checkForPendingTodoCompletion()
    }

    /// Check for a pending todo completion from a notification
    private func checkForPendingTodoCompletion() {
        // Check if we have a pending todo completion
        if let todoId = UserDefaults.standard.string(forKey: "pendingTodoCompletion"),
           let timestamp = UserDefaults.standard.object(forKey: "pendingTodoCompletionTimestamp") as? Date {

            // Only use pending completions from the last 30 seconds
            if Date().timeIntervalSince(timestamp) < 30 {
                print("Found pending todo completion from notification: \(todoId)")

                // Try to find and complete the todo
                do {
                    if let todo = try self.modelContext.fetchTodoByUUID(todoId) {
                        print("Completing todo from pending notification: \(todo.title)")
                        todo.isCompleted = true
                        try modelContext.save()
                    } else {
                        print("Could not find todo with ID for completion: \(todoId)")
                    }
                } catch {
                    print("Error completing pending todo: \(error.localizedDescription)")
                }
            }

            // Clear the pending todo completion
            UserDefaults.standard.removeObject(forKey: "pendingTodoCompletion")
            UserDefaults.standard.removeObject(forKey: "pendingTodoCompletionTimestamp")
        }
    }

    /// Check for a pending todo ID from a notification and focus that todo
    private func checkForPendingNotificationTodo() {
        // Check if we have a pending todo ID stored
        if let todoId = UserDefaults.standard.string(forKey: "pendingTodoId"),
           let timestamp = UserDefaults.standard.object(forKey: "pendingTodoIdTimestamp") as? Date {

            // Only use pending todo IDs from the last 30 seconds
            if Date().timeIntervalSince(timestamp) < 30 {
                print("Found pending todo ID from notification: \(todoId)")

                // Try to find and focus the todo
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    do {
                        if let todo = try self.modelContext.fetchTodoByUUID(todoId) {
                            print("Focusing todo from notification: \(todo.title)")
                            self.focusedTodo = todo
                            self.showingFocusedTodo = true

                            // Clear the pending todo ID
                            UserDefaults.standard.removeObject(forKey: "pendingTodoId")
                            UserDefaults.standard.removeObject(forKey: "pendingTodoIdTimestamp")
                            return
                        } else {
                            print("Could not find todo with ID: \(todoId)")
                        }
                    } catch {
                        print("Error finding todo with ID \(todoId): \(error.localizedDescription)")
                    }

                    // Fallback to showing the top required todo if the specific todo wasn't found
                    self.showDefaultFocusedTodo()
                }
            } else {
                // Timestamp is too old, show default focused todo
                showDefaultFocusedTodo()

                // Clear the pending todo ID
                UserDefaults.standard.removeObject(forKey: "pendingTodoId")
                UserDefaults.standard.removeObject(forKey: "pendingTodoIdTimestamp")
            }
        } else {
            // No pending todo ID, show default focused todo
            showDefaultFocusedTodo()
        }
    }

    /// Show the top required todo in focused view
    private func showDefaultFocusedTodo() {
        // Show focused todo view on app launch if there are required todos
        if !requiredTodos.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.focusedTodo = self.requiredTodos.first
                self.showingFocusedTodo = true
            }
        }
    }

    /// Register for notifications from the menu bar actions and keyboard shortcuts
    private func setupNotificationHandlers() {
        // Set up notification observers for menu bar actions and keyboard shortcuts

        // Show add todo sheet notification
        NotificationCenter.default.addObserver(
            forName: .showAddTodoSheet,
            object: nil,
            queue: .main
        ) { _ in
            self.showingAddTodo = true
        }

        // Show completed todos notification
        NotificationCenter.default.addObserver(
            forName: .showCompletedTodos,
            object: nil,
            queue: .main
        ) { _ in
            // Show both required and suggested completed todos
            self.showingRequiredCompletedTodos = true
            self.showingSuggestedCompletedTodos = true
        }

        // Reset todos notification
        NotificationCenter.default.addObserver(
            forName: .resetTodaysTodos,
            object: nil,
            queue: .main
        ) { _ in
            self.resetTodoManager.resetAllTodos()
        }

#if os(macOS)
        // Open settings notification (macOS only)
        NotificationCenter.default.addObserver(
            forName: .openSettingsWithLink,
            object: nil,
            queue: .main
        ) { _ in
            self.openSettings()
        }
#endif

        // Add notification for showing focused todo view
        NotificationCenter.default.addObserver(
            forName: .showFocusedTodo,
            object: nil,
            queue: .main
        ) { _ in
            self.focusedTodo = self.requiredTodos.first
            self.showingFocusedTodo = true
        }

        // Add notification for showing a specific todo in focused view
        NotificationCenter.default.addObserver(
            forName: .showFocusedTodoWithId,
            object: nil,
            queue: .main
        ) { notification in
            guard let todoId = notification.userInfo?["todoId"] as? String else {
                print("No todoId found in notification userInfo")
                return
            }

            print("Received notification to focus todo with ID: \(todoId)")

            // Find the todo with the given UUID and show it in focused view
            do {
                if let todo = try self.modelContext.fetchTodoByUUID(todoId) {
                    print("Found todo for notification: \(todo.title)")
                    self.focusedTodo = todo
                    self.showingFocusedTodo = true
                } else {
                    print("No todo found with UUID \(todoId)")
                }
            } catch {
                print("Error finding todo with UUID \(todoId): \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - View Body
    
    var body: some View {
        ZStack(alignment: .top) {
            // MARK: Main Content Area
            
            // Todo columns layout
            HStack(spacing: 0) {
                // Required Todos Column
                TodoStackView(category: .required, verticalOffset: 20, scale: 0.85, onTodoSelected: { todo in
                    focusedTodo = todo
                    showingFocusedTodo = true
                })
                .frame(minWidth: 0, maxWidth: .infinity)

                // Suggested Todos Column
                TodoStackView(category: .suggested, verticalOffset: 20, scale: 0.85, onTodoSelected: { todo in
                    focusedTodo = todo
                    showingFocusedTodo = true
                })
                .frame(minWidth: 0, maxWidth: .infinity)
            }
            .padding(.top, 200)  // Space for the fixed control bar and fan-out space
            
            // MARK: Header Bar
            
            // Fixed top control bar
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    // Left half - Required todos
                    HStack {
                        Spacer()
                        
                        // Required category title centered in left half
                        Text("Required")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Counter right aligned
                        TodoCounterView(category: .required, showCompletedTodos: $showingRequiredCompletedTodos)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.horizontal)
                    
                    // Right half - Suggested todos
                    HStack {
                        Spacer()
                        
                        // Suggested category title centered in right half
                        Text("Suggested")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Counter right aligned
                        TodoCounterView(category: .suggested, showCompletedTodos: $showingSuggestedCompletedTodos)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.horizontal)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

                Spacer()
            }
            .hideWhenOverlay(isAnyOverlayVisible)
            
            // MARK: Overlays

            // Completed todos overlay for Required category
            if showingRequiredCompletedTodos {
                CompletedTodoView(category: .required, isPresented: $showingRequiredCompletedTodos)
                    .transition(.opacity)
                    .zIndex(100)
            }

            // Completed todos overlay for Suggested category
            if showingSuggestedCompletedTodos {
                CompletedTodoView(category: .suggested, isPresented: $showingSuggestedCompletedTodos)
                    .transition(.opacity)
                    .zIndex(100)
            }

            // Focused todo overlay
            if showingFocusedTodo {
                FocusedTodoView(todo: focusedTodo, isPresented: $showingFocusedTodo)
                    .transition(.opacity)
                    .zIndex(100)
            }

            // Add todo overlay
            if showingAddTodo {
                AddTodoView(isPresented: $showingAddTodo)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        // MARK: View Modifiers

        // Add Todo Button in top left corner
        .overlay(
            AddTodoButtonView(showingAddTodo: $showingAddTodo)
                .padding([.top], 16)
                .padding([.leading], 16)
                .hideWhenOverlay(isAnyOverlayVisible),
            alignment: .topLeading
        )

        // Animation modifiers
        .animation(.easeInOut(duration: 0.3), value: showingAddTodo)
        .animation(.easeInOut(duration: 0.3), value: showingRequiredCompletedTodos)
        .animation(.easeInOut(duration: 0.3), value: showingSuggestedCompletedTodos)
        .animation(.easeInOut(duration: 0.3), value: showingFocusedTodo)
        .onAppear {
            setupView()
        }
    }
}

// MARK: - Hide When Overlay View Modifier

extension View {
    /// Hides the view when the condition is true
    /// - Parameter condition: Boolean condition that determines if the view should be hidden
    /// - Returns: Modified view that is hidden when the condition is true
    func hideWhenOverlay(_ condition: Bool) -> some View {
        self.opacity(condition ? 0 : 1)
            .animation(.easeInOut(duration: 0.2), value: condition)
            .disabled(condition)
    }
}

// MARK: - Previews

#Preview("Light Mode") {
    MainView()
        .preferredColorScheme(.light)
        .modelContainer(TodoMockData.createPreviewContainer())
        .frame(width: 800, height: 600)
}

#Preview("Dark Mode") {
    MainView()
        .preferredColorScheme(.dark)
        .modelContainer(TodoMockData.createPreviewContainer())
        .frame(width: 800, height: 600)
}

