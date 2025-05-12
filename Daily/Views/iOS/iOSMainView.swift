//
//  iOSMainView.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/12/2025.
//

import SwiftUI
import SwiftData

/// The primary interface view for the Daily app on iOS
///
/// iOSMainView serves as the main content view displayed on iOS devices.
/// It provides:
/// - A tab-based interface for organizing different todo categories
/// - Touch-optimized UI for iOS devices
/// - Full screen displays for focused todos and settings
/// - iOS-specific navigation and gesture controls
struct iOSMainView: View {
    // MARK: Environment & State
    
    /// The SwiftData model context for database operations
    @Environment(\.modelContext) private var modelContext
    
    /// Access to the system settings API
    @Environment(\.openSettings) private var openSettings
    
    /// Whether the add todo sheet is being displayed
    @State private var showingAddTodo = false
    
    /// Whether the completed required todos overlay is being displayed
    @State private var showingRequiredCompletedTodos = false
    
    /// Whether the completed suggested todos overlay is being displayed
    @State private var showingSuggestedCompletedTodos = false
    
    /// Whether the focused todo view is being displayed
    @State private var showingFocusedTodo = false
    
    /// The currently selected todo for focused view
    @State private var focusedTodo: Todo? = nil
    
    /// The currently selected tab
    @State private var selectedTab = 0
    
    /// Access to the todo reset functionality
    @EnvironmentObject private var resetTodoManager: TodoResetManager
    
    /// Query for checking if there are any required todos
    @Query(filter: Todo.Predicates.byCategoryAndCompletion(category: .required, isCompleted: false),
           sort: [SortDescriptor(\Todo.order)]) private var requiredTodos: [Todo]
    
    /// Counter for badge display
    @State private var requiredTodoCount = 0
    @State private var suggestedTodoCount = 0
    
    // MARK: - Initialization
    
    /// Default empty initializer required for SwiftUI previews
    init() {
        // This empty initializer is needed for SwiftUI previews
        // We'll set up notification handlers in onAppear
    }
    
    // MARK: - Computed Properties
    
    /// Returns true if any overlay is currently being shown
    private var isAnyOverlayVisible: Bool {
        showingAddTodo || showingRequiredCompletedTodos ||
        showingSuggestedCompletedTodos || showingFocusedTodo
    }
    
    // MARK: - Setup Methods
    
    /// Configure the view when it first appears
    private func setupView() {
        setupNotificationHandlers()
        
        // Check if we have a pending todo ID from a notification
        checkForPendingNotificationTodo()
        
        // Check if we have a pending todo completion
        checkForPendingTodoCompletion()
        
        // Update todo counts
        updateTodoCounts()
    }
    
    /// Update the todo counts for badge display
    private func updateTodoCounts() {
        Task {
            do {
                requiredTodoCount = try modelContext.countIncompleteTodos(category: .required)
                suggestedTodoCount = try modelContext.countIncompleteTodos(category: .suggested)
            } catch {
                print("Error counting todos: \(error)")
            }
        }
    }
    
    /// Check for a pending todo completion from a notification
    private func checkForPendingTodoCompletion() {
        // Check if we have a pending todo completion
        if let todoId = UserDefaults.standard.string(forKey: "pendingTodoCompletion"),
           let timestamp = UserDefaults.standard.object(forKey: "pendingTodoCompletionTimestamp") as? Date {
            
            // Only use pending completions from the last 30 seconds
            if Date().timeIntervalSince(timestamp) < 30 {
                print("Found pending todo completion from notification: \(todoId)")
                
                // Try to find and complete the todo
                do {
                    if let todo = try self.modelContext.fetchTodoByUUID(todoId) {
                        print("Completing todo from pending notification: \(todo.title)")
                        todo.isCompleted = true
                        try modelContext.save()
                        updateTodoCounts()
                    } else {
                        print("Could not find todo with ID for completion: \(todoId)")
                    }
                } catch {
                    print("Error completing pending todo: \(error.localizedDescription)")
                }
            }
            
            // Clear the pending todo completion
            UserDefaults.standard.removeObject(forKey: "pendingTodoCompletion")
            UserDefaults.standard.removeObject(forKey: "pendingTodoCompletionTimestamp")
        }
    }
    
