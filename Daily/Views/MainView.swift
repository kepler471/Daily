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
/// MainView serves as the main content view displayed in the popover when the
/// user clicks on the menu bar icon. It manages:
/// - Two columns of tasks (Required and Suggested)
/// - Displaying task completion status
/// - Coordination with the menu bar via notifications
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
    
    /// Access to the task reset functionality
    @EnvironmentObject private var resetTaskManager: TaskResetManager
    
    // MARK: - Initialization
    
    /// Default empty initializer required for SwiftUI previews
    init() {
        // This empty initializer is needed for SwiftUI previews
        // We'll set up notification handlers in onAppear
    }
    
    // MARK: - Setup Methods
    
    /// Configure the view when it first appears
    private func setupView() {
        setupNotificationHandlers()
    }
    
    /// Register for notifications from the menu bar actions
    private func setupNotificationHandlers() {
        // Set up notification observers for menu bar actions
        
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
    }
    
    // MARK: - View Body
    
    var body: some View {
        ZStack(alignment: .top) {
            // MARK: Main Content Area
            
            // Task columns layout
            HStack(spacing: 0) {
                // Required Tasks Column
                TaskStackView(category: .required, verticalOffset: 20, scale: 0.85)
                    .frame(minWidth: 0, maxWidth: .infinity)
                
                // Suggested Tasks Column
                TaskStackView(category: .suggested, verticalOffset: 20, scale: 0.85)
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
        }
        // MARK: View Modifiers
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
        }
        .animation(.easeInOut(duration: 0.3), value: showingRequiredCompletedTasks)
        .animation(.easeInOut(duration: 0.3), value: showingSuggestedCompletedTasks)
        .onAppear {
            setupView()
        }
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

