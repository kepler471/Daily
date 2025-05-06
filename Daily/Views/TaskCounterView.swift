//
//  TaskCounterView.swift
//  Daily
//
//  Created by Stelios Georgiou on 06/05/2025.
//

import SwiftUI
import SwiftData

struct TaskCounterView: View {
    @Environment(\.modelContext) private var modelContext
    let category: TaskCategory
    
    var body: some View {
        Text("\(getCompletedTaskCount())/\(getTaskCount())")
            .font(.title)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
    }
    
    private func getTaskCount() -> Int {
        do {
            let categoryString = category.rawValue
            var descriptor = FetchDescriptor<Task>()
            descriptor.predicate = #Predicate<Task> { task in
                task.categoryRaw == categoryString
            }
            
            return try modelContext.fetchCount(descriptor)
        } catch {
            print("Error fetching task count: \(error)")
            return 0
        }
    }
    
    private func getCompletedTaskCount() -> Int {
        do {
            let categoryString = category.rawValue
            var descriptor = FetchDescriptor<Task>()
            descriptor.predicate = #Predicate<Task> { task in
                task.categoryRaw == categoryString && task.isCompleted
            }
            
            return try modelContext.fetchCount(descriptor)
        } catch {
            print("Error fetching completed task count: \(error)")
            return 0
        }
    }
}

#Preview {
    TaskCounterView(category: .required)
        .modelContainer(TaskMockData.createPreviewContainer())
        .padding()
        .previewLayout(.sizeThatFits)
}