//
//  DailyApp.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import SwiftUI
import SwiftData
import AppKit

@main
struct DailyApp: App {
    @StateObject private var taskResetManager: TaskResetManager
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Task.self,
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        // @TEMP
        // Use a temporary in-memory container for now while we develop
        // Later we can switch to a persistent container
        do {
            // Use an in-memory container for now while development is in flux
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Add sample tasks if the container is empty - for development purposes
            let context = ModelContext(container)
            try TaskMockData.createSampleTasks(in: context)
            
            return container
        } catch {
            // For development, we'll just use an in-memory container if the persistent one fails
            print("Failed to create persistent container: \(error)")
            print("Falling back to in-memory container")
            
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            
            do {
                let container = try ModelContainer(for: schema, configurations: [configuration])
                // Add sample tasks
                let context = ModelContext(container)
                try TaskMockData.createSampleTasks(in: context)
                return container
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()
    
    init() {
        // Create the model context and task reset manager
        let context = ModelContext(sharedModelContainer)
        let manager = TaskResetManager(modelContext: context)
        
        // Initialize the state object
        _taskResetManager = StateObject(wrappedValue: manager)
        
        // Initialize the app delegate with necessary dependencies
        _appDelegate = NSApplicationDelegateAdaptor(AppDelegate.self)
    }
    
    // Make sure the app delegate has access to the model container and task reset manager
    func onAppear() {
        appDelegate.modelContainer = sharedModelContainer
        appDelegate.taskResetManager = taskResetManager
        
        // Configure the popover with the model context after we've passed the dependencies
        appDelegate.setupPopoverWithContext()
    }

    var body: some Scene {
        // This is a menu bar app, so we don't need a visible window on launch
        // The AppDelegate will handle setting up the menu bar
        WindowGroup {
            MainView()
                .environmentObject(taskResetManager) // Make available throughout the app
                .environment(\.resetTaskManager, taskResetManager) // Provide via environment key
                // Hide the window at startup and let the menu bar handle it
                .hidden()
                .onAppear {
                    onAppear()
                }
        }
        .modelContainer(sharedModelContainer)
        // Disable the default window title bar and hide the window by default
        .windowStyle(.hiddenTitleBar)
        .commands {
            // Remove the default window menu 
            CommandGroup(replacing: .newItem) { }
        }
    }
}
