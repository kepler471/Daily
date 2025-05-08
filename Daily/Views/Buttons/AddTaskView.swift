//
//  AddTaskView.swift
//  Daily
//
//  Created by Stelios Georgiou on 06/05/2025.
//

import SwiftUI
import SwiftData

struct AddTaskButtonView: View {
    @Binding var showingAddTask: Bool
    var color: Color = .blue
    
    var body: some View {
        Button {
            showingAddTask = true
        } label: {
            Image(systemName: "plus")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(color)
                )
        }
    }
}

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let category: TaskCategory
    
    @State private var title = ""
    @State private var hasScheduledTime = false
    @State private var scheduledTime = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    
                    Toggle("Schedule Time", isOn: $hasScheduledTime)
                    
                    if hasScheduledTime {
                        DatePicker("Time", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                    }
                }
                
                Section {
                    Button("Add Task") {
                        addTask()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(title.isEmpty ? Color.gray : category == .required ? Color.blue : Color.green)
                    )
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("New \(category.rawValue.capitalized) Task")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func addTask() {
        withAnimation {
            let newTask = Task(
                title: title,
                order: getNextOrder(),
                category: category,
                scheduledTime: hasScheduledTime ? scheduledTime : nil
            )
            modelContext.insert(newTask)
        }
    }
    
    private func getNextOrder() -> Int {
        do {
            let categoryString = category.rawValue
            var descriptor = FetchDescriptor<Task>(
                sortBy: [SortDescriptor(\Task.order, order: .reverse)]
            )
            descriptor.predicate = #Predicate<Task> { task in
                task.categoryRaw == categoryString
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
    AddTaskButtonView(showingAddTask: .constant(false))
        .padding()
        .previewLayout(.sizeThatFits)
}