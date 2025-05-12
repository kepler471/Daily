//
//  TodoStackView.swift
//  Daily
//
//  Created by Stelios Georgiou on 07/05/2025.
//

import SwiftUI
import SwiftData
import UserNotifications

// MARK: - TodoStackView

/// A view that displays todos in a visually pleasing, overlapping stack
///
/// TodoStackView provides a highly interactive todo display with:
/// - Stacked card layout with configurable spacing and scaling
/// - Hover interactions to fan out cards for easier selection
/// - Custom animations for todo completion and card repositioning
/// - Support for multiple layout styles through different initialization options
struct TodoStackView: View {
    // MARK: - Properties
    
    /// Database context for saving todo changes
    @Environment(\.modelContext) private var modelContext

    /// Settings manager for notification preferences
    @EnvironmentObject private var settingsManager: SettingsManager

    /// Query for retrieving todos from the database
    @Query private var todos: [Todo]
    
    /// Currently hovered todo index for interactive effects
    @State private var hoveredTodoIndex: Int? = nil
    
    /// Whether the stack is in selection mode (fanned out)
    @State private var isSelectionModeActive: Bool = false
    
    /// Constant vertical offset between cards in the stack
    var verticalOffset: CGFloat
    
    /// Optional function that calculates vertical offset based on index
    var offsetByIndex: ((Int) -> CGFloat)?
    
    /// Optional function that calculates scale factor based on index
    var scaleByIndex: ((Int) -> CGFloat)?
    
    /// Scale factor for cards in the stack (1.0 = no scaling)
    var scaleAmount: CGFloat
    
    /// Optional category filter for the todos
    var category: TodoCategory?

    /// Callback when a todo is selected for focused view
    var onTodoSelected: ((Todo) -> Void)? = nil

    /// Set of todos that should be visually removed due to completion
    @State private var todosToRemove: Set<ObjectIdentifier> = []

    /// Store completed todos temporarily for animation purposes
    @State private var animatingTodos: [Todo] = []

    /// Whether the stack is currently animating repositioning
    @State private var isRepositioning: Bool = false
    
    // MARK: - Initialization
    
    /// Initialize with a constant vertical offset and optional scale
    /// - Parameters:
    ///   - category: Optional category to filter todos by
    ///   - verticalOffset: Constant spacing between cards in the stack
    ///   - scale: Scale factor for cards in the stack (1.0 = no scaling)
    ///   - onTodoSelected: Optional callback when a todo is selected
    init(category: TodoCategory? = nil, verticalOffset: CGFloat = 20, scale: CGFloat = 1.0, onTodoSelected: ((Todo) -> Void)? = nil) {
        self.verticalOffset = verticalOffset
        self.offsetByIndex = nil
        self.scaleByIndex = nil
        self.scaleAmount = scale
        self.category = category
        self.onTodoSelected = onTodoSelected
        
        // Use a combined predicate to get only incomplete todos for this category
        if let category = category {
            _todos = Query(
                filter: Todo.Predicates.byCategoryAndCompletion(category: category, isCompleted: false),
                sort: [
                    SortDescriptor(\Todo.order, order: .forward),
                    SortDescriptor(\Todo.createdAt, order: .forward)
                ]
            )
        } else {
            _todos = Query(
                filter: Todo.Predicates.byCompletion(isCompleted: false),
                sort: [
                    SortDescriptor(\Todo.order, order: .forward),
                    SortDescriptor(\Todo.createdAt, order: .forward)
                ]
            )
        }
    }
    
    /// Initialize with a function mapping index to offset and optional scale
    /// - Parameters:
    ///   - category: Optional category to filter todos by
    ///   - offsetByIndex: Function that calculates vertical offset based on card index
    ///   - scale: Scale factor for cards in the stack (1.0 = no scaling)
    ///   - onTodoSelected: Optional callback when a todo is selected
    init(category: TodoCategory? = nil, offsetByIndex: @escaping (Int) -> CGFloat, scale: CGFloat = 1.0, onTodoSelected: ((Todo) -> Void)? = nil) {
        self.verticalOffset = 0 // Not used in this initialization
        self.offsetByIndex = offsetByIndex
        self.scaleByIndex = nil
        self.scaleAmount = scale
        self.category = category
        self.onTodoSelected = onTodoSelected
        
        // Use a combined predicate to get only incomplete todos for this category
        if let category = category {
            _todos = Query(
                filter: Todo.Predicates.byCategoryAndCompletion(category: category, isCompleted: false),
                sort: [
                    SortDescriptor(\Todo.order, order: .forward),
                    SortDescriptor(\Todo.createdAt, order: .forward)
                ]
            )
        } else {
            _todos = Query(
                filter: Todo.Predicates.byCompletion(isCompleted: false),
                sort: [
                    SortDescriptor(\Todo.order, order: .forward),
                    SortDescriptor(\Todo.createdAt, order: .forward)
                ]
            )
        }
    }
    
