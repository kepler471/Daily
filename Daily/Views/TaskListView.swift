//
//  TaskListView.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    
    init(category: TaskCategory? = nil) {
        if let category = category {
            _tasks = Query(filter: #Predicate { task in
                task.category == category
            }, sort: [
                SortDescriptor(\Task.order, order: .forward),
                SortDescriptor(\Task.createdAt, order: .forward)
            ])
        } else {
            _tasks = Query(sort: [
                SortDescriptor(\Task.order, order: .forward),
                SortDescriptor(\Task.createdAt, order: .forward)
            ])
        }
    }
    
    var body: some View {
        List {
            ForEach(tasks) { task in
                TaskRow(task: task)
            }
        }
    }
}

struct TaskRow: View {
    @Bindable var task: Task
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(task.title)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                
                if let scheduledTime = task.scheduledTime {
                    Text(scheduledTime, format: .dateTime.hour().minute())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(task.isCompleted ? "Incomplete" : "Complete") {
                task.isCompleted.toggle()
            }
            .tint(task.isCompleted ? .orange : .green)
        }
    }
}

#Preview {
    TaskListView()
        .modelContainer(TaskMockData.createPreviewContainer())
}