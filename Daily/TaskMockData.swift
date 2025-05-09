//
//  TaskMockData.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import Foundation
import SwiftData

// MARK: - Mock Data Provider

/// Utility for generating sample task data for development, testing and SwiftUI previews
///
/// This struct provides methods to:
/// - Create sample tasks in a SwiftData model context
/// - Set up an in-memory model container with predefined tasks
/// - Populate test environments with realistic task data
struct TaskMockData {
    
    // MARK: - Sample Data Generation
    
    /// Creates sample tasks for preview and testing purposes if none exist
    /// - Parameter context: The SwiftData model context to insert tasks into
    /// - Throws: Error if database operations fail
    static func createSampleTasks(in context: ModelContext) throws {
        // Check if tasks already exist to avoid duplicates
        let taskCount = try context.fetchCount(FetchDescriptor<Task>())
        guard taskCount == 0 else { return }
        
        // MARK: Task Creation
        
        // Create required daily tasks
        let breakfast = Task(title: "Breakfast", order: 1, category: .required)
        let brushTeeth = Task(title: "Brush teeth", order: 2, category: .required)
        let meditation = Task(title: "Meditation", order: 3, category: .required)
        let email = Task(title: "Check email", order: 4, category: .required)
        let lunch = Task(title: "Eat some lunch", order: 5, category: .required)
        let dinner = Task(title: "Eat some dinner", order: 9, category: .required)
        
        // Create suggested optional tasks
        let exercise = Task(title: "Exercise", order: 6, category: .suggested)
        let reading = Task(title: "Reading", order: 7, category: .suggested)
        let journaling = Task(title: "Journaling", order: 8, category: .suggested)
        
        // MARK: Task Scheduling
        
        // Set scheduled times for some tasks
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        
        // Set breakfast time to 8:00 AM
        dateComponents.hour = 8
        dateComponents.minute = 0
        breakfast.scheduledTime = calendar.date(from: dateComponents)
        
        // Set email check time to 9:30 AM
        dateComponents.hour = 9
        dateComponents.minute = 30
        email.scheduledTime = calendar.date(from: dateComponents)
        
        // MARK: Persistence
        
        // Insert all tasks into the database
        context.insert(breakfast)
        context.insert(brushTeeth)
        context.insert(meditation)
        context.insert(email)
        context.insert(lunch)
        context.insert(dinner)
        context.insert(exercise)
        context.insert(reading)
        context.insert(journaling)
        
        // Save the changes
        try context.save()
    }
    
    // MARK: - Preview Container
    
    /// Creates an in-memory SwiftData model container populated with sample tasks
    /// - Returns: A configured ModelContainer ready to use in SwiftUI previews or tests
    static func createPreviewContainer() -> ModelContainer {
        do {
            // Set up an in-memory container
            let schema = Schema([Task.self])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            
            // Populate it with sample data
            let context = ModelContext(container)
            try createSampleTasks(in: context)
            
            return container
        } catch {
            fatalError("Failed to create preview container: \(error.localizedDescription)")
        }
    }
}