    /// Initialize with functions for both offset and scale
    /// - Parameters:
    ///   - category: Optional category to filter todos by
    ///   - offsetByIndex: Function that calculates vertical offset based on card index
    ///   - scaleByIndex: Function that calculates scale factor based on card index
    ///   - onTodoSelected: Optional callback when a todo is selected
    init(category: TodoCategory? = .required, offsetByIndex: @escaping (Int) -> CGFloat, scaleByIndex: @escaping (Int) -> CGFloat, onTodoSelected: ((Todo) -> Void)? = nil) {
        self.verticalOffset = 0 // Not used in this initialization
        self.offsetByIndex = offsetByIndex
        self.scaleByIndex = scaleByIndex
        self.scaleAmount = 1.0 // Not used in this initialization
        self.category = category
        self.onTodoSelected = onTodoSelected
        
        // Use a combined predicate to get only incomplete todos for this category
        if let category = category {
            _todos = Query(
                filter: Todo.Predicates.byCategoryAndCompletion(category: category, isCompleted: false),
                sort: [
                    SortDescriptor(\Todo.order, order: .forward),
                    SortDescriptor(\Todo.createdAt, order: .forward)
                ]
            )
        } else {
            _todos = Query(
                filter: Todo.Predicates.byCompletion(isCompleted: false),
                sort: [
                    SortDescriptor(\Todo.order, order: .forward),
                    SortDescriptor(\Todo.createdAt, order: .forward)
                ]
            )
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        // Stack layout with cards
        ZStack {
            // First show regular todos (filtered to show only incomplete ones)
            let filteredTodos = todos.filter { todo in
                return !todo.isCompleted
            }

            ForEach(Array(filteredTodos.enumerated()), id: \.element.id) { index, todo in
                // Only show todos that aren't marked for removal
                if !todosToRemove.contains(ObjectIdentifier(todo)) {
                    todoCardView(for: todo, at: index)
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("\(todo.title), todo \(index + 1) of \(filteredTodos.count)")
                        .accessibilityHint("Hover to fan out all todos, tap to view details, or click complete button")
                        .onTapGesture {
                            if let onTodoSelected = onTodoSelected {
                                onTodoSelected(todo)
                            }
                        }
                }
            }

            // Then show the animating todos (ones that are completing)
            ForEach(animatingTodos, id: \.id) { todo in
                // Use the same position as the original todo (stored in todo.order)
                let originalPosition = min(Int(todo.order), filteredTodos.count)

                todoCardView(for: todo, at: originalPosition)
                    .transition(
                        AnyTransition.asymmetric(
                            insertion: .identity, // No insertion animation - we want it to stay in place
                            removal: AnyTransition.opacity
                                .combined(with: .offset(x: 250, y: -250))
                                .combined(with: .scale(scale: 0.2))
                                .animation(.easeOut(duration: 1.0))
                        )
                    )
                    .zIndex(1000) // Keep the animating todo on top during animation
            }
        }
        .padding()
        // This animation helps with the overall stack repositioning
        .animation(isRepositioning ? .spring(response: 0.7, dampingFraction: 0.7) : nil, value: todos.count)
        .onChange(of: todos) { oldValue, newValue in
            // Reset the removal tracking when todos change
            // This ensures we don't accidentally hide new todos
            todosToRemove.removeAll()
        }
        // Add another onChange handler specifically for todo completion status
        .onChange(of: todos.map(\.isCompleted)) { oldValue, newValue in
            // Clear todosToRemove when completion status changes from an external source
            if oldValue != newValue {
                todosToRemove.removeAll()
            }
        }
        // Print current todos for debugging
        .onAppear {
            print("📋 TodoStackView for category \(category?.rawValue ?? "all") initialized with \(todos.count) todos")
            for todo in todos {
                print("  - \(todo.title) (UUID: \(todo.uuid.uuidString), Completed: \(todo.isCompleted))")
            }
        }
        // Listen for todo reset notifications
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TodosResetNotification"))) { _ in
            // When todos are reset, clear the removal tracking
            withAnimation {
                todosToRemove.removeAll()
            }
        }
        // Listen for external todo completion notifications
        .onReceive(NotificationCenter.default.publisher(for: .todoCompletedExternally)) { notification in
            // Extract the completed todo ID and category from the notification
            print("🔔 TodoStackView for category \(category?.rawValue ?? "all"): Received todoCompletedExternally notification")

            let completedTodoId = notification.userInfo?["completedTodoId"] as? String
            let todoCategoryStr = notification.userInfo?["category"] as? String
            let todoCategory = todoCategoryStr.flatMap { TodoCategory(rawValue: $0) }

            print("🔔 TodoStackView: Notification details - todoId: \(completedTodoId ?? "nil"), category: \(todoCategoryStr ?? "nil")")

            // First check if this is a category-specific notification
            if let completedTodoId = completedTodoId,
               let todoCategory = todoCategory {

                // Only handle the notification if this stack is for the todo's category
                if todoCategory == category || category == nil {
                    print("✅ TodoStackView: Handling notification for matching category: \(todoCategory.rawValue)")

                    // Print current todos for comparison
                    print("📋 Current todos in this stack:")
                    for todo in todos {
                        print("  - \(todo.title) (UUID: \(todo.uuid.uuidString), Completed: \(todo.isCompleted))")
                    }

                    handleExternalTodoCompletion(todoId: completedTodoId)
                } else {
                    print("⚠️ TodoStackView: Ignoring notification for category \(todoCategory.rawValue) (this stack is for \(category?.rawValue ?? "all"))")
                }
            }
            // Fallback for backward compatibility
            else if let completedTodoId = completedTodoId {
                print("🔔 TodoStackView: Handling notification without category info")

                // Print current todos for comparison
                print("📋 Current todos in this stack:")
                for todo in todos {
                    print("  - \(todo.title) (UUID: \(todo.uuid.uuidString), Completed: \(todo.isCompleted))")
                }

                handleExternalTodoCompletion(todoId: completedTodoId)
            } else {
                print("❌ TodoStackView: Missing completedTodoId in notification userInfo")
                print("Available keys: \(notification.userInfo?.keys.map { $0 as? String } ?? [])")
            }
        }
    }
    
