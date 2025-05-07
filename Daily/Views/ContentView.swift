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
            VStack(spacing: 0) {
                // Top row with add button, trash button, and counter
                HStack {
                    HStack(spacing: 12) {
                        AddTaskButtonView(showingAddTask: $showingAddTask)
                        
                        ResetDataView()
                    }
                    
                    Spacer()
                    
                    // Task counter
                    TaskCounterView(category: .required)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Task cards container
                TaskStackView()
            }
            .tabItem {
                Label("Required", systemImage: "checklist")
            }
            .tag(0)
            
            VStack(spacing: 0) {
                // Top row with add button, trash button, and counter
                HStack {
                    HStack(spacing: 12) {
                        AddTaskButtonView(showingAddTask: $showingAddTask)
                        
                        ResetDataView()
                    }
                    
                    Spacer()
                    
                    // Task counter
                    TaskCounterView(category: .suggested)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Task cards container
                TaskStackView()
            }
            .tabItem {
                Label("Suggested", systemImage: "star")
            }
            .tag(1)
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(category: selectedTab == 0 ? .required : .suggested)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(TaskMockData.createPreviewContainer())
}
