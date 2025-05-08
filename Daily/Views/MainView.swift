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
    @State private var showingAddTask = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main content with task columns
            HStack(spacing: 0) {
                // Required Tasks Column
                TaskStackView(category: .required, verticalOffset: 20, scale: 0.85)
                    .frame(minWidth: 0, maxWidth: .infinity)
                
                // Suggested Tasks Column
                TaskStackView(category: .suggested, verticalOffset: 20, scale: 0.85)
                    .frame(minWidth: 0, maxWidth: .infinity)
            }
            .padding(.top, 200)  // Space for the fixed control bar and fan-out space
            
            // Fixed top control bar
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    // Left half
                    HStack {
                        // Add button and reset at left
                        HStack(spacing: 12) {
                            // Add task button
                            AddTaskButtonView(showingAddTask: $showingAddTask, color: .purple)
                                
                            #if DEBUG
                            ResetDataView()
                            #endif
                        }
                        
                        Spacer()
                        
                        // Required category title centered in left half
                        Text("Required")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Counter right aligned
                        TaskCounterView(category: .required)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.horizontal)
                    
                    // Right half
                    HStack {
                        Spacer()
                        
                        // Suggested category title centered in right half
                        Text("Suggested")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Counter right aligned
                        TaskCounterView(category: .suggested)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.horizontal)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
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