    // MARK: - Card View Builder
    
    /// Creates a todo card view with animations and transitions
    /// - Parameters:
    ///   - todo: The todo to display
    ///   - index: The index of the todo in the stack
    /// - Returns: A configured TodoCardView with animations and effects
    private func todoCardView(for todo: Todo, at index: Int) -> some View {
        
        // MARK: - Animation Setup
        
        // Setup the transition for removal animation
        let insertionTransition = AnyTransition.opacity.combined(with: .scale)
        
        // Create a custom opacity effect that fades out more slowly
        let slowOpacity = AnyTransition.opacity.animation(.easeOut(duration: 1.0))
        
        // Create the removal transition in stages to avoid complex expressions
        let removalStep1 = slowOpacity.combined(with: .offset(x: 250, y: CGFloat(-index * 50) - 250))
        let removalStep2 = removalStep1.combined(with: .scale(scale: 0.2))
        let removalTransition = removalStep2
        
        // The complete transition combines both insertion and removal transitions
        let todoTransition = AnyTransition.asymmetric(
            insertion: insertionTransition,
            removal: removalTransition
        )
        
        // Calculate the vertical offset based on selection mode
        let verticalOffset = isSelectionModeActive ? 
            calculateExpandedOffset(for: index) : 
            calculateYOffset(for: index)
            
        return TodoView(todo: todo) {
            // Handle todo completion toggle
            let newCompletionState = !todo.isCompleted
            
            // Start animation first, then update model
            if newCompletionState {
                // For completion animation, insert into removal set before updating model
                // This preserves the animation even if the model refreshes
                _ = withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                    todosToRemove.insert(ObjectIdentifier(todo))
                }
                
                // Prepare for smooth repositioning of other todos
                // Delay repositioning slightly to allow the todo to start its completion animation first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    // Enable repositioning animation
                    withAnimation {
                        isRepositioning = true
                    }
                    
                    // Delay the actual model update slightly to allow animation to start
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // Now update the model
                        todo.isCompleted = newCompletionState
                        
                        // Try to save the changes
                        do {
                            try modelContext.save()

                            // Cancel notification for completed todo
                            Task {
                                await todo.cancelNotification()
                            }
                        } catch {
                            print("Error saving todo completion state: \(error.localizedDescription)")
                        }
                        
                        // After the todo has been completed and saved, we can reset the repositioning flag
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            isRepositioning = false
                        }
                    }
                }
            } else {
                // For reopening, update model immediately
                todo.isCompleted = newCompletionState
                todosToRemove.remove(ObjectIdentifier(todo))

                // Try to save the changes
                do {
                    try modelContext.save()

                    // Reschedule notification for reopened todo
                    if todo.scheduledTime != nil {
                        Task {
                            await todo.scheduleNotification(settings: settingsManager)
                        }
                    }
                } catch {
                    print("Error saving todo completion state: \(error.localizedDescription)")
                }
            }
        }
        // Apply positioning and visual effects
        .offset(y: verticalOffset)
        .scaleEffect(calculateScale(for: index))
        .rotation3DEffect(
            todo.isCompleted ? .degrees(10) : .degrees(0),
            axis: (x: 1.0, y: 0.2, z: 0.0)
        )
        .zIndex(calculateZIndex(for: index))
        .onHover { isHovered in
            handleHover(isHovered: isHovered, at: index)
        }
        .transition(todoTransition)
        // Animation for hover effects
        .animation(.easeOut(duration: 0.2), value: hoveredTodoIndex)
        // Animation for completion state changes
        .animation(.easeOut(duration: 0.7), value: todo.isCompleted)
        // Animation for repositioning
        .animation(isRepositioning ? 
                  .spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.3) : 
                  nil, 
                  value: index)
    }
    
    // MARK: - Hover Handling
    
    /// Handles mouse hover interactions to trigger fan-out effect
    /// - Parameters:
    ///   - isHovered: Whether the card is currently being hovered
    ///   - index: The index of the card being hovered
    private func handleHover(isHovered: Bool, at index: Int) {
        if isHovered {
            // Card is being hovered over
            hoveredTodoIndex = index
            
            // Activate selection mode when any card is hovered
            if !isSelectionModeActive {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isSelectionModeActive = true
                }
            }
        } else if hoveredTodoIndex == index {
            // Card is no longer being hovered
            hoveredTodoIndex = nil
            
            // Keep selection mode active for a shorter time to allow moving to another card
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                if hoveredTodoIndex == nil {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isSelectionModeActive = false
                    }
                }
            }
        }
    }
    
    // MARK: - Layout Calculations
    
    /// Calculate the Y offset for a card at the given index
    /// - Parameter index: The index of the card in the stack
    /// - Returns: The vertical offset to apply to the card
    private func calculateYOffset(for index: Int) -> CGFloat {
        if let offsetByIndex = offsetByIndex {
            // Use the offset function if provided
            return offsetByIndex(index)
        } else {
            // Use the constant offset multiplied by index
            return verticalOffset * CGFloat(index)
        }
    }
    
    // MARK: - Scaling
    
    /// Calculate the scale for a card at the given index
    /// - Parameter index: The index of the card in the stack
    /// - Returns: The scale factor to apply to the card
    private func calculateScale(for index: Int) -> CGFloat {
        // When cards are fanned out in selection mode, apply distance-based scaling
        if isSelectionModeActive {
            // The hovered card remains at full scale
            if hoveredTodoIndex == index {
                return 1.0
            }
            
            // If no card is hovered, use the middle of the stack as reference
            // For odd-numbered collections, this will be the exact middle
            // For even-numbered collections, it will be just below the middle
            let referenceIndex = hoveredTodoIndex ?? Int(floor(Double(todos.count - 1) / 2.0))
            
            // Calculate distance from the hovered/reference card
            let distance = abs(index - referenceIndex)
            
            // Scale down based on distance from hovered card
            // The further away, the smaller the scale
            let minScale: CGFloat = 0.8
            let scaleReduction: CGFloat = 0.05 * min(CGFloat(distance), 3.0)
            
            return max(1.0 - scaleReduction, minScale)
        } 
        // For normal stacked mode, use the provided scaling function or default scaling
        else if let scaleByIndex = scaleByIndex {
            // Use the scaling function if provided
            return scaleByIndex(index)
        } else {
            // Apply linear scaling based on index and scale amount
            // The formula ensures that the first card (index 0) has scale 1.0,
            // and each subsequent card is scaled down by a factor proportional to scaleAmount
            let baseScale = 1.0
            let scaleFactor = scaleAmount
            let numberOfCards = CGFloat(todos.count)
            
            // No scaling if scale amount is 1.0
            if scaleFactor == 1.0 {
                return 1.0
            }
            
            // Otherwise, scale down for deeper cards in the stack
            // Ensure we don't scale below 0.5
            return max(baseScale - (baseScale - scaleFactor) * CGFloat(index) / max(1, numberOfCards - 1), 0.5)
        }
    }
    
    // MARK: - Fan-out Layout
    
    /// Calculate an expanded vertical offset for fan-out view in selection mode
    /// - Parameter index: The index of the card in the stack
    /// - Returns: The vertical offset to apply in fan-out mode
    private func calculateExpandedOffset(for index: Int) -> CGFloat {
        let totalCards = todos.count
        
        // Fixed spacing between cards in fan-out mode
        let cardSpacing: CGFloat = 70.0
        
        // Calculate position in fan-out mode based on index only
        // This creates stable positions regardless of which card is hovered
        let normalizedPosition = CGFloat(index) / CGFloat(max(1, totalCards - 1))
        
        // Map to a range from -1.0 to 1.0 (centered around 0.5)
        // This makes the middle card at y=0, with cards above going negative and below going positive
        let positionFactor = (normalizedPosition - 0.5) * 2.0
        
        // Calculate total height of the fan and center it
        let fanHeight = cardSpacing * CGFloat(totalCards - 1)
        
        // Adjust positions to ensure proper overlap and hover detection
        let middleIndex = Int(floor(Double(todos.count - 1) / 2.0))
        let isOddCount = todos.count % 2 != 0
        
        var basePosition = positionFactor * (fanHeight / 2.0)
        
        // For odd counts, create a larger gap around the middle card
        if isOddCount {
            if index == middleIndex {
                // Middle card gets a slight vertical adjustment
                basePosition += 5.0
            } else if index > middleIndex {
                // Cards below the middle get pushed down slightly more
                basePosition += 10.0
            }
        }
        
        // Apply a small offset for the hovered card to make it stand out
        let hoverBonus: CGFloat = (hoveredTodoIndex == index) ? -10 : 0
        
        return basePosition + hoverBonus
    }
    
    // MARK: - External Completion Handling

    /// Handles a todo completion that happened outside the TodoStackView (notification or focused view)
    /// - Parameter todoId: The UUID string of the completed todo
    private func handleExternalTodoCompletion(todoId: String) {
        print("🔍 Searching for todo with UUID: \(todoId) to animate completion")

        // Step 1: Try the modelContext directly to find the todo, even if it's completed
        do {
            // Create a fetch descriptor that includes completed todos
            let fetchDescriptor = FetchDescriptor<Todo>()

            // Fetch all todos
            let allTodos = try modelContext.fetch(fetchDescriptor)

            // Find the todo with matching UUID
            if let completedTodo = allTodos.first(where: { $0.uuid.uuidString == todoId }) {
                print("✅ Found todo in database: \(completedTodo.title)")

                // Only animate if it belongs to this category
                if completedTodo.category == category || category == nil {
                    print("🎬 Starting animation for todo: \(completedTodo.title)")

                    // First find if the todo is in the current visible todos array
                    // to preserve its original position and avoid the jump effect
                    let todoIndex = self.todos.firstIndex(where: { $0.uuid.uuidString == todoId }) ?? 0
                    print("📊 Original todo index: \(todoIndex)")

                    // Add to the animating todos array without animation
                    // This will make it appear in place without moving
                    self.animatingTodos.append(completedTodo)

                    // Then after a short delay, remove it with animation
                    // This delay ensures the todo appears to stay in place initially
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeOut(duration: 1.0)) {
                            // Remove it from the array (triggers removal animation)
                            self.animatingTodos.removeAll(where: { $0.id == completedTodo.id })
                        }

                        // Enable repositioning animation for the stack
                        withAnimation {
                            print("🔄 Enabling repositioning")
                            self.isRepositioning = true
                        }

                        // After animation completes, reset the repositioning flag
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            print("🔄 Disabling repositioning")
                            self.isRepositioning = false
                        }
                    }

                    return
                } else {
                    print("⚠️ Todo found but belongs to different category - this stack is for \(category?.rawValue ?? "all categories")")
                }
            }
        } catch {
            print("❌ Error fetching todos: \(error.localizedDescription)")
        }

        // If we get here, try the regular approach as a fallback
        print("⚠️ Trying fallback method with todo array")

        // Find the todo in our todos array
        if let todoIndex = todos.firstIndex(where: { $0.uuid.uuidString == todoId }) {
            let todo = todos[todoIndex]
            print("✅ Found todo at index \(todoIndex): \(todo.title)")

            // Ensure the todo isn't already in the removal set
            if !todosToRemove.contains(ObjectIdentifier(todo)) {
                print("🎬 Animating external completion for todo: \(todo.title)")

                // Start the completion animation on the main thread
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                        print("➕ Adding todo to todosToRemove set")
                        self.todosToRemove.insert(ObjectIdentifier(todo))
                    }

                    // Enable repositioning animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        // Enable repositioning animation
                        withAnimation {
                            print("🔄 Enabling repositioning")
                            self.isRepositioning = true
                        }

                        // After animation completes, reset the repositioning flag
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            print("🔄 Disabling repositioning")
                            self.isRepositioning = false
                        }
                    }
                }
            } else {
                print("⚠️ Todo already in removal set, skipping animation")
            }
        } else {
            print("❌ Could not find todo with ID: \(todoId) in this TodoStackView")
            print("❓ Is this the correct TodoStackView for this todo's category?")
        }
    }

    // MARK: - Z-index Calculation

    /// Calculate the z-index for a card, taking into account hover state
    /// - Parameter index: The index of the card in the stack
    /// - Returns: The z-index value to determine visual stacking order
    private func calculateZIndex(for index: Int) -> Double {
        // Default stacking: top card has highest z-index
        let baseZIndex = Double(todos.count - index)
        
        // Standard stacking when not in selection mode or no todo is hovered
        if !isSelectionModeActive || hoveredTodoIndex == nil {
            return baseZIndex
        }
        
        // When in selection mode with a hovered todo
        if hoveredTodoIndex == index {
            // Hovered todo gets highest z-index
            return 10.0 
        } else {
            // All other todos get z-index based on distance from hovered todo
            let distance = abs(index - (hoveredTodoIndex ?? 0))
            return 10.0 - Double(distance)
        }
    }
}