    /// Check for a pending todo ID from a notification and focus that todo
    private func checkForPendingNotificationTodo() {
        // Check if we have a pending todo ID stored
        if let todoId = UserDefaults.standard.string(forKey: "pendingTodoId"),
           let timestamp = UserDefaults.standard.object(forKey: "pendingTodoIdTimestamp") as? Date {
            
            // Only use pending todo IDs from the last 30 seconds
            if Date().timeIntervalSince(timestamp) < 30 {
                print("Found pending todo ID from notification: \(todoId)")
                
                // Try to find and focus the todo
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    do {
                        if let todo = try self.modelContext.fetchTodoByUUID(todoId) {
                            print("Focusing todo from notification: \(todo.title)")
                            self.focusedTodo = todo
                            self.showingFocusedTodo = true
                            
                            // Set the correct tab based on todo category
                            if todo.category == .required {
                                self.selectedTab = 0
                            } else {
                                self.selectedTab = 1
                            }
                            
                            // Clear the pending todo ID
                            UserDefaults.standard.removeObject(forKey: "pendingTodoId")
                            UserDefaults.standard.removeObject(forKey: "pendingTodoIdTimestamp")
                            return
                        } else {
                            print("Could not find todo with ID: \(todoId)")
                        }
                    } catch {
                        print("Error finding todo with ID \(todoId): \(error.localizedDescription)")
                    }
                    
                    // Fallback to showing the top required todo if the specific todo wasn't found
                    self.showDefaultFocusedTodo()
                }
            } else {
                // Timestamp is too old, clear pending data
                UserDefaults.standard.removeObject(forKey: "pendingTodoId")
                UserDefaults.standard.removeObject(forKey: "pendingTodoIdTimestamp")
            }
        }
    }
    
    /// Show the top required todo in focused view
    private func showDefaultFocusedTodo() {
        // Show focused todo view on app launch if there are required todos
        if !requiredTodos.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.focusedTodo = self.requiredTodos.first
                self.showingFocusedTodo = true
            }
        }
    }
    
    /// Register for notifications from iOS menu actions
    private func setupNotificationHandlers() {
        // Set up notification observers for menu bar actions and keyboard shortcuts
        
        // Show add todo sheet notification
        NotificationCenter.default.addObserver(
            forName: .showAddTodoSheet,
            object: nil,
            queue: .main
        ) { _ in
            self.showingAddTodo = true
        }
        
        // Show completed todos notification
        NotificationCenter.default.addObserver(
            forName: .showCompletedTodos,
            object: nil,
            queue: .main
        ) { _ in
            // Show both required and suggested completed todos based on current tab
            if self.selectedTab == 0 {
                self.showingRequiredCompletedTodos = true
            } else {
                self.showingSuggestedCompletedTodos = true
            }
        }
        
        // Reset todos notification
        NotificationCenter.default.addObserver(
            forName: .resetTodaysTodos,
            object: nil,
            queue: .main
        ) { _ in
            self.resetTodoManager.resetAllTodos()
            self.updateTodoCounts()
        }
        
        // Add notification for showing focused todo view
        NotificationCenter.default.addObserver(
            forName: .showFocusedTodo,
            object: nil,
            queue: .main
        ) { _ in
            if self.selectedTab == 0 {
                self.focusedTodo = self.requiredTodos.first
            } else {
                do {
                    let suggestedTodos = try self.modelContext.fetchIncompleteTodos(category: .suggested)
                    self.focusedTodo = suggestedTodos.first
                } catch {
                    print("Error fetching suggested todos: \(error)")
                }
            }
            self.showingFocusedTodo = true
        }
        
        // Add notification for showing a specific todo in focused view
        NotificationCenter.default.addObserver(
            forName: .showFocusedTodoWithId,
            object: nil,
            queue: .main
        ) { notification in
            guard let todoId = notification.userInfo?["todoId"] as? String else {
                print("No todoId found in notification userInfo")
                return
            }
            
            print("Received notification to focus todo with ID: \(todoId)")
            
            // Find the todo with the given UUID and show it in focused view
            do {
                if let todo = try self.modelContext.fetchTodoByUUID(todoId) {
                    print("Found todo for notification: \(todo.title)")
                    self.focusedTodo = todo
                    self.showingFocusedTodo = true
                    
                    // Set the correct tab based on todo category
                    if todo.category == .required {
                        self.selectedTab = 0
                    } else {
                        self.selectedTab = 1
                    }
                } else {
                    print("No todo found with UUID \(todoId)")
                }
            } catch {
                print("Error finding todo with UUID \(todoId): \(error.localizedDescription)")
            }
        }
        
        // Listen for model changes to update counts
        NotificationCenter.default.addObserver(
            forName: .todoCompletedExternally,
            object: nil,
            queue: .main
        ) { _ in
            self.updateTodoCounts()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("TodosResetNotification"),
            object: nil,
            queue: .main
        ) { _ in
            self.updateTodoCounts()
        }
    }
    
    // MARK: - View Body
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // MARK: Required Todos Tab
                VStack(spacing: 0) {
                    // Header for Required tab
                    HStack {
                        Text("Required")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.leading)
                        
                        Spacer()
                        
                        Button {
                            showingRequiredCompletedTodos = true
                        } label: {
                            Label("\(requiredTodoCount)", systemImage: "checkmark.circle")
                                .padding(8)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding(.trailing)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    
                    // Divider
                    Divider()
                    
                    // Required Todos List
                    TodoScrollView(category: .required) { todo in
                        self.focusedTodo = todo
                        self.showingFocusedTodo = true
                    }
                }
                .tabItem {
                    Label("Required", systemImage: "exclamationmark.circle")
                }
                .badge(requiredTodoCount > 0 ? requiredTodoCount : nil)
                .tag(0)
                
                // MARK: Suggested Todos Tab
                VStack(spacing: 0) {
                    // Header for Suggested tab
                    HStack {
                        Text("Suggested")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.leading)
                        
                        Spacer()
                        
                        Button {
                            showingSuggestedCompletedTodos = true
                        } label: {
                            Label("\(suggestedTodoCount)", systemImage: "checkmark.circle")
                                .padding(8)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding(.trailing)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    
                    // Divider
                    Divider()
                    
                    // Suggested Todos List
                    TodoScrollView(category: .suggested) { todo in
                        self.focusedTodo = todo
                        self.showingFocusedTodo = true
                    }
                }
                .tabItem {
                    Label("Suggested", systemImage: "lightbulb")
                }
                .badge(suggestedTodoCount > 0 ? suggestedTodoCount : nil)
                .tag(1)
                
                // MARK: Settings Tab
                NavigationView {
                    SettingsView()
                        .navigationTitle("Settings")
                }
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(selectedTab == 0 ? "Required" : (selectedTab == 1 ? "Suggested" : "Settings"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingAddTodo = true
                    } label: {
                        Label("Add Todo", systemImage: "plus.circle.fill")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            if let onTodoSelected = requiredTodos.first {
                                focusedTodo = onTodoSelected
                                showingFocusedTodo = true
                            }
                        }) {
                            Label("Focus on Top Todo", systemImage: "eye")
                        }
                        .disabled(requiredTodos.isEmpty)
                        
                        Button(action: {
                            resetTodoManager.resetAllTodos()
                            updateTodoCounts()
                        }) {
                            Label("Reset Today's Todos", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTodo) {
            AddTodoView(isPresented: $showingAddTodo)
                .onDisappear {
                    updateTodoCounts()
                }
        }
        .sheet(isPresented: $showingFocusedTodo) {
            if let todo = focusedTodo {
                FocusedTodoView(todo: todo, isPresented: $showingFocusedTodo)
                    .onDisappear {
                        updateTodoCounts()
                    }
            }
        }
        .sheet(isPresented: $showingRequiredCompletedTodos) {
            CompletedTodoView(category: .required, isPresented: $showingRequiredCompletedTodos)
                .onDisappear {
                    updateTodoCounts()
                }
        }
        .sheet(isPresented: $showingSuggestedCompletedTodos) {
            CompletedTodoView(category: .suggested, isPresented: $showingSuggestedCompletedTodos)
                .onDisappear {
                    updateTodoCounts()
                }
        }
        .onAppear {
            setupView()
        }
        .onChange(of: selectedTab) { _, _ in
            // Update the counts when changing tabs
            updateTodoCounts()
        }
    }
}

// MARK: - Previews

#Preview("Light Mode") {
    iOSMainView()
        .preferredColorScheme(.light)
        .modelContainer(TodoMockData.createPreviewContainer())
        .environmentObject(SettingsManager())
        .environmentObject(TodoResetManager(modelContext: ModelContext(TodoMockData.createPreviewContainer())))
}

#Preview("Dark Mode") {
    iOSMainView()
        .preferredColorScheme(.dark)
        .modelContainer(TodoMockData.createPreviewContainer())
        .environmentObject(SettingsManager())
        .environmentObject(TodoResetManager(modelContext: ModelContext(TodoMockData.createPreviewContainer())))
}