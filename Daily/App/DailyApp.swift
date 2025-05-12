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
/// - Application behavior through platform-specific delegates
/// - Application scenes and window behavior
@main
struct DailyApp: App {
    // MARK: Properties

    /// Manager for handling todo reset functionality
    @StateObject private var todoResetManager: TodoResetManager

    /// Manager for app settings and preferences
    @StateObject private var settingsManager = SettingsManager()

    #if os(macOS)
    /// The AppDelegate that handles platform integration
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #elseif os(iOS)
    /// The AppDelegate that handles platform integration
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #endif

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

        // MARK: TODO: Replace with fully persistent container in production
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
        // Create the model context and todo reset manager
        let context = ModelContext(sharedModelContainer)
        let manager = TodoResetManager(modelContext: context)

        // Initialize the state object
        _todoResetManager = StateObject(wrappedValue: manager)

        #if os(macOS)
        // Initialize the app delegate for macOS
        _appDelegate = NSApplicationDelegateAdaptor(AppDelegate.self)
        #elseif os(iOS)
        // Initialize the app delegate for iOS
        _appDelegate = UIApplicationDelegateAdaptor(AppDelegate.self)
        #endif
    }

    // MARK: - Lifecycle

    /// Configure dependencies when the app appears
    ///
    /// This method passes the required dependencies to the appropriate AppDelegate
    /// and sets up the application context based on platform
    func onAppear() {
        // Common setup for all platforms
        appDelegate.modelContainer = sharedModelContainer
        appDelegate.todoResetManager = todoResetManager
        appDelegate.settingsManager = settingsManager

        // Platform-specific context setup
        #if os(macOS)
        appDelegate.setupPopoverWithContext()
        #elseif os(iOS)
        appDelegate.setupWithContext()
        #endif
    }

    // MARK: - SwiftUI Scene Configuration

    /// Define the app's scenes and window behavior based on platform
    var body: some Scene {
        #if os(macOS)
        // MARK: macOS Main Window Group
        WindowGroup {
            MainView()
                .environmentObject(todoResetManager) // Make available throughout the app
                .environmentObject(settingsManager) // Make settings available throughout the app
                .environment(\.resetTodoManager, todoResetManager) // Provide via environment key
                .onAppear {
                    onAppear()
                }
        }
        .modelContainer(sharedModelContainer)
        .windowResizability(.contentSize)
        .defaultSize(width: 800, height: 600)
        .windowStyle(.titleBar)

        // MARK: macOS Settings Scene

        // Add standard macOS Settings scene
        Settings {
            SettingsView()
                .environmentObject(settingsManager)
                .modelContainer(sharedModelContainer)
        }
        #elseif os(iOS)
        // MARK: iOS Window Group
        WindowGroup {
            iOSMainView()
                .environmentObject(todoResetManager) // Make available throughout the app
                .environmentObject(settingsManager) // Make settings available throughout the app
                .environment(\.resetTodoManager, todoResetManager) // Provide via environment key
                .onAppear {
                    onAppear()
                }
        }
        .modelContainer(sharedModelContainer)
        #endif
    }
}
