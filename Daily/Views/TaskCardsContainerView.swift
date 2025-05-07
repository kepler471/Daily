//
//  TaskCardsContainerView.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import SwiftUI
import SwiftData

// MARK: - Stack Configuration

/// Environment key to store stack configuration
private struct StackConfigurationKey: EnvironmentKey {
    static let defaultValue = StackConfiguration()
}

/// Environment extension for stack configuration
extension EnvironmentValues {
    var stackConfiguration: StackConfiguration {
        get { self[StackConfigurationKey.self] }
        set { self[StackConfigurationKey.self] = newValue }
    }
}

/// Configuration for card stack effects
struct StackConfiguration {
    // Overlap configuration
    var overlapEnabled: Bool = false
    var overlapAmount: CGFloat = 20
    var overlapFunction: (Int, Int) -> CGFloat = { index, total in
        CGFloat(index)
    }
    
    // Rotation configuration
    var rotationEnabled: Bool = false
    var rotationDegrees: Double = 5
    var rotationFunction: (Int, Int) -> Double = { index, total in
        Double(index)
    }
    
    // Scaling configuration
    var scalingEnabled: Bool = false
    var scaleFactor: Double = 0.05
    var scaleFunction: (Int, Int) -> Double = { index, total in
        Double(index)
    }
    
    // Animation configuration
    var animation: Animation? = .easeInOut(duration: 0.3)
}

// MARK: - Stack Effect Modifiers

/// Base modifier for applying stack effects to a collection of views
struct StackEffectModifier: ViewModifier {
    @Environment(\.stackConfiguration) private var config
    
    func body(content: Content) -> some View {
        content
    }
}

/// Applies overlapping effect to cards in a stack
struct CardOverlapModifier: ViewModifier {
    let amount: CGFloat
    let mapper: (Int, Int) -> CGFloat
    
    func body(content: Content) -> some View {
        content.transformEffect { view, index, count in
            view.offset(y: mapper(index, count) * amount)
        }
    }
}

/// Applies 3D rotation effect to cards
struct Card3DRotationModifier: ViewModifier {
    let degrees: Double
    let mapper: (Int, Int) -> Double
    
    func body(content: Content) -> some View {
        content.transformEffect { view, index, count in
            view.rotation3DEffect(
                .degrees(mapper(index, count) * degrees),
                axis: (x: 1.0, y: 0, z: 0),
                anchor: .bottom,
                perspective: 0.5
            )
        }
    }
}

/// Applies scaling effect to cards
struct CardScalingModifier: ViewModifier {
    let factor: Double
    let mapper: (Int, Int) -> Double
    
    func body(content: Content) -> some View {
        content.transformEffect { view, index, count in
            view.scaleEffect(1.0 - (mapper(index, count) * factor), anchor: .bottom)
        }
    }
}

/// Helper modifier that provides index and count info to transformations
struct TransformEffectModifier<T: View>: ViewModifier {
    let transform: (Content, Int, Int) -> T
    
    func body(content: Content) -> some View {
        content // The actual implementation needs access to SwiftUI's internals
               // This is a placeholder as the actual implementation will happen in the TaskStackView
    }
}

// MARK: - View Extensions

extension View {
    /// Applies a transform based on index and total count
    /// Note: This is a placeholder function - actual implementation happens in the parent view
    func transformEffect<T: View>(_ transform: @escaping (Self, Int, Int) -> T) -> some View {
        self // This is a placeholder method for the API design
    }
    
    /// Sets the stack configuration environment for child views
    func stackConfiguration(_ configuration: StackConfiguration) -> some View {
        environment(\.stackConfiguration, configuration)
    }
    
    /// Applies an overlapping effect to cards
    func cardOverlap(_ amount: CGFloat = 20, mapper: @escaping (Int, Int) -> CGFloat = { index, _ in CGFloat(index) }) -> some View {
        self.modifier(CardOverlapModifier(amount: amount, mapper: mapper))
    }
    
