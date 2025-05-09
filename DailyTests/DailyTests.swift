//
//  DailyTests.swift
//  DailyTests
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import Testing
import SwiftData
import Foundation
@testable import Daily

struct DailyTests {
    
    // Test the Task model creation and property access
    @Test func testTaskCreation() async throws {
        // Create a task with required attributes
        let task = Task(title: "Test Task", order: 1, category: .required)
        
        // Verify properties were set correctly
        #expect(task.title == "Test Task")
        #expect(task.order == 1)
        #expect(task.category == .required)
        #expect(task.isCompleted == false)
        #expect(task.scheduledTime == nil)
        #expect(task.createdAt <= Date())
    }
    
    // Test the Task model's category property and raw storage
    @Test func testTaskCategory() async throws {
        // Create tasks with different categories
        let requiredTask = Task(title: "Required Task", order: 1, category: .required)
        let suggestedTask = Task(title: "Suggested Task", order: 2, category: .suggested)
        
        // Verify categories are set correctly
        #expect(requiredTask.category == .required)
        #expect(suggestedTask.category == .suggested)
        
        // Verify raw storage
        #expect(requiredTask.categoryRaw == "required")
        #expect(suggestedTask.categoryRaw == "suggested")
        
        // Test changing category
        requiredTask.category = .suggested
        #expect(requiredTask.category == .suggested)
        #expect(requiredTask.categoryRaw == "suggested")
    }
    
    // Test Task predicates
    @Test func testTaskPredicates() async throws {
        // Test category predicate
        let requiredPredicate = Task.Predicates.byCategory(.required)
        let allCategoriesPredicate = Task.Predicates.byCategory(nil)
        
        // Create test tasks
        let requiredTask = Task(title: "Required Task", order: 1, category: .required)
        let suggestedTask = Task(title: "Suggested Task", order: 2, category: .suggested)
        
        // Verify predicate filtering works as expected
        #expect(try requiredPredicate.evaluate(requiredTask))
        #expect(!(try requiredPredicate.evaluate(suggestedTask)))
        #expect(try allCategoriesPredicate.evaluate(requiredTask))
        #expect(try allCategoriesPredicate.evaluate(suggestedTask))
        
        // Test completion predicate
        let completedPredicate = Task.Predicates.byCompletion(isCompleted: true)
        let incompletePredicate = Task.Predicates.byCompletion(isCompleted: false)
        
        // Both tasks start as incomplete
        #expect(!(try completedPredicate.evaluate(requiredTask)))
        #expect(try incompletePredicate.evaluate(requiredTask))
        
        // Mark one task as completed
        requiredTask.isCompleted = true
        
        // Verify predicates now return the expected results
        #expect(try completedPredicate.evaluate(requiredTask))
        #expect(!(try incompletePredicate.evaluate(requiredTask)))
    }
    
    // Test ModelContext extensions with an in-memory container
    @Test func testModelContextExtensions() async throws {
        // Create an in-memory container for testing
        let container = try ModelContainer(for: Task.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        
        // Create some test tasks
        let task1 = Task(title: "Task 1", order: 1, category: .required)
        let task2 = Task(title: "Task 2", order: 2, category: .required)
        let task3 = Task(title: "Task 3", order: 3, category: .suggested)
        
        // Add tasks to the context
        context.insert(task1)
        context.insert(task2)
        context.insert(task3)
        
        try context.save()
        
        // Test count methods with no tasks completed
        let initialTotalCount = try context.countTasks()
        let initialCompletedCount = try context.countCompletedTasks()
        let initialIncompleteCount = try context.countIncompleteTasks()
        
        #expect(initialTotalCount == 3)
        #expect(initialCompletedCount == 0)
        #expect(initialIncompleteCount == 3)
        
        // Mark some tasks as completed
        task1.isCompleted = true
        task3.isCompleted = true
        
        try context.save()
        
        // Test count methods after completing tasks
        let updatedTotalCount = try context.countTasks()
        let updatedCompletedCount = try context.countCompletedTasks()
        let updatedIncompleteCount = try context.countIncompleteTasks()
        
        #expect(updatedTotalCount == 3)
        #expect(updatedCompletedCount == 2)
        #expect(updatedIncompleteCount == 1)
        
        // Test category-specific counts
        let requiredTotal = try context.countTasks(category: .required)
        let requiredCompleted = try context.countCompletedTasks(category: .required)
        let suggestedCompleted = try context.countCompletedTasks(category: .suggested)
        
        #expect(requiredTotal == 2)
        #expect(requiredCompleted == 1)
        #expect(suggestedCompleted == 1)
    }
}