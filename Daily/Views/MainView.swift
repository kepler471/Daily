//
//  MainView.swift
//  Daily
//
//  Created by Stelios Georgiou on 08/05/2025.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddRequiredTask = false
    @State private var showingAddSuggestedTask = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Required Tasks Column
            VStack(spacing: 0) {
                // Top row with add button, trash button, and counter
                HStack {
                    HStack(spacing: 12) {
                        // Add task button
                        AddTaskButtonView(showingAddTask: $showingAddRequiredTask, color: .blue)
                        
                        #if DEBUG
                        ResetDataView()
                        #endif
                    }
                    
                    Spacer()
                    
                    Text("Required")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Task counter
                    TaskCounterView(category: .required)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Task cards container with overlapping effect
                TaskStackView(category: .required, verticalOffset: 20, scale: 0.85)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(Color.blue.opacity(0.05))
            
            // Divider between columns
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Suggested Tasks Column
            VStack(spacing: 0) {
                // Top row with add button, trash button, and counter
                HStack {
                    HStack(spacing: 12) {
                        // Add task button
                        AddTaskButtonView(showingAddTask: $showingAddSuggestedTask, color: .green)
                        
                        #if DEBUG
                        ResetDataView()
                        #endif
                    }
                    
                    Spacer()
                    
                    Text("Suggested")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Task counter
                    TaskCounterView(category: .suggested)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Task cards container with custom offset based on index
                TaskStackView(category: .suggested, verticalOffset: 20, scale: 0.85)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(Color.green.opacity(0.05))
        }
        .sheet(isPresented: $showingAddRequiredTask) {
            AddTaskView(category: .required)
        }
        .sheet(isPresented: $showingAddSuggestedTask) {
            AddTaskView(category: .suggested)
        }
    }
}

#Preview("Light Mode") {
    MainView()
        .preferredColorScheme(.light)
        .modelContainer(TaskMockData.createPreviewContainer())
        .frame(width: 800, height: 600)
}

#Preview("Dark Mode") {
    MainView()
        .preferredColorScheme(.dark)
        .modelContainer(TaskMockData.createPreviewContainer())
        .frame(width: 800, height: 600)
}
