//
//  TaskCounterView.swift
//  Daily
//
//  Created by Stelios Georgiou on 06/05/2025.
//

import SwiftUI
import SwiftData

struct TaskCounterView: View {
    // Use direct queries to observe tasks dynamically
    @Query(sort: \Task.order) private var allTasks: [Task]
    @Query(filter: #Predicate<Task> { $0.isCompleted == true }, sort: \Task.order) private var completedTasks: [Task]
    
    // For category-specific filtering
    let category: TaskCategory?
    
    init(category: TaskCategory? = nil) {
        self.category = category
        
        if let category = category {
            // Category-specific queries
            _allTasks = Query(filter: #Predicate<Task> { $0.categoryRaw == category.rawValue }, 
                             sort: \Task.order)
            _completedTasks = Query(filter: #Predicate<Task> { 
                $0.categoryRaw == category.rawValue && $0.isCompleted == true 
            }, sort: \Task.order)
        }
    }
    
    var body: some View {
        // Calculate counts directly from observed arrays
        Text("\(completedTasks.count)/\(allTasks.count)")
            .font(.title)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
            .id(UUID()) // Force refresh on state changes
//            .onChange(of: allTasks.count) { _, _ in } // Trigger view update when count changes
//            .onChange(of: completedTasks.count) { _, _ in } // Trigger view update when count changes
            .animation(.easeInOut, value: completedTasks.count)
    }
}

#Preview {
    TaskCounterView(category: .required)
        .modelContainer(TaskMockData.createPreviewContainer())
        .padding()
}
