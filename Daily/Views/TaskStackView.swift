//
//  TaskStackView.swift
//  Daily
//
//  Created using Claude Code.
//

import SwiftUI
import SwiftData

// MARK: - TaskStackView
struct TaskStackView: View {
    // Data source
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    
    // State for hover effects
    @State private var hoveredTaskIndex: Int? = nil
    @State private var isSelectionModeActive: Bool = false
    
    // Stack configuration
    var verticalOffset: CGFloat
    var offsetByIndex: ((Int) -> CGFloat)?
    var scaleByIndex: ((Int) -> CGFloat)?
    var scaleAmount: CGFloat
    var category: TaskCategory?
    
    /// Initialize with a constant vertical offset and optional scale
    init(category: TaskCategory? = nil, verticalOffset: CGFloat = 20, scale: CGFloat = 1.0) {
        self.verticalOffset = verticalOffset
        self.offsetByIndex = nil
        self.scaleByIndex = nil
        self.scaleAmount = scale
        self.category = category
        
        _tasks = Query(
            filter: Task.Predicates.byCategory(category),
            sort: [
                SortDescriptor(\Task.order, order: .forward),
                SortDescriptor(\Task.createdAt, order: .forward)
            ]
        )
    }
    
    /// Initialize with a function mapping index to offset and optional scale
    init(category: TaskCategory? = nil, offsetByIndex: @escaping (Int) -> CGFloat, scale: CGFloat = 1.0) {
        self.verticalOffset = 0 // Not used in this initialization
        self.offsetByIndex = offsetByIndex
        self.scaleByIndex = nil
        self.scaleAmount = scale
        self.category = category
        
        _tasks = Query(
            filter: Task.Predicates.byCategory(category),
            sort: [
                SortDescriptor(\Task.order, order: .forward),
                SortDescriptor(\Task.createdAt, order: .forward)
            ]
        )
    }
    
    /// Initialize with functions for both offset and scale
    init(category: TaskCategory? = .required, offsetByIndex: @escaping (Int) -> CGFloat, scaleByIndex: @escaping (Int) -> CGFloat) {
        self.verticalOffset = 0 // Not used in this initialization
        self.offsetByIndex = offsetByIndex
        self.scaleByIndex = scaleByIndex
        self.scaleAmount = 1.0 // Not used in this initialization
        self.category = category
        
        _tasks = Query(
            filter: Task.Predicates.byCategory(category),
            sort: [
                SortDescriptor(\Task.order, order: .forward),
                SortDescriptor(\Task.createdAt, order: .forward)
            ]
        )
    }
    
    // Track tasks that should be removed after completion
    @State private var tasksToRemove: Set<ObjectIdentifier> = []
    
