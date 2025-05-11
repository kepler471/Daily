//
//  EditTaskView.swift
//  Daily
//
//  Created by Stelios Georgiou on 11/05/2025.
//

import SwiftUI
import SwiftData
import UserNotifications

/// A view that provides the user interface for editing an existing task
struct EditTaskView: View {
    // MARK: - Environment and State

    /// The model context for saving task changes
    @Environment(\.modelContext) private var modelContext

    /// The settings manager for notification preferences
    @EnvironmentObject private var settingsManager: SettingsManager

    /// The task being edited
    @Bindable var task: Task
    
    /// The edited title of the task
    @State private var title: String
    
    /// The edited category for the task
    @State private var selectedCategory: TaskCategory
    
    /// Components for the custom time picker
    @State private var selectedHour: Int
    @State private var selectedMinute: Int
    @State private var isAM: Bool
    
    /// Whether a time is scheduled for this task
    @State private var hasScheduledTime: Bool
    
    /// Binding to control the visibility of this view
    @Binding var isPresented: Bool
    
    /// Focus state for the title text field
    @FocusState private var isTitleFieldFocused: Bool
    
    /// The scheduled time for the task calculated from picker components
    private var scheduledTime: Date? {
        guard hasScheduledTime else { return nil }
        
        let calendar = Calendar.current
        let hour = selectedHour + (isAM ? 0 : 12)
        let minute = selectedMinute
        
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour == 12 && isAM ? 0 : (hour == 0 && !isAM ? 12 : hour)
        components.minute = minute
        
        return calendar.date(from: components)
    }
    
    // MARK: - Initialization
    
    /// Creates a new edit task view for an existing task
    /// - Parameters:
    ///   - task: The task to edit
    ///   - isPresented: Binding to control the visibility of the view
    init(task: Task, isPresented: Binding<Bool>) {
        self.task = task
        self._isPresented = isPresented
        
        // Initialize state with existing task values
        _title = State(initialValue: task.title)
        _selectedCategory = State(initialValue: task.category)
        
        // Set default time values
        let now = Date()
        let calendar = Calendar.current
        _selectedHour = State(initialValue: calendar.component(.hour, from: now) % 12)
        _selectedMinute = State(initialValue: calendar.component(.minute, from: now))
        _isAM = State(initialValue: calendar.component(.hour, from: now) < 12)
        
        // Check if the task has a scheduled time
        if let scheduledTime = task.scheduledTime {
            _hasScheduledTime = State(initialValue: true)
            
            // Extract time components from the task's scheduled time
            let hour = calendar.component(.hour, from: scheduledTime)
            let minute = calendar.component(.minute, from: scheduledTime)
            
            // Convert hour to 12-hour format and determine AM/PM
            _selectedHour = State(initialValue: hour % 12 == 0 ? 12 : hour % 12)
            _selectedMinute = State(initialValue: minute)
            _isAM = State(initialValue: hour < 12)
        } else {
            _hasScheduledTime = State(initialValue: false)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // MARK: Background
            
            // Translucent blurred background overlay
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.85)
                .ignoresSafeArea()
            
            // MARK: Content
            
            ScrollView {
                VStack(spacing: 20) {
                    // Title section
                    Text("Edit Task")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                        .padding(.bottom, 10)

                    // MARK: Task Card

                    VStack(spacing: 20) {
                        // MARK: - Task title

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            TextField("Task name", text: $title)
                                .font(.system(size: 18, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                                .focused($isTitleFieldFocused)
                                .accessibilityIdentifier("taskTitleField")
                        }

                        // MARK: - Category selection

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Picker("", selection: $selectedCategory) {
                                Text("Required").tag(TaskCategory.required)
                                Text("Suggested").tag(TaskCategory.suggested)
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                            .padding(.vertical, 5)
                            .accessibilityIdentifier("categoryPicker")
                            .accessibilityLabel("Task Category")
                        }

                        // MARK: - Time settings

                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Schedule Time", isOn: $hasScheduledTime)
                                .font(.headline)
                                .foregroundColor(.secondary)

                            if hasScheduledTime {
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
                            }
                        }

                        Spacer()
                            .frame(height: 10)

                        // MARK: - Save button

                        Button {
                            saveChanges()
                            isPresented = false
                        } label: {
                            Text("Save Changes")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .padding(.vertical, 16)
                                .background(
                                    Capsule()
                                        .fill(title.isEmpty ? Color.gray.opacity(0.5) : selectedCategory == .required ? Color.blue : Color.purple)
                                )
                                .contentShape(Rectangle())
                        }
                        .disabled(title.isEmpty)
                        .buttonStyle(.borderless)
                        .accessibilityIdentifier("saveChangesButton")
                        .accessibilityHint("Saves task changes")
                    }
                    .padding(30)
                    .background(
                        Rectangle()
                            .fill(.regularMaterial)
                            .opacity(0.9)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                selectedCategory == .required ? .blue.opacity(0.5) : .purple.opacity(0.5),
                                                selectedCategory == .required ? .teal.opacity(0.3) : .pink.opacity(0.3)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 30)
                .frame(maxWidth: 600)
            }
        }
        .onAppear {
            // Auto-focus the title field when the view appears
            isTitleFieldFocused = true
        }
        .withCloseButton(
            action: { isPresented = false },
            size: 36,
            iconSize: 18
        )
    }
    
    // MARK: - Actions
    
    /// Saves the changes to the task
    private func saveChanges() {
        // Update task properties
        task.title = title
        task.category = selectedCategory
        task.scheduledTime = scheduledTime
        
        do {
            // Save changes to the database
            try modelContext.save()
            
            // Update notification if there's a scheduled time
            SwiftUI.Task {
                if task.scheduledTime != nil {
                    await task.scheduleNotification(settings: settingsManager)
                } else {
                    await task.cancelNotification()
                }
            }
        } catch {
            print("Error saving task changes: \(error.localizedDescription)")
        }
    }
}

// MARK: - Previews

#Preview("Edit Task") {
    let container = TaskMockData.createPreviewContainer()
    let context = ModelContext(container)
    let task = Task(
        title: "Morning Meditation",
        order: 1,
        category: .required,
        scheduledTime: Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date())
    )
    context.insert(task)
    
    return EditTaskView(task: task, isPresented: .constant(true))
        .environmentObject(SettingsManager())
}

#Preview("Edit Task - No Time") {
    let container = TaskMockData.createPreviewContainer()
    let context = ModelContext(container)
    let task = Task(
        title: "Read a book",
        order: 2,
        category: .suggested,
        scheduledTime: nil
    )
    context.insert(task)
    
    return EditTaskView(task: task, isPresented: .constant(true))
        .environmentObject(SettingsManager())
}