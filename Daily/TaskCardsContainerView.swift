//
//  TaskCardsContainerView.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import SwiftUI
import SwiftData

struct TaskCardsContainerView: View {
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
        ScrollView {
            VStack(spacing: 0) {
                ForEach(tasks) { task in
                    TaskCardView(task: task) {
                        toggleTaskCompletion(task)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Empty view at the bottom for better UX when scrolling
                Color.clear
                    .frame(height: 40)
            }
            .padding(.top)
        }
        .scrollIndicators(.hidden)
        .animation(.spring(duration: 0.3), value: tasks.map(\.isCompleted))
    }
    
    private func toggleTaskCompletion(_ task: Task) {
        withAnimation {
            task.isCompleted.toggle()
        }
    }
}

// Alternative Grid Layout Option
struct TaskCardsGridView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    
    let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 16)
    ]
    
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
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(tasks) { task in
                    TaskCardView(task: task) {
                        withAnimation {
                            task.isCompleted.toggle()
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// Alternative staggered layout option that can be enabled
extension TaskCardsContainerView {
    var staggeredBody: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                    TaskCardView(task: task) {
                        toggleTaskCompletion(task)
                    }
                    .offset(x: index % 2 == 0 ? -8 : 8)
                    .scaleEffect(task.isCompleted ? 0.95 : 1.0)
                }
                
                Color.clear
                    .frame(height: 40)
            }
            .padding(.top)
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    TaskCardsContainerView()
        .modelContainer(TaskMockData.createPreviewContainer())
}