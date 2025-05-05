//
//  DailyApp.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import SwiftUI
import SwiftData

@main
struct DailyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Task.self,
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
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

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}