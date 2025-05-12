//
//  DatabaseResetUtility.swift
//  Daily
//
//  Created by Stelios Georgiou on 11/05/2025.
//

import Foundation
import SwiftData

/// Utility for handling database reset operations
struct DatabaseResetUtility {
    
    /// Resets the database by removing all store files
    /// - Returns: True if successful, false otherwise
    static func resetDatabase() -> Bool {
        let fileManager = FileManager.default
        
        // Get the application support directory
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("Failed to locate Application Support directory")
            return false
        }
        
        // Get the path to the default store
        let storeURL = appSupportURL.appendingPathComponent("default.store")
        print("Attempting to delete database at: \(storeURL)")
        
        // Use a more robust deletion approach
        var success = true
        
        // Delete the main store file
        do {
            if fileManager.fileExists(atPath: storeURL.path) {
                try fileManager.removeItem(at: storeURL)
                print("Successfully deleted main store file")
            }
        } catch {
            print("Failed to delete main store: \(error)")
            success = false
        }
        
        // Delete all related auxiliary files
        do {
            let storeDir = storeURL.deletingLastPathComponent()
            let directoryContents = try fileManager.contentsOfDirectory(
                at: storeDir,
                includingPropertiesForKeys: nil
            )
            
            // Find and delete all files related to the store
            for fileURL in directoryContents {
                if fileURL.lastPathComponent.starts(with: "default.store") {
                    do {
                        try fileManager.removeItem(at: fileURL)
                        print("Deleted: \(fileURL.lastPathComponent)")
                    } catch {
                        print("Failed to delete \(fileURL.lastPathComponent): \(error)")
                        success = false
                    }
                }
            }
        } catch {
            print("Failed to enumerate directory contents: \(error)")
            success = false
        }
        
        // Ensure file system operations are complete
        Thread.sleep(forTimeInterval: 0.5)
        
        return success
    }
    
    /// Creates an in-memory database for fallback
    /// - Returns: A model container with in-memory storage
    static func createInMemoryContainer() -> ModelContainer? {
        let schema = Schema([Todo.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            try TodoMockData.createSampleTodos(in: context)
            return container
        } catch {
            print("Failed to create in-memory container: \(error)")
            return nil
        }
    }
}
