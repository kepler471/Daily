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
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
                .padding(4)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .focusable(false)
    }
}

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var selectedCategory: TaskCategory = .required
    @State private var hasScheduledTime = false
    @State private var scheduledTime = Date()
    @FocusState private var isTitleFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Task name", text: $title)
                    .font(.system(size: 18, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                    .focused($isTitleFieldFocused)
                
                Picker("", selection: $selectedCategory) {
                    Text("Required").tag(TaskCategory.required)
                    Text("Suggested").tag(TaskCategory.suggested)
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 5)
                
                HStack {
                    Toggle("", isOn: $hasScheduledTime)
                        .labelsHidden()
                    
                    Text("Time")
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                    
                    Spacer()
                    
                    if hasScheduledTime {
                        DatePicker("", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .fixedSize()
                    }
                }
                .padding(.vertical, 5)
                
                Spacer()
                
                Button("Add Task") {
                    addTask()
                    dismiss()
                }
                .disabled(title.isEmpty)
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(title.isEmpty ? Color.gray.opacity(0.5) : selectedCategory == .required ? Color.blue : Color.green)
                )
                .buttonStyle(.plain)
                .focusable(false)
            }
            .padding(20)
            .navigationTitle("New Task")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .defaultFocus($isTitleFieldFocused, true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(300)])
        .onAppear {
            // Auto-focus the title field when the sheet appears
            isTitleFieldFocused = true
        }
    }
    
    private func addTask() {
        withAnimation {
            let newTask = Task(
                title: title,
                order: getNextOrder(),
                category: selectedCategory,
                scheduledTime: hasScheduledTime ? scheduledTime : nil
            )
            modelContext.insert(newTask)
        }
    }
    
    private func getNextOrder() -> Int {
        do {
            let categoryString = selectedCategory.rawValue
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
}