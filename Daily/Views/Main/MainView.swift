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
/// - Two columns of tasks (Required and Suggested)
/// - Displaying task completion status
/// - Handling app notifications
/// - Navigation to sheets and overlays for task management
struct MainView: View {
    // MARK: Environment & State

    /// The SwiftData model context for database operations
    @Environment(\.modelContext) private var modelContext

    /// Access to the system settings API
    @Environment(\.openSettings) private var openSettings

    /// Whether the add task sheet is being displayed
    @State private var showingAddTask = false

    /// Whether the completed required tasks overlay is being displayed
    @State private var showingRequiredCompletedTasks = false

    /// Whether the completed suggested tasks overlay is being displayed
    @State private var showingSuggestedCompletedTasks = false

    /// Whether the focused task view is being displayed
    @State private var showingFocusedTask = false

    /// The currently selected task for focused view
    @State private var focusedTask: Task? = nil

    /// Access to the task reset functionality
    @EnvironmentObject private var resetTaskManager: TaskResetManager

    /// Query for checking if there are any required tasks
    @Query(filter: Task.Predicates.byCategoryAndCompletion(category: .required, isCompleted: false),
           sort: [SortDescriptor(\Task.order)]) private var requiredTasks: [Task]

    // MARK: - Initialization

    /// Default empty initializer required for SwiftUI previews
    init() {
        // This empty initializer is needed for SwiftUI previews
        // We'll set up notification handlers in onAppear
    }

    // MARK: - Computed Properties

    /// Returns true if any overlay is currently being shown
    private var isAnyOverlayVisible: Bool {
        showingAddTask || showingRequiredCompletedTasks ||
        showingSuggestedCompletedTasks || showingFocusedTask
    }

    // MARK: - Setup Methods

    /// Configure the view when it first appears
    private func setupView() {
        setupNotificationHandlers()

        // Check if we have a pending task ID from a notification
        checkForPendingNotificationTask()
    }