// MARK: - Previews

#Preview("Scalar") {
    TabView {
        TodoStackView(
            category: .required,
            verticalOffset: 20)
            .frame(height: 600)
            .padding()
            .modelContainer(TodoMockData.createPreviewContainer())
            .environmentObject(SettingsManager())
            .tabItem {
                Label("Required", systemImage: "checklist")
            }
            .tag(0)

        TodoStackView(
            category: .suggested,
            verticalOffset: 20)
            .frame(height: 600)
            .padding()
            .modelContainer(TodoMockData.createPreviewContainer())
            .environmentObject(SettingsManager())
            .tabItem {
                Label("Suggested", systemImage: "checklist")
            }
            .tag(1)
    }
}

#Preview("Log") {
    TodoStackView(
        category: nil,
        offsetByIndex: { i in
            return CGFloat(60 * pow(0.2 * Double(i), 0.5))
        }
    )
        .frame(height: 600)
        .padding()
        .modelContainer(TodoMockData.createPreviewContainer())
}

#Preview("With Scale") {
    TodoStackView(category: .required, verticalOffset: 20, scale: 0.85)
        .frame(height: 600)
        .padding()
        .modelContainer(TodoMockData.createPreviewContainer())
}

#Preview("Log with Scale") {
    TodoStackView(
        category: .required,
        offsetByIndex: { i in
            return CGFloat(60 * pow(0.2 * Double(i), 0.5))
        },
        scaleByIndex: { i in
            // Scale from 1.0 down to 0.7 based on index
            return 1.0 - CGFloat(i) * 0.05
        }
    )
    .frame(height: 600)
    .padding()
    .modelContainer(TodoMockData.createPreviewContainer())
}

