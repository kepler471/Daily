//
//  DailyApp.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import SwiftUI
import SwiftData

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

// MARK: - Main App

/// The main entry point for the Daily app
///
/// DailyApp sets up the core infrastructure including:
/// - Model container for data persistence using SwiftData
/// - State management through TodoResetManager and SettingsManager
/// - Application behavior through SwiftUI app lifecycle
/// - Cross-platform UI using conditional compilation
@main
@available(macOS 12.0, iOS 15.0, *)
struct DailyApp: App {
    // MARK: - Properties

    /// Manager for handling notifications across platforms
    @StateObject private var notificationManager = NotificationManager.shared
    
    /// Manager for handling todo reset functionality
    @StateObject private var todoResetManager: TodoResetManager
    
    /// Manager for app settings and preferences
    @StateObject private var settingsManager = SettingsManager()
    
    /// The current scene phase for lifecycle events
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - SwiftData Setup
    
    /// The shared SwiftData model container for data persistence
    var sharedModelContainer: ModelContainer = {
        // Define the data schema
        let schema = Schema([
            Todo.self,
        ])
        
        // Configure the model with persistent storage
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        // Try to create a persistent container
        do {
            // Create the container with the config
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Add sample todos if the container is empty (for development purposes)
            let context = ModelContext(container)
            try TodoMockData.createSampleTodos(in: context)
            
            return container
        } catch {
            // Fall back to in-memory container if persistent one fails
            print("Failed to create persistent container: \(error)")
            print("Falling back to in-memory container")
            
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            
            do {
                let container = try ModelContainer(for: schema, configurations: [configuration])
                let context = ModelContext(container)
                try TodoMockData.createSampleTodos(in: context)
                return container
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()
    
    // MARK: - Initialization
    
    /// Initialize the app with all required dependencies
    init() {
        // Create the model context for the todo reset manager
        let context = ModelContext(sharedModelContainer)

        // Initialize the reset manager
        _todoResetManager = StateObject(wrappedValue: TodoResetManager(modelContext: context))

        // Set up the dependencies immediately
        self.setupDependenciesOnInit()
    }

    /// Setup dependencies during initialization
    private func setupDependenciesOnInit() {
        // Create a context for the notification manager
        let context = ModelContext(sharedModelContainer)
        NotificationManager.shared.setModelContext(context)

        // Set up notifications
        Task {
            await NotificationManager.shared.setupNotifications()
            await self.syncDataWithNotificationsTask()

            // Check for any pending todo completions
            checkPendingTodoCompletions()
        }

        // Add observer for pending todo completions from notifications
        NotificationCenter.default.addObserver(
            forName: .completeTodoPending,
            object: nil,
            queue: .main
        ) { notification in
            DailyApp.handleStaticPendingTodoCompletion(notification, container: sharedModelContainer)
        }
    }

    /// Static handler for pending todo completions
    static func handleStaticPendingTodoCompletion(_ notification: Notification, container: ModelContainer) {
        guard let todoId = notification.userInfo?["todoId"] as? String else {
            print("No todoId in completeTodoPending notification")
            return
        }

        Task {
            let context = ModelContext(container)
            do {
                if let todo = try context.fetchTodoByUUID(todoId) {
                    // Complete the todo
                    todo.isCompleted = true
                    try context.save()
                    print("Completed pending todo from notification: \(todo.title)")

                    // Update badge
                    await NotificationManager.shared.refreshBadgeCount()

                    // Notify observers
                    NotificationCenter.default.post(
                        name: .todoCompletedExternally,
                        object: nil,
                        userInfo: [
                            "completedTodoId": todoId,
                            "category": todo.category.rawValue
                        ]
                    )
                }
            } catch {
                print("Error completing pending todo: \(error.localizedDescription)")
            }
        }
    }

    /// Checks UserDefaults for any pending todo completions
    private func checkPendingTodoCompletions() {
        // Check if there's a pending todo completion
        if let todoId = UserDefaults.standard.string(forKey: "pendingTodoCompletion") {
            print("Found pending todo completion with ID: \(todoId)")
            
            // Remove the stored ID to prevent duplicate completions
            UserDefaults.standard.removeObject(forKey: "pendingTodoCompletion")
            UserDefaults.standard.removeObject(forKey: "pendingTodoCompletionTimestamp")
            
            // Create notification to process the pending todo
            let userInfo = ["todoId": todoId]
            NotificationCenter.default.post(
                name: .completeTodoPending,
                object: nil,
                userInfo: userInfo
            )
        }
    }

    /// Task version of syncDataWithNotifications for init
    private func syncDataWithNotificationsTask() async {
        let context = ModelContext(sharedModelContainer)
        do {
            let todos = try context.fetchTodos()
            await NotificationManager.shared.synchronizeNotificationsWithDatabase(todos: todos)
            await NotificationManager.shared.refreshBadgeCount()
        } catch {
            print("Error syncing data with notifications: \(error.localizedDescription)")
        }
    }
    
    // MARK: - SwiftUI Scene Configuration
    
    /// Define the app's scenes and window behavior based on platform
    var body: some Scene {
        #if os(macOS)
        // MARK: macOS Main Window Group
        WindowGroup {
            MainView()
                .environmentObject(todoResetManager) 
                .environmentObject(settingsManager) 
                .environmentObject(notificationManager)
                .environment(\.resetTodoManager, todoResetManager)
        }
        .modelContainer(sharedModelContainer)
        .windowResizability(.contentSize)
        .defaultSize(width: 800, height: 600)
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("About Daily") {
                    NSApplication.shared.orderFrontStandardAboutPanel()
                }
            }
            
            CommandGroup(replacing: .newItem) {
                Button("New Todo") {
                    NotificationCenter.default.post(name: .showAddTodoSheet, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandMenu("Todo") {
                Button("Toggle Completion") {
                    // Would need selected todo context
                }
                .keyboardShortcut("c", modifiers: .command)
                
                Button("Reset Today's Todos") {
                    todoResetManager.resetAllTodos()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Show Completed Todos") {
                    NotificationCenter.default.post(name: .showCompletedTodos, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
        
        // MARK: macOS Settings Scene
        Settings {
            SettingsView()
                .environmentObject(settingsManager)
                .environmentObject(notificationManager)
                .modelContainer(sharedModelContainer)
        }
        #elseif os(iOS)
        // MARK: iOS Window Group
        WindowGroup {
            iOSMainView()
                .environmentObject(todoResetManager)
                .environmentObject(settingsManager)
                .environmentObject(notificationManager)
                .environment(\.resetTodoManager, todoResetManager)
        }
        .modelContainer(sharedModelContainer)
        // iOS background task for resetting todos at the scheduled time
        .backgroundTask(.appRefresh("com.kepler471.Daily.resetTodos")) {
            await todoResetManager.resetTodosInBackground()
        }
        #endif
    }
    
    // MARK: - Lifecycle Methods
    
    /// Sets up the dependencies when the app becomes active
    private func setupDependencies() {
        // Create a context for the notification manager
        let context = ModelContext(sharedModelContainer)
        notificationManager.setModelContext(context)

        // Set up notifications
        Task {
            await notificationManager.setupNotifications()
        }
    }
    
    /// Synchronizes notifications with the database
    private func syncDataWithNotifications() {
        Task {
            let context = ModelContext(sharedModelContainer)
            do {
                let todos = try context.fetchTodos()
                await notificationManager.synchronizeNotificationsWithDatabase(todos: todos)
            } catch {
                print("Error syncing data with notifications: \(error.localizedDescription)")
            }

            // Refresh badge count
            await notificationManager.refreshBadgeCount()
        }
    }
    
    /// Saves the model context to persist changes
    private func saveContext() {
        let context = ModelContext(sharedModelContainer)
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error.localizedDescription)")
        }
    }
}

// MARK: - Environment Key for TodoResetManager

/// Environment key for accessing the todo reset manager
struct TodoResetManagerKey: EnvironmentKey {
    static let defaultValue: TodoResetManager? = nil
}

/// Environment extension for the todo reset manager
extension EnvironmentValues {
    var resetTodoManager: TodoResetManager? {
        get { self[TodoResetManagerKey.self] }
        set { self[TodoResetManagerKey.self] = newValue }
    }
}