    /// Applies a 3D rotation effect to cards
    func card3DRotation(_ degrees: Double = 5, mapper: @escaping (Int, Int) -> Double = { index, _ in Double(index) }) -> some View {
        self.modifier(Card3DRotationModifier(degrees: degrees, mapper: mapper))
    }
    
    /// Applies scaling to create depth effect
    func cardScaling(_ factor: Double = 0.05, mapper: @escaping (Int, Int) -> Double = { index, _ in Double(index) }) -> some View {
        self.modifier(CardScalingModifier(factor: factor, mapper: mapper))
    }
}

// MARK: - Task Stack View

/// A specialized stack view for displaying tasks with various visual effects
struct TaskStackView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    
    // Internal configuration 
    private var config = StackConfiguration()
    
    /// Initialize with default configuration
    init() {
        _tasks = Query(sort: [
            SortDescriptor(\Task.order, order: .forward),
            SortDescriptor(\Task.createdAt, order: .forward)
        ])
    }
    
    /// Initialize with configuration
    init(configuration: StackConfiguration) {
        self.config = configuration
        
        _tasks = Query(sort: [
            SortDescriptor(\Task.order, order: .forward),
            SortDescriptor(\Task.createdAt, order: .forward)
        ])
    }
    
    /// Backwards compatibility initializer
    init(
        useOverlap: Bool = false,
        useRotation: Bool = false,
        useScaling: Bool = false,
        overlapAmount: CGFloat = 20,
        rotationDegrees: Double = 5,
        scaleFactor: Double = 0.05
    ) {
        // Convert old parameters to new configuration
        var config = StackConfiguration()
        config.overlapEnabled = useOverlap
        config.overlapAmount = overlapAmount
        config.rotationEnabled = useRotation
        config.rotationDegrees = rotationDegrees
        config.scalingEnabled = useScaling
        config.scaleFactor = scaleFactor
        
        self.config = config
        
        _tasks = Query(sort: [
            SortDescriptor(\Task.order, order: .forward),
            SortDescriptor(\Task.createdAt, order: .forward)
        ])
    }
    
    var body: some View {
        ScrollView {
            ZStack {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                    TaskCardView(task: task) {
                        withAnimation(config.animation) {
                            task.isCompleted.toggle()
                        }
                    }
                    .zIndex(Double(tasks.count - index))
                    // Apply the transformations with the actual index information
                    .modifier(CardStackModifiers(index: index, count: tasks.count, config: config))
                }
            }
            .padding()
        }
        .environment(\.stackConfiguration, config)
    }
    
    /// Applies card overlap effect
    func cardOverlap(_ amount: CGFloat, mapper: @escaping (Int, Int) -> CGFloat = { index, _ in CGFloat(index) }) -> TaskStackView {
        var newConfig = config
        newConfig.overlapEnabled = true
        newConfig.overlapAmount = amount
        newConfig.overlapFunction = mapper
        return TaskStackView(configuration: newConfig)
    }
    
    /// Applies card 3D rotation effect
    func card3DRotation(_ degrees: Double, mapper: @escaping (Int, Int) -> Double = { index, _ in Double(index) }) -> TaskStackView {
        var newConfig = config
        newConfig.rotationEnabled = true
        newConfig.rotationDegrees = degrees
        newConfig.rotationFunction = mapper
        return TaskStackView(configuration: newConfig)
    }
    
    /// Applies card scaling effect
    func cardScaling(_ factor: Double, mapper: @escaping (Int, Int) -> Double = { index, _ in Double(index) }) -> TaskStackView {
        var newConfig = config
        newConfig.scalingEnabled = true
        newConfig.scaleFactor = factor
        newConfig.scaleFunction = mapper
        return TaskStackView(configuration: newConfig)
    }
    
    /// Applies animation to the effects
    func withStackAnimation(_ animation: Animation?) -> TaskStackView {
        var newConfig = config
        newConfig.animation = animation
        return TaskStackView(configuration: newConfig)
    }
}

