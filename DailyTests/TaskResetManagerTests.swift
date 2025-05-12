//
//  TodoResetManagerTests.swift
//  DailyTests
//
//  Created by Stelios Georgiou on 08/05/2025.
//

import Testing
import SwiftData
import Foundation
@testable import Daily

struct TodoResetManagerTests {
    
    // Test that todos are properly reset to incomplete
    @Test func testTodoReset() async throws {
        // Create an in-memory container for testing
        let container = try ModelContainer(for: Todo.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        
        // Create some test todos (both completed and incomplete)
        let todo1 = Todo(title: "Test Todo 1", order: 1, category: .required)
        let todo2 = Todo(title: "Test Todo 2", order: 2, category: .required)
        let todo3 = Todo(title: "Test Todo 3", order: 3, category: .suggested)
        
        // Add todos to the context
        context.insert(todo1)
        context.insert(todo2)
        context.insert(todo3)
        
        // Mark some todos as completed
        todo1.isCompleted = true
        todo3.isCompleted = true
        
        try context.save()
        
        // Verify we have 2 completed todos
        let completedTodosCount = try context.countCompletedTodos()
        #expect(completedTodosCount == 2)
        
        // Create the reset manager and reset todos
        let resetManager = TodoResetManager(modelContext: context)
        resetManager.resetTodosNow()
        
        // Check that all todos are now incomplete
        let completedTodosAfterReset = try context.countCompletedTodos()
        #expect(completedTodosAfterReset == 0)
        
        // Verify each individual todo status
        #expect(todo1.isCompleted == false)
        #expect(todo2.isCompleted == false)
        #expect(todo3.isCompleted == false)
    }
    
    // Test that the next reset date is calculated correctly
    @Test func testNextResetDateCalculation() async throws {
        // Create a todo reset manager with a test context
        let container = try ModelContainer(for: Todo.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        
        // Create a test reset manager
        let resetManager = TodoResetManager(modelContext: context)
        
        // Access the calculateNextResetDate method directly (now internal instead of private)
        let nextResetDate = resetManager.calculateNextResetDate()
        
        // Get the expected reset time (4am today or tomorrow)
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 4
        components.minute = 0
        components.second = 0
        
        guard let todayResetDate = calendar.date(from: components) else {
            throw NSError(domain: "TestError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create today's reset date"])
        }
        
        // If it's already past 4am today, expect tomorrow's date
        let expectedDate = Date() > todayResetDate
            ? calendar.date(byAdding: .day, value: 1, to: todayResetDate)!
            : todayResetDate
        
        // Compare the dates, allowing a small tolerance for test execution time
        let timeInterval = nextResetDate.timeIntervalSince(expectedDate)
        #expect(abs(timeInterval) < 1.0)
    }
}
