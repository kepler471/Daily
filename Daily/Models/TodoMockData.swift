//
//  TodoMockData.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import Foundation
import SwiftData

// MARK: - Mock Data Provider

/// Utility for generating sample todo data for development, testing and SwiftUI previews
///
/// This struct provides methods to:
/// - Create sample todos in a SwiftData model context
/// - Set up an in-memory model container with predefined todos
/// - Populate test environments with realistic todo data
struct TodoMockData {

    // MARK: - Sample Data Generation

    /// Creates sample todos for preview and testing purposes if none exist
    /// - Parameter context: The SwiftData model context to insert todos into
    /// - Throws: Error if database operations fail
    static func createSampleTodos(in context: ModelContext) throws {
        // Check if todos already exist to avoid duplicates
        let todoCount = try context.fetchCount(FetchDescriptor<Todo>())
        guard todoCount == 0 else { return }

        // MARK: Todo Creation

        // Create required daily todos
        let breakfast = Todo(title: "Breakfast", order: 1, category: .required)
        let brushTeeth = Todo(title: "Brush teeth", order: 2, category: .required)
        let meditation = Todo(title: "Meditation", order: 3, category: .required)
        let email = Todo(title: "Check email", order: 4, category: .required)
        let lunch = Todo(title: "Eat some lunch", order: 5, category: .required)
        let dinner = Todo(title: "Eat some dinner", order: 9, category: .required)

        // Create suggested optional todos
        let exercise = Todo(title: "Exercise", order: 6, category: .suggested)
        let reading = Todo(title: "Reading", order: 7, category: .suggested)
        let journaling = Todo(title: "Journaling", order: 8, category: .suggested)

        // MARK: Todo Scheduling

        // Set scheduled times for some todos
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

        // Insert all todos into the database
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

    /// Creates an in-memory SwiftData model container populated with sample todos
    /// - Returns: A configured ModelContainer ready to use in SwiftUI previews or tests
    static func createPreviewContainer() -> ModelContainer {
        do {
            // Set up an in-memory container
            let schema = Schema([Todo.self])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [configuration])

            // Populate it with sample data
            let context = ModelContext(container)
            try createSampleTodos(in: context)

            return container
        } catch {
            fatalError("Failed to create preview container: \(error.localizedDescription)")
        }
    }
}
