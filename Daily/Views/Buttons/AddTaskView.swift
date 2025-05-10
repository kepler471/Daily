//
//  AddTaskView.swift
//  Daily
//
//  Created by Stelios Georgiou on 06/05/2025.
//

import SwiftUI
import SwiftData

/// A button view that triggers the task creation sheet
struct AddTaskButtonView: View {
    // MARK: - Properties
    
    /// Binding to control the presentation of the add task sheet
    @Binding var showingAddTask: Bool
    
    /// The color theme for the button (defaults to blue)
    var color: Color = .blue
    
    // MARK: - Body
    
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
        .accessibilityLabel("Add new task")
    }
}

/// A view that provides the user interface for creating a new task
struct AddTaskView: View {
    // MARK: - Environment and State
    
    /// The model context for saving new tasks
    @Environment(\.modelContext) private var modelContext
    
    /// Environment value for dismissing the sheet
    @Environment(\.dismiss) private var dismiss
    
    /// The title of the new task
    @State private var title = ""
    
    /// The selected category for the new task
    @State private var selectedCategory: TaskCategory = .required
    
    /// Whether the task has a scheduled time
    @State private var hasScheduledTime = false
    
    /// The scheduled time for the task if enabled
    @State private var scheduledTime = Date()
    
    /// Focus state for the title text field
    @FocusState private var isTitleFieldFocused: Bool
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Task title input field
                TextField("Task name", text: $title)
                    .font(.system(size: 18, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                    .focused($isTitleFieldFocused)
                    .accessibilityIdentifier("taskTitleField")
                    .onSubmit {
                        if !title.isEmpty {
                            addTask()
                            dismiss()
                        }
                    }
                
                // Category selection
                Picker("Task Category", selection: $selectedCategory) {
                    Text("Required").tag(TaskCategory.required)
                    Text("Suggested").tag(TaskCategory.suggested)
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 5)
                .accessibilityIdentifier("categoryPicker")
                
                // Time scheduling options
                HStack {
                    Toggle("Schedule Time", isOn: $hasScheduledTime)
                        .labelsHidden()
                        .accessibilityLabel("Schedule specific time")
                    
                    Text("Time")
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                    
                    Spacer()
                    
                    if hasScheduledTime {
                        DatePicker("Scheduled Time", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .fixedSize()
                            .accessibilityLabel("Select time for task")
                    }
                }
                .padding(.vertical, 5)
                
                Spacer()
                
                // Add task button
                Button {
                    if !title.isEmpty {
                        addTask()
                        dismiss()
                    }
                } label: {
                    Text("Add Task")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(title.isEmpty ? Color.gray.opacity(0.5) : selectedCategory == .required ? Color.blue : Color.green)
                        )
                        .contentShape(Rectangle()) // Make entire area clickable
                }
                .disabled(title.isEmpty)
                .buttonStyle(.borderless) // Use borderless style for better hit testing
                .focusable(false)
                .accessibilityIdentifier("addTaskButton")
                .accessibilityHint("Creates a new task with the provided details")
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
                    .accessibilityIdentifier("cancelButton")
                }
            }
        }
        .presentationDetents([.height(300)])
        .onAppear {
            // Auto-focus the title field when the sheet appears
            isTitleFieldFocused = true
        }
    }
    
    // MARK: - Helper Methods
    
    /// Creates and saves a new task with the current input values
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
    
    /// Calculates the next available order value for sorting tasks
    /// - Returns: The next order value for the selected category
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

// MARK: - Previews

#Preview {
    AddTaskButtonView(showingAddTask: .constant(false))
        .padding()
}