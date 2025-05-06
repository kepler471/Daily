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
            let categoryString = category.rawValue
            _tasks = Query(filter: #Predicate<Task> { task in
                task.categoryRaw == categoryString
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
            ZStack(alignment: .top) {
                // We use the ZStack with top alignment for the overlapping effect
                VStack(spacing: 0) {
                    // Reserve space for all cards (minus their overlap)
                    // Each card is about 110-150px tall and we want to offset by the overlapping amount
                    if !tasks.isEmpty {
                        let totalHeight = CGFloat(tasks.count) * 140 - CGFloat(tasks.count - 1) * 30
                        Color.clear
                            .frame(height: totalHeight)
                    }
                }
                
                VStack(spacing: 0) {
                    ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                        TaskCardView(task: task) {
                            toggleTaskCompletion(task)
                        }
                        .zIndex(Double(tasks.count - index)) // Higher z-index for items at the top
                        .offset(y: CGFloat(index) * -30) // Negative offset to create overlap
                        .rotation3DEffect(
                            .degrees(index == 0 ? 0 : -2), // Slight rotation for 3D effect
                            axis: (x: 1.0, y: 0.0, z: 0.0), // Rotate around X axis
                            anchor: .top // Pivot from the top
                        )
                        .scaleEffect(1.0 - CGFloat(index) * 0.01) // Subtle scaling to enhance 3D effect
                        .transition(
                            .asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale(scale: 0.9).combined(with: .opacity).combined(with: .offset(y: -20))
                            )
                        )
                        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 3 + CGFloat(index))
                    }
                    
                    // Empty view at the bottom for better UX when scrolling
                    Color.clear
                        .frame(height: 40)
                }
            }
            .padding(.top)
        }
        .scrollIndicators(.hidden)
        .animation(.spring(duration: 0.3), value: tasks.map(\.isCompleted))
        .animation(.spring(duration: 0.5), value: tasks.count) // Animate when tasks are added/removed
    }
    
    private func toggleTaskCompletion(_ task: Task) {
        withAnimation {
            task.isCompleted.toggle()
        }
    }
}

#Preview("Default Stack Layout") {
    TaskCardsContainerView()
        .modelContainer(TaskMockData.createPreviewContainer())
}
