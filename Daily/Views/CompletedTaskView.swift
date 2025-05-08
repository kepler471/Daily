//
//  CompletedTaskView.swift
//  Daily
//
//  Created using Claude Code.
//

import SwiftUI
import SwiftData

struct CompletedTaskView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Query for completed tasks, sorted by order
    @Query private var completedTasks: [Task]
    
    // Filter by category if provided
    let category: TaskCategory?
    
    // Binding to control visibility
    @Binding var isPresented: Bool
    
    // State for hover effects
    @State private var hoveredTaskId: PersistentIdentifier? = nil
    
    init(category: TaskCategory? = nil, isPresented: Binding<Bool>) {
        self.category = category
        self._isPresented = isPresented
        
        let sortDescriptors = [
            SortDescriptor(\Task.order),
            SortDescriptor(\Task.createdAt)
        ]
        
        if let category = category {
            // Category-specific query using predefined predicates
            _completedTasks = Query(
                filter: Task.Predicates.byCategoryAndCompletion(category: category, isCompleted: true),
                sort: sortDescriptors
            )
        } else {
            // All completed tasks
            _completedTasks = Query(
                filter: Task.Predicates.byCompletion(isCompleted: true),
                sort: sortDescriptors
            )
        }
    }
    
    // Computed property for the title based on category
    private var categoryTitle: String {
        switch category {
        case .required:
            return "Completed Required Tasks"
        case .suggested:
            return "Completed Suggested Tasks"
        case nil:
            return "All Completed Tasks"
        }
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Translucent blurred background
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.85)
                .ignoresSafeArea()
            
            // Close button
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.title)
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            VStack(spacing: 20) {
                // Title
                Text(categoryTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 40)
                
                if completedTasks.isEmpty {
                    Spacer()
                    Text("No completed tasks")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                } else {
                    // Tasks stack
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(completedTasks) { task in
                                completedTaskCard(for: task)
                                    .scaleEffect(hoveredTaskId == task.persistentModelID ? 1.05 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hoveredTaskId)
                                    .onHover { isHovered in
                                        hoveredTaskId = isHovered ? task.persistentModelID : nil
                                    }
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                    }
                }
            }
            .padding(.top, 60)
        }
    }
    
    @ViewBuilder
    private func completedTaskCard(for task: Task) -> some View {
        HStack {
            // Task title and scheduled time (if exists)
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .strikethrough(task.isCompleted)
                
                if let scheduledTime = task.scheduledTime {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        
                        Text(scheduledTime, format: .dateTime.hour().minute())
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                }
            }
            
            Spacer()
            
            // Category badge
            Text(task.category == .required ? "Required" : "Suggested")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(task.category == .required ? Color.blue.opacity(0.2) : Color.purple.opacity(0.2))
                )
                .foregroundColor(task.category == .required ? .blue : .purple)
            
            // Reopen button
            Button(action: {
                toggleTaskCompletion(task)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward.circle")
                    Text("Reopen")
                }
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
        .padding()
        .background(
            Rectangle()
                .fill(.regularMaterial)
                .opacity(0.9)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func toggleTaskCompletion(_ task: Task) {
        task.isCompleted.toggle()
        
        do {
            try modelContext.save()
        } catch {
            print("Error toggling task completion: \(error.localizedDescription)")
        }
    }
}

// Note: Task in Swift/SwiftData already conforms to Identifiable
// by virtue of the @Model macro, so we don't need to add an extension here

#Preview {
    CompletedTaskView(isPresented: .constant(true))
        .modelContainer(TaskMockData.createPreviewContainer())
}