//
//  TaskMockData.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import Foundation
import SwiftData

struct TaskMockData {
    
    /// Creates sample tasks for preview and testing purposes
    static func createSampleTasks(in context: ModelContext) throws {
        // Check if tasks already exist
        let taskCount = try context.fetchCount(FetchDescriptor<Task>())
        guard taskCount == 0 else { return }
        
        // Required tasks
        let breakfast = Task(title: "Breakfast", order: 1, category: .required)
        let brushTeeth = Task(title: "Brush teeth", order: 2, category: .required)
        let meditation = Task(title: "Meditation", order: 3, category: .required)
        let email = Task(title: "Check email", order: 4, category: .required)
        
        // Suggested tasks
        let exercise = Task(title: "Exercise", order: 1, category: .suggested)
        let reading = Task(title: "Reading", order: 2, category: .suggested)
        let journaling = Task(title: "Journaling", order: 3, category: .suggested)
        
        // Add time to some tasks
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
        
        // Insert tasks
        context.insert(breakfast)
        context.insert(brushTeeth)
        context.insert(meditation)
        context.insert(email)
        context.insert(exercise)
        context.insert(reading)
        context.insert(journaling)
        
        try context.save()
    }
    
    /// Creates a model container with sample data for previews and tests
    static func createPreviewContainer() -> ModelContainer {
        do {
            let schema = Schema([Task.self])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            
            let context = ModelContext(container)
            try createSampleTasks(in: context)
            
            return container
        } catch {
            fatalError("Failed to create preview container: \(error.localizedDescription)")
        }
    }
}