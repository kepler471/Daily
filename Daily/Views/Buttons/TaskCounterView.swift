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
    @Query private var allTasks: [Task]
    @Query private var completedTasks: [Task]
    
    // For category-specific filtering
    let category: TaskCategory?
    
    // Binding for showing completed tasks view
    @Binding var showCompletedTasks: Bool
    
    init(category: TaskCategory? = nil, showCompletedTasks: Binding<Bool> = .constant(false)) {
        self.category = category
        self._showCompletedTasks = showCompletedTasks
        
        let sortDescriptors = [SortDescriptor(\Task.order)]
        
        if let category = category {
            // Category-specific queries using predefined predicates
            _allTasks = Query(
                filter: Task.Predicates.byCategory(category),
                sort: sortDescriptors
            )
            _completedTasks = Query(
                filter: Task.Predicates.byCategoryAndCompletion(category: category, isCompleted: true),
                sort: sortDescriptors
            )
        } else {
            // All tasks and completed tasks
            _allTasks = Query(sort: sortDescriptors)
            _completedTasks = Query(
                filter: Task.Predicates.byCompletion(isCompleted: true),
                sort: sortDescriptors
            )
        }
    }
    
    var body: some View {
        // Calculate counts directly from observed arrays
        Button(action: {
            showCompletedTasks = true
        }) {
            Text("\(completedTasks.count)/\(allTasks.count)")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .id(UUID()) // Force refresh on state changes
                .animation(.easeInOut, value: completedTasks.count)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

#Preview {
    TaskCounterView(category: .required, showCompletedTasks: .constant(false))
        .modelContainer(TaskMockData.createPreviewContainer())
        .padding()
}
