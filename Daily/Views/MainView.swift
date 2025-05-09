//
//  MainView.swift
//  Daily
//
//  Created by Stelios Georgiou on 08/05/2025.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openSettings) private var openSettings
    @State private var showingAddTask = false
    @State private var showingRequiredCompletedTasks = false
    @State private var showingSuggestedCompletedTasks = false
    @EnvironmentObject private var resetTaskManager: TaskResetManager
    
    // Default empty init for SwiftUI previews
    init() {
        // This empty initializer is needed for SwiftUI previews
        // We'll set up notification handlers in onAppear
    }
    
    // This will be called when the view appears
    private func setupView() {
        setupNotificationHandlers()
    }
    
    private func setupNotificationHandlers() {
        // Set up notification observers for menu bar actions
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ShowAddTaskSheet"),
            object: nil,
            queue: .main
        ) { _ in
            self.showingAddTask = true
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ShowCompletedTasks"),
            object: nil,
            queue: .main
        ) { _ in
            // Show both required and suggested completed tasks
            self.showingRequiredCompletedTasks = true
            self.showingSuggestedCompletedTasks = true
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ResetTodaysTasks"),
            object: nil,
            queue: .main
        ) { _ in
            resetTaskManager.resetAllTasks()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenSettingsWithLink"),
            object: nil,
            queue: .main
        ) { _ in
            openSettings()
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main content with task columns
            HStack(spacing: 0) {
                // Required Tasks Column
                TaskStackView(category: .required, verticalOffset: 20, scale: 0.85)
                    .frame(minWidth: 0, maxWidth: .infinity)
                
                // Suggested Tasks Column
                TaskStackView(category: .suggested, verticalOffset: 20, scale: 0.85)
                    .frame(minWidth: 0, maxWidth: .infinity)
            }
            .padding(.top, 200)  // Space for the fixed control bar and fan-out space
            
            // Fixed top control bar
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    // Left half
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
                    
                    // Right half
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

