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
    let category: TaskCategory?
    
    init(category: TaskCategory? = nil) {
        self.category = category
    }
    
    var body: some View {
        Text("\(getCompletedTaskCount())/\(getTaskCount())")
            .font(.title)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
    }
    
    private func getTaskCount() -> Int {
        do {
            return try modelContext.countTasks(category: category)
        } catch {
            print("Error fetching task count: \(error)")
            return 0
        }
    }
    
    private func getCompletedTaskCount() -> Int {
        do {
            return try modelContext.countCompletedTasks(category: category)
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