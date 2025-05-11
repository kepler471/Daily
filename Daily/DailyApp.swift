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
        // Define the data schema with versioning
        let schema = Schema([
            Task.self,
        ]) // SwiftData will handle schema versions internally
        
        // First try to load the existing store
        do {
            // Configure the model with persistent storage
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            // Create the container with the config
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Add sample tasks if the container is empty (for development purposes)
            let context = ModelContext(container)
            try TaskMockData.createSampleTasks(in: context)
            
            return container
        } catch {
            print("Failed to load existing store: \(error)")
            print("Attempting to recreate the store...")
            
            // Reset the database using our utility
            let resetSuccessful = DatabaseResetUtility.resetDatabase()
            
            do {
                // Try again with a fresh store configuration
                let freshConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    allowsSave: true
                )
                
                let container = try ModelContainer(for: schema, configurations: [freshConfig])
                let context = ModelContext(container)
                try TaskMockData.createSampleTasks(in: context)
                return container
            } catch {
                // If we still can't create a persistent store, fall back to in-memory
                print("Still failed to create persistent container: \(error)")
                print("Falling back to in-memory container")
                
                // Try to create an in-memory container as a last resort
                if let inMemoryContainer = DatabaseResetUtility.createInMemoryContainer() {
                    return inMemoryContainer
                } else {
                    // If even that fails, create a minimal container to avoid crashing
                    let inMemoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                    
                    do {
                        let container = try ModelContainer(for: schema, configurations: [inMemoryConfig])
                        return container
                    } catch {
                        fatalError("Could not create any ModelContainer: \(error)")
                    }
                }
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

        // Check if this is the first launch
        checkFirstLaunch()
    }

    /// Check if this is the first app launch and set up initial state
    private func checkFirstLaunch() {
        let defaults = UserDefaults.standard
        let hasLaunchedBefore = defaults.bool(forKey: "hasLaunchedBefore")

        if !hasLaunchedBefore {
            print("First app launch detected in DailyApp.init()")
            // Don't set the flag here - let NotificationManager handle it
            // This ensures UserDefaults.didChangeNotification fires properly
        }
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

        // Check if this is a first launch
        let defaults = UserDefaults.standard

        // For debugging - print current state
        print("App has appeared. hasLaunchedBefore = \(defaults.bool(forKey: "hasLaunchedBefore"))")

        // If we need to force trigger permission requests for testing, uncomment this
        // This is a fallback mechanism in case the earlier requests didn't happen
        if !defaults.bool(forKey: "hasLaunchedBefore") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                print("Fallback notification permission request from onAppear")
                NotificationManager.shared.requestPermission()

                // Mark as launched to avoid duplicate requests
                defaults.set(true, forKey: "hasLaunchedBefore")
            }
        }
    }

    // MARK: - SwiftUI Scene Configuration
    
    /// Define the app's scenes and window behavior
    var body: some Scene {
        // MARK: Main Window Group
        WindowGroup {
            MainView()
                .environmentObject(taskResetManager) // Make available throughout the app
                .environmentObject(settingsManager) // Make settings available throughout the app
                .environmentObject(NotificationManager.shared) // Make notification manager available
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
                .environmentObject(NotificationManager.shared)
        }
    }
}