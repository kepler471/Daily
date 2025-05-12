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
    
    // Test the Todo model creation and property access
    @Test func testTodoCreation() async throws {
        // Create a todo with required attributes
        let todo = Todo(title: "Test Todo", order: 1, category: .required)
        
        // Verify properties were set correctly
        #expect(todo.title == "Test Todo")
        #expect(todo.order == 1)
        #expect(todo.category == .required)
        #expect(todo.isCompleted == false)
        #expect(todo.scheduledTime == nil)
        #expect(todo.createdAt <= Date())
    }
    
    // Test the Todo model's category property and raw storage
    @Test func testTodoCategory() async throws {
        // Create todos with different categories
        let requiredTodo = Todo(title: "Required Todo", order: 1, category: .required)
        let suggestedTodo = Todo(title: "Suggested Todo", order: 2, category: .suggested)
        
        // Verify categories are set correctly
        #expect(requiredTodo.category == .required)
        #expect(suggestedTodo.category == .suggested)
        
        // Verify raw storage
        #expect(requiredTodo.categoryRaw == "required")
        #expect(suggestedTodo.categoryRaw == "suggested")
        
        // Test changing category
        requiredTodo.category = .suggested
        #expect(requiredTodo.category == .suggested)
        #expect(requiredTodo.categoryRaw == "suggested")
    }
    
    // Test Todo predicates
    @Test func testTodoPredicates() async throws {
        // Test category predicate
        let requiredPredicate = Todo.Predicates.byCategory(.required)
        let allCategoriesPredicate = Todo.Predicates.byCategory(nil)
        
        // Create test todos
        let requiredTodo = Todo(title: "Required Todo", order: 1, category: .required)
        let suggestedTodo = Todo(title: "Suggested Todo", order: 2, category: .suggested)
        
        // Verify predicate filtering works as expected
        #expect(try requiredPredicate.evaluate(requiredTodo))
        #expect(!(try requiredPredicate.evaluate(suggestedTodo)))
        #expect(try allCategoriesPredicate.evaluate(requiredTodo))
        #expect(try allCategoriesPredicate.evaluate(suggestedTodo))
        
        // Test completion predicate
        let completedPredicate = Todo.Predicates.byCompletion(isCompleted: true)
        let incompletePredicate = Todo.Predicates.byCompletion(isCompleted: false)
        
        // Both todos start as incomplete
        #expect(!(try completedPredicate.evaluate(requiredTodo)))
        #expect(try incompletePredicate.evaluate(requiredTodo))
        
        // Mark one todo as completed
        requiredTodo.isCompleted = true
        
        // Verify predicates now return the expected results
        #expect(try completedPredicate.evaluate(requiredTodo))
        #expect(!(try incompletePredicate.evaluate(requiredTodo)))
    }
    
    // Test ModelContext extensions with an in-memory container
    @Test func testModelContextExtensions() async throws {
        // Create an in-memory container for testing
        let container = try ModelContainer(for: Todo.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        
        // Create some test todos
        let todo1 = Todo(title: "Todo 1", order: 1, category: .required)
        let todo2 = Todo(title: "Todo 2", order: 2, category: .required)
        let todo3 = Todo(title: "Todo 3", order: 3, category: .suggested)
        
        // Add todos to the context
        context.insert(todo1)
        context.insert(todo2)
        context.insert(todo3)
        
        try context.save()
        
        // Test count methods with no todos completed
        let initialTotalCount = try context.countTodos()
        let initialCompletedCount = try context.countCompletedTodos()
        let initialIncompleteCount = try context.countIncompleteTodos()
        
        #expect(initialTotalCount == 3)
        #expect(initialCompletedCount == 0)
        #expect(initialIncompleteCount == 3)
        
        // Mark some todos as completed
        todo1.isCompleted = true
        todo3.isCompleted = true
        
        try context.save()
        
        // Test count methods after completing todos
        let updatedTotalCount = try context.countTodos()
        let updatedCompletedCount = try context.countCompletedTodos()
        let updatedIncompleteCount = try context.countIncompleteTodos()
        
        #expect(updatedTotalCount == 3)
        #expect(updatedCompletedCount == 2)
        #expect(updatedIncompleteCount == 1)
        
        // Test category-specific counts
        let requiredTotal = try context.countTodos(category: .required)
        let requiredCompleted = try context.countCompletedTodos(category: .required)
        let suggestedCompleted = try context.countCompletedTodos(category: .suggested)
        
        #expect(requiredTotal == 2)
        #expect(requiredCompleted == 1)
        #expect(suggestedCompleted == 1)
    }
}