/// A composite modifier that applies all card stack effects based on index
struct CardStackModifiers: ViewModifier {
    let index: Int
    let count: Int
    let config: StackConfiguration
    
    func body(content: Content) -> some View {
        content
            .modifier(CardStackOverlapModifier(
                enabled: config.overlapEnabled,
                index: index,
                count: count,
                amount: config.overlapAmount,
                mapper: config.overlapFunction
            ))
            .modifier(CardStack3DRotationModifier(
                enabled: config.rotationEnabled,
                index: index,
                count: count,
                degrees: config.rotationDegrees,
                mapper: config.rotationFunction
            ))
            .modifier(CardStackScalingModifier(
                enabled: config.scalingEnabled,
                index: index,
                count: count,
                factor: config.scaleFactor,
                mapper: config.scaleFunction
            ))
    }
}

/// Actual implementation of the card overlap effect
struct CardStackOverlapModifier: ViewModifier {
    let enabled: Bool
    let index: Int
    let count: Int
    let amount: CGFloat
    let mapper: (Int, Int) -> CGFloat
    
    func body(content: Content) -> some View {
        if enabled {
            content
                .offset(y: mapper(index, count) * amount)
        } else {
            content
        }
    }
}

/// Actual implementation of the card 3D rotation effect
struct CardStack3DRotationModifier: ViewModifier {
    let enabled: Bool
    let index: Int
    let count: Int
    let degrees: Double
    let mapper: (Int, Int) -> Double
    
    func body(content: Content) -> some View {
        if enabled {
            content
                .rotation3DEffect(
                    .degrees(mapper(index, count) * degrees),
                    axis: (x: 1.0, y: 0, z: 0),
                    anchor: .bottom,
                    perspective: 0.5
                )
        } else {
            content
        }
    }
}

/// Actual implementation of the card scaling effect
struct CardStackScalingModifier: ViewModifier {
    let enabled: Bool
    let index: Int
    let count: Int
    let factor: Double
    let mapper: (Int, Int) -> Double
    
    func body(content: Content) -> some View {
        if enabled {
            content
                .scaleEffect(1.0 - (mapper(index, count) * factor), anchor: .bottom)
        } else {
            content
        }
    }
}

// MARK: - Helper Extensions

extension View {
    /// Conditionally applies a modifier
    @ViewBuilder func apply<T: View>(if condition: Bool, transform: (Self) -> T) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Previews

struct TaskStackViewPreviews: View {
    var body: some View {
        TabView {
            TaskStackView()
                .tabItem {
                    Label("1", systemImage: "list.bullet")
                }
            
            // Using the new modifier approach
            TaskStackView()
                .cardOverlap(20)
                .tabItem {
                    Label("2", systemImage: "square.stack")
                }
            
            // Using the new modifier with custom mapping function
            TaskStackView()
                .cardOverlap(25) { index, count in
                    // Non-linear spacing - cards closer at the top
                    CGFloat(index) * (1.0 - CGFloat(index) / CGFloat(count) * 0.3)
                }
                .tabItem {
                    Label("3", systemImage: "square.stack.3d")
                }
            
            TaskStackView()
                .card3DRotation(5)
                .tabItem {
                    Label("4", systemImage: "rotate.3d")
                }
            
            TaskStackView()
                .cardScaling(0.05)
                .tabItem {
                    Label("5", systemImage: "plus.forwardslash.minus")
                }
            
            // Combining multiple effects with animation
            TaskStackView()
                .cardOverlap(20)
                .card3DRotation(5)
                .cardScaling(0.05)
                .withStackAnimation(.spring(duration: 0.4))
                .tabItem {
                    Label("6", systemImage: "sparkles")
                }
            
            // Using the old approach for backwards compatibility
            TaskStackView(useOverlap: true, useRotation: true, useScaling: true)
                .tabItem {
                    Label("7", systemImage: "backward")
                }
        }
    }
}

#Preview("Task Stack View Options") {
    TaskStackViewPreviews()
        .modelContainer(TaskMockData.createPreviewContainer())
}
