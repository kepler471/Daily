//
//  ContentView.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TaskListView(category: .required)
                .tabItem {
                    Label("Required", systemImage: "checklist")
                }
                .tag(0)
            
            TaskListView(category: .suggested)
                .tabItem {
                    Label("Suggested", systemImage: "star")
                }
                .tag(1)
        }
        .toolbar {
            ToolbarItem {
                Button(action: addTask) {
                    Label("Add Task", systemImage: "plus")
                }
            }
        }
    }
    
    private func addTask() {
        withAnimation {
            let category: TaskCategory = selectedTab == 0 ? .required : .suggested
            let newTask = Task(title: "New Task", order: getNextOrder(for: category), category: category)
            modelContext.insert(newTask)
        }
    }
    
    private func getNextOrder(for category: TaskCategory) -> Int {
        do {
            var descriptor = FetchDescriptor<Task>(
                sortBy: [SortDescriptor(\Task.order, order: .reverse)]
            )
            descriptor.predicate = #Predicate<Task> { task in
                task.category == category
            }
            descriptor.fetchLimit = 1
            
            let result = try modelContext.fetch(descriptor)
            return (result.first?.order ?? 0) + 1
        } catch {
            print("Error fetching next order: \(error)")
            return 0
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(TaskMockData.createPreviewContainer())
}