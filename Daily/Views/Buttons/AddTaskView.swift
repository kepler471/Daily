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
            SharpPlus(size: 24)          // tailor size here
                .padding(16)             // ≥ 44×44 tap target
        }
        .buttonStyle(.plain)             // no default shading/tint
        .contentShape(Rectangle())
    }
}

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var selectedCategory: TaskCategory = .required
    @State private var hasScheduledTime = false
    @State private var scheduledTime = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    
                    Picker("Category", selection: $selectedCategory) {
                        Text("Required").tag(TaskCategory.required)
                        Text("Suggested").tag(TaskCategory.suggested)
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                    
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
                            .fill(title.isEmpty ? Color.gray : selectedCategory == .required ? Color.blue : Color.green)
                    )
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("New Task")
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

/// A crisp, solid “+” icon whose tips are square.
struct SharpPlus: View {
    /// Overall edge length of the plus (outside to outside).
    var size: CGFloat = 24
    /// Thickness of each arm. 1⁄6 of the size is a pleasing default.
    var thickness: CGFloat { size / 6 }
    /// Fill colour of the symbol.
    var color: Color = .black
    
    var body: some View {
        ZStack {
            // Vertical bar
            Rectangle()
                .fill(color)
                .frame(width: thickness, height: size)
            // Horizontal bar
            Rectangle()
                .fill(color)
                .frame(width: size, height: thickness)
        }
        // Keep the drawing centred inside any parent frame
        .frame(width: size, height: size)
        .accessibilityLabel(Text("Add"))
    }
}

#Preview {
    AddTaskButtonView(showingAddTask: .constant(false))
        .padding()
}
