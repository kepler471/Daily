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
    
    /// Components for the custom time picker
    @State private var selectedHour = Calendar.current.component(.hour, from: Date()) % 12
    @State private var selectedMinute = Calendar.current.component(.minute, from: Date())
    @State private var isAM = Calendar.current.component(.hour, from: Date()) < 12

    /// The scheduled time for the task calculated from picker components
    private var scheduledTime: Date {
        let calendar = Calendar.current
        let hour = selectedHour + (isAM ? 0 : 12)
        let minute = selectedMinute

        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour == 12 && isAM ? 0 : (hour == 0 && !isAM ? 12 : hour)
        components.minute = minute

        return calendar.date(from: components) ?? Date()
    }
    
    /// Focus state for the title text field
    @FocusState private var isTitleFieldFocused: Bool
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Add top spacing to avoid X button overlap
                Spacer()
                    .frame(height: 32)
                
                // MARK: - Task title
                
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
                
                // MARK: - Category selection
                Picker("", selection: $selectedCategory) {
                    Text("Required").tag(TaskCategory.required)
                    Text("Suggested").tag(TaskCategory.suggested)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .padding(.vertical, 5)
                .accessibilityIdentifier("categoryPicker")
                .accessibilityLabel("Task Category")
                
                // MARK: - Custom time picker

                // Time selection components
                HStack(alignment: .center, spacing: 4) {
                    // Hours picker
                    VStack(alignment: .center, spacing: 2) {
                        Picker("", selection: $selectedHour) {
                            ForEach(1...12, id: \.self) { hour in
                                Text("\(hour)").tag(hour == 12 ? 0 : hour)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 60)
                        .fixedSize()
                        .accessibilityLabel("Hour")
                    }

                    // Minutes picker
                    VStack(alignment: .center, spacing: 2) {
                        Picker("", selection: $selectedMinute) {
                            ForEach(0..<60) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 60)
                        .fixedSize()
                        .accessibilityLabel("Minute")
                    }

                    // AM/PM picker
                    VStack(alignment: .center, spacing: 2) {
                        Picker("", selection: $isAM) {
                            Text("AM").tag(true)
                            Text("PM").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                        .accessibilityLabel("AM or PM")
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                
                // Add task button - only enabled if both title and time are set
                Button {
                    addTask()
                    dismiss()
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
                .accessibilityHint("Creates a new task with the provided details and scheduled time")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
//            .navigationBarHidden(true)
            .defaultFocus($isTitleFieldFocused, true)
            .overlay(
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .accessibilityLabel("Close")
                .accessibilityIdentifier("closeButton")
                .padding([.top, .leading], 16),
                alignment: .topLeading
            )
        }
        .presentationDetents([.height(550)])
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
                scheduledTime: scheduledTime
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

#Preview("Add Task Button") {
    AddTaskButtonView(showingAddTask: .constant(false))
        .padding()
}

#Preview("Add Task View") {
    AddTaskView()
}
