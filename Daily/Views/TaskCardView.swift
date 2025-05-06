//
//  TaskCardView.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import SwiftUI
import SwiftData

struct TaskCardView: View {
    @Bindable var task: Task
    var onToggleComplete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)
                
                Spacer()
                
                categoryBadge
            }
            
            if let scheduledTime = task.scheduledTime {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    
                    Text(scheduledTime, format: .dateTime.hour().minute())
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
            }
            
            HStack {
                Spacer()
                
                completionButton
            }
        }
        .padding()
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .contentShape(Rectangle()) // Makes the whole card tappable
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
    
    private var cardBackground: some View {
        Group {
            if task.isCompleted {
                Color(.windowBackgroundColor).opacity(0.8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else {
                Color(.windowBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        task.category == .required ? .blue.opacity(0.5) : .purple.opacity(0.5),
                                        task.category == .required ? .teal.opacity(0.3) : .pink.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            }
        }
    }
    
    private var categoryBadge: some View {
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
    }
    
    private var completionButton: some View {
        Button(action: onToggleComplete) {
            HStack(spacing: 4) {
                Image(systemName: task.isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle")
                Text(task.isCompleted ? "Reopen" : "Complete")
            }
            .font(.footnote)
            .fontWeight(.medium)
            .foregroundColor(task.isCompleted ? .orange : .green)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(task.isCompleted ? Color.orange.opacity(0.1) : Color.green.opacity(0.1))
            )
        }
    }
}

#Preview {
    let container = TaskMockData.createPreviewContainer()
    let context = ModelContext(container)
    let task = Task(
        title: "Morning Meditation",
        order: 1,
        category: .required,
        scheduledTime: Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date())
    )
    context.insert(task)
    
    return TaskCardView(task: task, onToggleComplete: {})
        .frame(width: 350)
        .previewLayout(.sizeThatFits)
        .padding()
}