#Preview("Hover Effects") {
    VStack {
        Text("Hover over any card to fan out the stack")
            .font(.headline)
            .padding(.bottom)
        
        Text("Cards fan out non-linearly from the hovered card")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.bottom)
        
        TodoStackView(
            category: .required,
            offsetByIndex: { i in
                return CGFloat(30 * i)
            },
            scale: 0.9
        )
        .frame(height: 600)
    }
    .padding()
    .modelContainer(TodoMockData.createPreviewContainer())
}

#Preview("Interactive") {
    TodoStackAdjustablePreview()
        .modelContainer(TodoMockData.createPreviewContainer())
}

/// An interactive preview wrapper for TodoStackView that allows real-time adjustment with sliders
struct TodoStackAdjustablePreview: View {
    // Slider parameters
    @State private var baseValue: Double = 40
    @State private var exponent: Double = 0.7
    @State private var offset: Double = 2
    @State private var formula: OffsetFormula = .exponential
    
    // Scale parameters
    @State private var useScale: Bool = false
    @State private var scaleValue: Double = 0.85
    @State private var useCustomScale: Bool = false
    @State private var scaleMin: Double = 0.7
    
    enum OffsetFormula: String, CaseIterable, Identifiable {
        case linear = "Linear"
        case exponential = "Exponential"
        case logarithmic = "Logarithmic"
        case squareRoot = "Square Root"
        case power = "Power Function"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Formula picker - Top section
            VStack {
                Text("Stack Formula")
                    .font(.headline)
                    .padding(.top, 8)
                
                Picker("Formula", selection: $formula) {
                    ForEach(OffsetFormula.allCases) { formula in
                        Text(formula.rawValue).tag(formula)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
            .background(Color.secondary.opacity(0.05))
            
            // Parameter sliders - Middle section with fixed height
            VStack {
                // Offset parameters
                VStack(spacing: 12) {
                    // Always visible base value slider
                    HStack {
                        Text("Offset Base:")
                            .frame(width: 100, alignment: .leading)
                        
                        Text("\(baseValue, specifier: "%.1f")")
                            .frame(width: 50)
                        
                        Slider(value: $baseValue, in: 10...100, step: 1)
                    }
                    
                    // Formula-specific parameters
                    if formula != .linear {
                        HStack {
                            Text("\(formulaExponentLabel):")
                                .frame(width: 100, alignment: .leading)
                            
                            Text("\(exponent, specifier: "%.2f")")
                                .frame(width: 50)
                            
                            Slider(value: $exponent, in: getExponentRange().0...getExponentRange().1, step: 0.01)
                        }
                    }
                    
                    if formula == .logarithmic || formula == .squareRoot {
                        HStack {
                            Text("Offset:")
                                .frame(width: 100, alignment: .leading)
                            
                            Text("\(offset, specifier: "%.1f")")
                                .frame(width: 50)
                            
                            Slider(value: $offset, in: 1...20, step: 0.5)
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, 6)
                
                // Scale parameters
                VStack(spacing: 10) {
                    Toggle("Enable Scaling", isOn: $useScale)
                        .padding(.horizontal)
                    
                    if useScale {
                        Toggle("Custom Scale Function", isOn: $useCustomScale)
                            .padding(.horizontal)
                        
                        if useCustomScale {
                            HStack {
                                Text("Min Scale:")
                                    .frame(width: 100, alignment: .leading)
                                
                                Text("\(scaleMin, specifier: "%.2f")")
                                    .frame(width: 50)
                                
                                Slider(value: $scaleMin, in: 0.5...0.95, step: 0.01)
                            }
                        } else {
                            HStack {
                                Text("Scale Factor:")
                                    .frame(width: 100, alignment: .leading)
                                
                                Text("\(scaleValue, specifier: "%.2f")")
                                    .frame(width: 50)
                                
                                Slider(value: $scaleValue, in: 0.7...0.98, step: 0.01)
                            }
                        }
                    }
                }
            }
            .frame(height: 190) // Fixed height for the controls section
            .padding(.horizontal)
            
            // Code representation - Bottom section
            VStack {
                Text("Generated Code")
                    .font(.subheadline)
                    .padding(.top, 8)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                    
                    Text(generateCodeText())
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                }
                .frame(height: 80)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(Color.secondary.opacity(0.05))
            
            Divider()
            
            // TodoStackView with dynamic parameters
            if useScale {
                if useCustomScale {
                    TodoStackView(
                        category: .required,
                        offsetByIndex: offsetFunction,
                        scaleByIndex: customScaleFunction
                    )
                    .frame(minHeight: 380)
                } else {
                    TodoStackView(
                        category: .required,
                        offsetByIndex: offsetFunction,
                        scale: CGFloat(scaleValue)
                    )
                    .frame(minHeight: 380)
                }
            } else {
                TodoStackView(
                    category: .required,
                    offsetByIndex: offsetFunction
                )
                .frame(minHeight: 380)
            }
        }
        .padding(.vertical)
    }
    
    // Generate the offset function based on selected formula and parameters
    private var offsetFunction: (Int) -> CGFloat {
        return { index in
            switch self.formula {
            case .linear:
                return -self.baseValue * CGFloat(index)
                
            case .exponential:
                return -self.baseValue * pow(CGFloat(self.exponent), CGFloat(index))
                
            case .logarithmic:
                return -self.baseValue * (log2(CGFloat(index) + CGFloat(self.offset)) - log2(CGFloat(index) + 1))
                
            case .squareRoot:
                return -self.baseValue * (sqrt(CGFloat(index) + CGFloat(self.offset)) - sqrt(CGFloat(index)))
                
            case .power:
                return -self.baseValue / pow(CGFloat(index) + CGFloat(self.exponent), CGFloat(self.exponent))
            }
        }
    }
    
    // Generate a custom scale function that scales cards from 1.0 to min scale
    private var customScaleFunction: (Int) -> CGFloat {
        return { index in
            // Linear scaling from 1.0 down to minimum scale
            return max(1.0 - CGFloat(index) * 0.05, CGFloat(self.scaleMin))
        }
    }
    
    // Get the appropriate exponent range based on formula
    private func getExponentRange() -> (Double, Double) {
        switch formula {
        case .exponential: return (0.5, 0.99)
        case .power: return (0.5, 2.0)
        case .logarithmic: return (1.1, 3.0)
        case .squareRoot: return (0.1, 1.0)
        default: return (0.5, 1.0)
        }
    }
    
    // Get the exponent label based on the formula
    private var formulaExponentLabel: String {
        switch formula {
        case .exponential: return "Base"
        case .power: return "Power"
        case .logarithmic: return "Log Factor"
        case .squareRoot: return "Root Factor"
        default: return "Factor"
        }
    }
    
    // Generate the full code representation based on current settings
    private func generateCodeText() -> String {
        var code = "TodoStackView(\n"
        
        // Add category
        code += "    category: .required,\n"
        
        // Add offset function
        code += "    offsetByIndex: \(getOffsetFunctionText())"
        
        // Add scale if enabled
        if useScale {
            if useCustomScale {
                code += ",\n    scaleByIndex: \(getScaleFunctionText())"
            } else {
                code += ",\n    scale: \(String(format: "%.2f", scaleValue))"
            }
        }
        
        code += "\n)"
        return code
    }
    
    // Get the offset function code representation
    private func getOffsetFunctionText() -> String {
        switch formula {
        case .linear:
            return "{ index in -\(String(format: "%.1f", baseValue)) * CGFloat(index) }"
            
        case .exponential:
            return "{ index in -\(String(format: "%.1f", baseValue)) * pow(\(String(format: "%.2f", exponent)), CGFloat(index)) }"
            
        case .logarithmic:
            return "{ index in -\(String(format: "%.1f", baseValue)) * (log2(CGFloat(index) + \(String(format: "%.1f", offset))) - log2(CGFloat(index) + 1)) }"
            
        case .squareRoot:
            return "{ index in -\(String(format: "%.1f", baseValue)) * (sqrt(CGFloat(index) + \(String(format: "%.1f", offset))) - sqrt(CGFloat(index))) }"
            
        case .power:
            return "{ index in -\(String(format: "%.1f", baseValue)) / pow(CGFloat(index) + \(String(format: "%.2f", exponent)), \(String(format: "%.2f", exponent))) }"
        }
    }
    
    // Get the scale function code representation
    private func getScaleFunctionText() -> String {
        return "{ index in max(1.0 - CGFloat(index) * 0.05, \(String(format: "%.2f", scaleMin))) }"
    }
}
