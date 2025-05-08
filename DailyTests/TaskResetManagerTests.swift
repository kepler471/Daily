//
//  TaskResetManagerTests.swift
//  DailyTests
//
//  Created by Claude on 08/05/2025.
//

import Testing
import SwiftData
@testable import Daily

struct TaskResetManagerTests {
    
    // Test that tasks are properly reset to incomplete
    @Test func testTaskReset() async throws {
        // Create an in-memory container for testing
        let container = try ModelContainer(for: Task.self, configurations: [
            ModelConfiguration(isStoredInMemoryOnly: true)
        ])
        let context = ModelContext(container)
        
        // Create some test tasks (both completed and incomplete)
        let task1 = Task(title: "Test Task 1", order: 1, category: .required)
        let task2 = Task(title: "Test Task 2", order: 2, category: .required)
        let task3 = Task(title: "Test Task 3", order: 3, category: .suggested)
        
        // Add tasks to the context
        context.insert(task1)
        context.insert(task2)
        context.insert(task3)
        
        // Mark some tasks as completed
        task1.isCompleted = true
        task3.isCompleted = true
        
        try context.save()
        
        // Verify we have 2 completed tasks
        let completedTasksCount = try context.countCompletedTasks()
        #expect(completedTasksCount == 2, "Expected 2 completed tasks before reset")
        
        // Create the reset manager and reset tasks
        let resetManager = TaskResetManager(modelContext: context)
        resetManager.resetTasksNow()
        
        // Check that all tasks are now incomplete
        let completedTasksAfterReset = try context.countCompletedTasks()
        #expect(completedTasksAfterReset == 0, "Expected 0 completed tasks after reset")
        
        // Verify each individual task status
        #expect(task1.isCompleted == false, "Task 1 should be incomplete after reset")
        #expect(task2.isCompleted == false, "Task 2 should be incomplete after reset")
        #expect(task3.isCompleted == false, "Task 3 should be incomplete after reset")
    }
    
    // Test that the next reset date is calculated correctly
    @Test func testNextResetDateCalculation() async throws {
        // Create a task reset manager with a test context
        let container = try ModelContainer(for: Task.self, configurations: [
            ModelConfiguration(isStoredInMemoryOnly: true)
        ])
        let context = ModelContext(container)
        
        // Create a test reset manager
        let resetManager = TaskResetManager(modelContext: context)
        
        // Use reflection to access the private calculateNextResetDate method
        let nextResetDate = try {
            let mirror = Mirror(reflecting: resetManager)
            let calculateMethod = mirror.children.first { $0.label == "calculateNextResetDate" }?.value
            guard let calculate = calculateMethod as? () -> Date else {
                throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not access calculateNextResetDate method"])
            }
            return calculate()
        }()
        
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
        #expect(abs(timeInterval) < 1.0, "Next reset date should be at 4am today or tomorrow")
    }
}