    // MARK: - ZStack
    var body: some View {
        // Reset the removed tasks when tasks change
        // This ensures consistency when tasks are modified outside this view
        ZStack {
            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                // Only show tasks that aren't marked for removal
                if !tasksToRemove.contains(ObjectIdentifier(task)) {
                    taskCardView(for: task, at: index)
                }
            }
        }
        .padding()
        .onChange(of: tasks) { oldValue, newValue in
            // Reset the removal tracking when tasks change
            // This ensures we don't accidentally hide new tasks
            tasksToRemove.removeAll()
        }
    }
    
    // MARK: - Task mechanics
    // Extract task card creation to a separate function to reduce complexity
    private func taskCardView(for task: Task, at index: Int) -> some View {
        
        // MARK: - Animations
        // Setup the transition for removal animation
        let insertionTransition = AnyTransition.opacity.combined(with: .scale)
        
        // Create a custom opacity effect that fades out more slowly
        let slowOpacity = AnyTransition.opacity.animation(.easeOut(duration: 1.0))
        
        // Create the removal transition in stages to avoid complex expressions
        let removalStep1 = slowOpacity.combined(with: .offset(x: 250, y: CGFloat(-index * 50) - 250))
        let removalStep2 = removalStep1.combined(with: .scale(scale: 0.2))
        // Note: We can't use rotation3DEffect directly as a transition
        // Just use the steps we already have
        let removalTransition = removalStep2
        
        // The complete transition combines both insertion and removal transitions
        let taskTransition = AnyTransition.asymmetric(
            insertion: insertionTransition,
            removal: removalTransition
        )
        
        // Calculate the vertical offset based on selection mode
        let verticalOffset = isSelectionModeActive ? 
            calculateExpandedOffset(for: index) : 
            calculateYOffset(for: index)
            
        return TaskCardView(task: task) {
            // Toggle completion state
            task.isCompleted.toggle()
            
            // Handle task completion state change
            if task.isCompleted {
                // When a task is completed, it will animate upward and fade out
                _ = withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                    tasksToRemove.insert(ObjectIdentifier(task))
                }
            } else {
                // If task was reopened, make sure it's not in the removal set
                tasksToRemove.remove(ObjectIdentifier(task))
            }
        }
        // Apply positioning and visual effects
        .offset(y: verticalOffset)
        .scaleEffect(calculateScale(for: index))
        .rotation3DEffect(
            task.isCompleted ? .degrees(10) : .degrees(0),
            axis: (x: 1.0, y: 0.2, z: 0.0)
        )
        .zIndex(calculateZIndex(for: index))
        .onHover { isHovered in
            handleHover(isHovered: isHovered, at: index)
        }
        .transition(taskTransition)
        // Animation for hover effects
        .animation(.easeOut(duration: 0.2), value: hoveredTaskIndex)
        // Animation for completion state changes
        .animation(.easeOut(duration: 0.7), value: task.isCompleted)
    }
    
    // MARK: - Hover
    // Handle hover state changes
    private func handleHover(isHovered: Bool, at index: Int) {
        if isHovered {
            // Card is being hovered over
            hoveredTaskIndex = index
            
            // Activate selection mode when any card is hovered
            if !isSelectionModeActive {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isSelectionModeActive = true
                }
            }
        } else if hoveredTaskIndex == index {
            // Card is no longer being hovered
            hoveredTaskIndex = nil
            
            // Keep selection mode active for a shorter time to allow moving to another card
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                if hoveredTaskIndex == nil {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isSelectionModeActive = false
                    }
                }
            }
        }
    }
    
    // MARK: - Overlapping
    /// Calculate the Y offset for a card at the given index
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
    private func calculateScale(for index: Int) -> CGFloat {
        // When cards are fanned out in selection mode, apply distance-based scaling
        if isSelectionModeActive {
            // The hovered card remains at full scale
            if hoveredTaskIndex == index {
                return 1.0
            }
            
            // If no card is hovered, use the middle of the stack as reference
            // For odd-numbered collections, this will be the exact middle
            // For even-numbered collections, it will be just below the middle
            let referenceIndex = hoveredTaskIndex ?? Int(floor(Double(tasks.count - 1) / 2.0))
            
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
            let numberOfCards = CGFloat(tasks.count)
            
            // No scaling if scale amount is 1.0
            if scaleFactor == 1.0 {
                return 1.0
            }
            
            // Otherwise, scale down for deeper cards in the stack
            // Ensure we don't scale below 0.5
            return max(baseScale - (baseScale - scaleFactor) * CGFloat(index) / max(1, numberOfCards - 1), 0.5)
        }
    }
    
    // MARK: - Fanning
    /// Calculate an expanded vertical offset for fan-out view in selection mode
    private func calculateExpandedOffset(for index: Int) -> CGFloat {
        let totalCards = tasks.count
        
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
        let middleIndex = Int(floor(Double(tasks.count - 1) / 2.0))
        let isOddCount = tasks.count % 2 != 0
        
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
        let hoverBonus: CGFloat = (hoveredTaskIndex == index) ? -10 : 0
        
        return basePosition + hoverBonus
    }
    
    // MARK: - Z-index
    /// Calculate the z-index for a card, taking into account hover state
    private func calculateZIndex(for index: Int) -> Double {
        // Default stacking: top card has highest z-index
        let baseZIndex = Double(tasks.count - index)
        
        // Standard stacking when not in selection mode or no task is hovered
        if !isSelectionModeActive || hoveredTaskIndex == nil {
            return baseZIndex
        }
        
        // When in selection mode with a hovered task
        if hoveredTaskIndex == index {
            // Hovered task gets highest z-index
            return 10.0 
        } else {
            // All other tasks get z-index based on distance from hovered task
            let distance = abs(index - (hoveredTaskIndex ?? 0))
            return 10.0 - Double(distance)
        }
    }
}

// MARK: - Previews

#Preview("Scalar") {
    TabView {
        TaskStackView(
            category: .required,
            verticalOffset: 20)
            .frame(height: 600)
            .padding()
            .modelContainer(TaskMockData.createPreviewContainer())
            .tabItem {
                Label("Required", systemImage: "checklist")
            }
            .tag(0)
        
        TaskStackView(
            category: .suggested,
            verticalOffset: 20)
            .frame(height: 600)
            .padding()
            .modelContainer(TaskMockData.createPreviewContainer())
            .tabItem {
                Label("Suggested", systemImage: "checklist")
            }
            .tag(1)
    }
}

#Preview("Log") {
    TaskStackView(
        category: nil,
        offsetByIndex: { i in
            return CGFloat(60 * pow(0.2 * Double(i), 0.5))
        }
    )
        .frame(height: 600)
        .padding()
        .modelContainer(TaskMockData.createPreviewContainer())
}

#Preview("With Scale") {
    TaskStackView(category: .required, verticalOffset: 20, scale: 0.85)
        .frame(height: 600)
        .padding()
        .modelContainer(TaskMockData.createPreviewContainer())
}

#Preview("Log with Scale") {
    TaskStackView(
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
    .modelContainer(TaskMockData.createPreviewContainer())
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
        
        TaskStackView(
            category: .required,
            offsetByIndex: { i in
                return CGFloat(30 * i)
            },
            scale: 0.9
        )
        .frame(height: 600)
    }
    .padding()
    .modelContainer(TaskMockData.createPreviewContainer())
}

#Preview("Interactive") {
    TaskStackAdjustablePreview()
        .modelContainer(TaskMockData.createPreviewContainer())
}

/// An interactive preview wrapper for TaskStackView that allows real-time adjustment with sliders
struct TaskStackAdjustablePreview: View {
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
            
            // TaskStackView with dynamic parameters
            if useScale {
                if useCustomScale {
                    TaskStackView(
                        category: .required,
                        offsetByIndex: offsetFunction,
                        scaleByIndex: customScaleFunction
                    )
                    .frame(minHeight: 380)
                } else {
                    TaskStackView(
                        category: .required,
                        offsetByIndex: offsetFunction,
                        scale: CGFloat(scaleValue)
                    )
                    .frame(minHeight: 380)
                }
            } else {
                TaskStackView(
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
        var code = "TaskStackView(\n"
        
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