    /// Check for a pending task ID from a notification and focus that task
    private func checkForPendingNotificationTask() {
        // Check if we have a pending task ID stored
        if let taskId = UserDefaults.standard.string(forKey: "pendingTaskId"),
           let timestamp = UserDefaults.standard.object(forKey: "pendingTaskIdTimestamp") as? Date {

            // Only use pending task IDs from the last 30 seconds
            if Date().timeIntervalSince(timestamp) < 30 {
                print("Found pending task ID from notification: \(taskId)")

                // Try to find and focus the task
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    do {
                        if let task = try self.modelContext.fetchTaskByUUID(taskId) {
                            print("Focusing task from notification: \(task.title)")
                            self.focusedTask = task
                            self.showingFocusedTask = true

                            // Clear the pending task ID
                            UserDefaults.standard.removeObject(forKey: "pendingTaskId")
                            UserDefaults.standard.removeObject(forKey: "pendingTaskIdTimestamp")
                            return
                        } else {
                            print("Could not find task with ID: \(taskId)")
                        }
                    } catch {
                        print("Error finding task with ID \(taskId): \(error.localizedDescription)")
                    }

                    // Fallback to showing the top required task if the specific task wasn't found
                    self.showDefaultFocusedTask()
                }
            } else {
                // Timestamp is too old, show default focused task
                showDefaultFocusedTask()

                // Clear the pending task ID
                UserDefaults.standard.removeObject(forKey: "pendingTaskId")
                UserDefaults.standard.removeObject(forKey: "pendingTaskIdTimestamp")
            }
        } else {
            // No pending task ID, show default focused task
            showDefaultFocusedTask()
        }
    }

    /// Show the top required task in focused view
    private func showDefaultFocusedTask() {
        // Show focused task view on app launch if there are required tasks
        if !requiredTasks.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.focusedTask = self.requiredTasks.first
                self.showingFocusedTask = true
            }
        }
    }

    /// Register for notifications from the menu bar actions and keyboard shortcuts
    private func setupNotificationHandlers() {
        // Set up notification observers for menu bar actions and keyboard shortcuts

        // Show add task sheet notification
        NotificationCenter.default.addObserver(
            forName: .showAddTaskSheet,
            object: nil,
            queue: .main
        ) { _ in
            self.showingAddTask = true
        }

        // Show completed tasks notification
        NotificationCenter.default.addObserver(
            forName: .showCompletedTasks,
            object: nil,
            queue: .main
        ) { _ in
            // Show both required and suggested completed tasks
            self.showingRequiredCompletedTasks = true
            self.showingSuggestedCompletedTasks = true
        }

        // Reset tasks notification
        NotificationCenter.default.addObserver(
            forName: .resetTodaysTasks,
            object: nil,
            queue: .main
        ) { _ in
            self.resetTaskManager.resetAllTasks()
        }

        // Open settings notification
        NotificationCenter.default.addObserver(
            forName: .openSettingsWithLink,
            object: nil,
            queue: .main
        ) { _ in
            self.openSettings()
        }

        // Add notification for showing focused task view
        NotificationCenter.default.addObserver(
            forName: .showFocusedTask,
            object: nil,
            queue: .main
        ) { _ in
            self.focusedTask = self.requiredTasks.first
            self.showingFocusedTask = true
        }

        // Add notification for showing a specific task in focused view
        NotificationCenter.default.addObserver(
            forName: .showFocusedTaskWithId,
            object: nil,
            queue: .main
        ) { notification in
            guard let taskId = notification.userInfo?["taskId"] as? String else {
                print("No taskId found in notification userInfo")
                return
            }

            print("Received notification to focus task with ID: \(taskId)")

            // Find the task with the given UUID and show it in focused view
            do {
                if let task = try self.modelContext.fetchTaskByUUID(taskId) {
                    print("Found task for notification: \(task.title)")
                    self.focusedTask = task
                    self.showingFocusedTask = true
                } else {
                    print("No task found with UUID \(taskId)")
                }
            } catch {
                print("Error finding task with UUID \(taskId): \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - View Body
    
    var body: some View {
        ZStack(alignment: .top) {
            // MARK: Main Content Area
            
            // Task columns layout
            HStack(spacing: 0) {
                // Required Tasks Column
                TaskStackView(category: .required, verticalOffset: 20, scale: 0.85, onTaskSelected: { task in
                    focusedTask = task
                    showingFocusedTask = true
                })
                .frame(minWidth: 0, maxWidth: .infinity)

                // Suggested Tasks Column
                TaskStackView(category: .suggested, verticalOffset: 20, scale: 0.85, onTaskSelected: { task in
                    focusedTask = task
                    showingFocusedTask = true
                })
                .frame(minWidth: 0, maxWidth: .infinity)
            }
            .padding(.top, 200)  // Space for the fixed control bar and fan-out space
            
            // MARK: Header Bar
            
            // Fixed top control bar
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    // Left half - Required tasks
                    HStack {
                        Spacer()
                        
                        // Required category title centered in left half
                        Text("Required")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Counter right aligned
                        TaskCounterView(category: .required, showCompletedTasks: $showingRequiredCompletedTasks)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.horizontal)
                    
                    // Right half - Suggested tasks
                    HStack {
                        Spacer()
                        
                        // Suggested category title centered in right half
                        Text("Suggested")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Counter right aligned
                        TaskCounterView(category: .suggested, showCompletedTasks: $showingSuggestedCompletedTasks)
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

            // Completed tasks overlay for Required category
            if showingRequiredCompletedTasks {
                CompletedTaskView(category: .required, isPresented: $showingRequiredCompletedTasks)
                    .transition(.opacity)
                    .zIndex(100)
            }

            // Completed tasks overlay for Suggested category
            if showingSuggestedCompletedTasks {
                CompletedTaskView(category: .suggested, isPresented: $showingSuggestedCompletedTasks)
                    .transition(.opacity)
                    .zIndex(100)
            }

            // Focused task overlay
            if showingFocusedTask {
                FocusedTaskView(task: focusedTask, isPresented: $showingFocusedTask)
                    .transition(.opacity)
                    .zIndex(100)
            }

            // Add task overlay
            if showingAddTask {
                AddTaskView(isPresented: $showingAddTask)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        // MARK: View Modifiers

        // Add Task Button in top left corner
        .overlay(
            AddTaskButtonView(showingAddTask: $showingAddTask)
                .padding([.top], 16)
                .padding([.leading], 16)
                .hideWhenOverlay(isAnyOverlayVisible),
            alignment: .topLeading
        )

        // Animation modifiers
        .animation(.easeInOut(duration: 0.3), value: showingAddTask)
        .animation(.easeInOut(duration: 0.3), value: showingRequiredCompletedTasks)
        .animation(.easeInOut(duration: 0.3), value: showingSuggestedCompletedTasks)
        .animation(.easeInOut(duration: 0.3), value: showingFocusedTask)
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
        .modelContainer(TaskMockData.createPreviewContainer())
        .frame(width: 800, height: 600)
}

#Preview("Dark Mode") {
    MainView()
        .preferredColorScheme(.dark)
        .modelContainer(TaskMockData.createPreviewContainer())
        .frame(width: 800, height: 600)
}

