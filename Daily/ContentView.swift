//
//  ContentView.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var showingAddTask = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TaskCardsContainerView(category: .required)
                .tabItem {
                    Label("Required", systemImage: "checklist")
                }
                .tag(0)
            
            TaskCardsContainerView(category: .suggested)
                .tabItem {
                    Label("Suggested", systemImage: "star")
                }
                .tag(1)
        }
        .overlay(alignment: .bottom) {
            addButton
        }
        .overlay(alignment: .topTrailing) {
            #if DEBUG
            Button(action: resetData) {
                Image(systemName: "trash")
                    .padding(10)
                    .background(Circle().fill(.ultraThinMaterial))
                    .padding()
            }
            #endif
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(category: selectedTab == 0 ? .required : .suggested)
        }
    }
    
    private var addButton: some View {
        Button {
            showingAddTask = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
        }
        .padding(.bottom, 16)
    }
    
    #if DEBUG
    private func resetData() {
        // Delete all tasks
        do {
            try modelContext.delete(model: Task.self)
            
            // Re-add sample data
            try TaskMockData.createSampleTasks(in: modelContext)
        } catch {
            print("Error resetting data: \(error)")
        }
    }
    #endif
    
    private func getNextOrder(for category: TaskCategory) -> Int {
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
                            .fill(title.isEmpty ? Color.gray : Color.blue)
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
    ContentView()
        .modelContainer(TaskMockData.createPreviewContainer())
}