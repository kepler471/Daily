//
//  DailyApp.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import SwiftUI
import SwiftData
import AppKit

// MARK: - Main App

/// The main entry point for the Daily app
///
/// DailyApp sets up the core infrastructure including:
/// - Model container for data persistence using SwiftData
/// - State management through TaskResetManager and SettingsManager
/// - Menu bar behavior through AppDelegate and MenuBarManager
/// - Application scenes and window behavior
@main
struct DailyApp: App {
    // MARK: Properties
    
    /// Manager for handling task reset functionality
    @StateObject private var taskResetManager: TaskResetManager
    
    /// Manager for app settings and preferences
    @StateObject private var settingsManager = SettingsManager()
    
    /// The AppDelegate that handles AppKit integration
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    // MARK: - SwiftData Setup
    
    /// The shared SwiftData model container for data persistence
    var sharedModelContainer: ModelContainer = {
        // Define the data schema
        let schema = Schema([
            Task.self,
        ])
        
        // Configure the model with persistent storage
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        // MARK: TODO: Replace with fully persistent container in production
        do {
            // Create the container with the config
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Add sample tasks if the container is empty (for development purposes)
            let context = ModelContext(container)
            try TaskMockData.createSampleTasks(in: context)
            
            return container
        } catch {
            // Fall back to in-memory container if persistent one fails
            print("Failed to create persistent container: \(error)")
            print("Falling back to in-memory container")
            
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            
            do {
                let container = try ModelContainer(for: schema, configurations: [configuration])
                let context = ModelContext(container)
                try TaskMockData.createSampleTasks(in: context)
                return container
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()
    
    // MARK: - Initialization
    
    /// Initialize the app with all required dependencies
    init() {
        // Create the model context and task reset manager
        let context = ModelContext(sharedModelContainer)
        let manager = TaskResetManager(modelContext: context)
        
        // Initialize the state object
        _taskResetManager = StateObject(wrappedValue: manager)
        
        // Initialize the app delegate with necessary dependencies
        _appDelegate = NSApplicationDelegateAdaptor(AppDelegate.self)
    }
    
    // MARK: - Lifecycle
    
    /// Configure dependencies when the app appears
    /// 
    /// This method passes the required dependencies to the AppDelegate
    /// and sets up the popover with the correct context
    func onAppear() {
        // Pass the dependencies to the app delegate
        appDelegate.modelContainer = sharedModelContainer
        appDelegate.taskResetManager = taskResetManager
        appDelegate.settingsManager = settingsManager
        
        // Configure the popover with the model context after we've passed the dependencies
        appDelegate.setupPopoverWithContext()
    }

    // MARK: - SwiftUI Scene Configuration
    
    /// Define the app's scenes and window behavior
    var body: some Scene {
        // MARK: Main Window Group
        WindowGroup {
            MainView()
                .environmentObject(taskResetManager) // Make available throughout the app
                .environmentObject(settingsManager) // Make settings available throughout the app
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
        
        // MARK: Settings Scene
        
        // Add standard macOS Settings scene
        Settings {
            SettingsView()
                .environmentObject(settingsManager)
        }
    }
}
