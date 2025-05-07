//
//  TaskCardsContainerView.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//
//  A customizable card stack view for displaying tasks with visual effects.
//  This implementation provides a fluent API for applying various transformations
//  to a stack of task cards, such as overlap, 3D rotation, and scaling.

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

/// Configuration for card stack visual effects
///
/// This struct holds all configuration options for the TaskStackView's
/// visual effects, including overlap, rotation, scaling, and animations.
/// Each effect can be individually enabled/disabled and configured with
/// custom transformation functions.
struct StackConfiguration {
    /// Function type for mapping from item index and total count to a transformation value
    typealias TransformMapper<T: BinaryFloatingPoint> = (Int, Int) -> T
    
    /// Generic configuration for a single stack effect
    ///
    /// This struct defines how a particular effect (overlap, rotation, scaling)
    /// should be applied to items in the stack based on their position.
    struct EffectConfig<T: BinaryFloatingPoint> {
        /// Whether this effect is enabled
        var enabled: Bool
        
        /// The base value for the effect (amount, degrees, factor)
        var value: T
        
        /// A function that maps the item's index and total count to a multiplier
        /// for the effect value. This allows for non-linear transformations.
        var mapper: TransformMapper<T>
        
        /// Creates a new effect configuration
        /// - Parameters:
        ///   - enabled: Whether this effect is enabled (default: false)
        ///   - value: The base value for the effect
        ///   - mapper: A function that determines how the effect varies by index
        ///             (default: linear progression based on index)
        init(enabled: Bool = false, value: T, mapper: @escaping TransformMapper<T> = { index, _ in T(index) }) {
            self.enabled = enabled
            self.value = value
            self.mapper = mapper
        }
    }
    
    /// Vertical overlapping effect configuration (default: 20pt per card)
    var overlap = EffectConfig<CGFloat>(value: 20)
    
    /// 3D rotation effect configuration (default: 5 degrees per card)
    var rotation = EffectConfig<Double>(value: 5)
    
    /// Scaling effect configuration (default: 5% reduction per card)
    var scaling = EffectConfig<Double>(value: 0.05)
    
}

// MARK: - View Extensions

extension View {
    /// Sets the stack configuration environment for child views
    func stackConfiguration(_ configuration: StackConfiguration) -> some View {
        environment(\.stackConfiguration, configuration)
    }
    
    /// Applies vertical overlapping effect to cards
    func cardOverlap(index: Int, count: Int, amount: CGFloat = 20, mapper: @escaping (Int, Int) -> CGFloat = { index, _ in CGFloat(index) }) -> some View {
        self.modifier(CardOverlapModifier(index: index, count: count, amount: amount, mapper: mapper))
    }
    
    /// Applies 3D rotation effect to cards
    func card3DRotation(index: Int, count: Int, degrees: Double = 5, mapper: @escaping (Int, Int) -> Double = { index, _ in Double(index) }) -> some View {
        self.modifier(Card3DRotationModifier(index: index, count: count, degrees: degrees, mapper: mapper))
    }
    
    /// Applies scaling effect to cards
    func cardScaling(index: Int, count: Int, factor: Double = 0.05, mapper: @escaping (Int, Int) -> Double = { index, _ in Double(index) }) -> some View {
        self.modifier(CardScalingModifier(index: index, count: count, factor: factor, mapper: mapper))
    }
}

// MARK: - Task Stack View

/// A stack view for displaying tasks with customizable visual effects
///
/// `TaskStackView` provides a fluent API for configuring visual effects like overlap,
/// 3D rotation, and scaling. Each effect can be controlled with precision through
/// custom mapping functions that determine how the effect varies by card position.
///
/// Example usage:
/// ```
/// TaskStackView()
///     .cardOverlap(20)
///     .card3DRotation(5)
///     .cardScaling(0.05)
///     .withStackAnimation(.spring(duration: 0.4))
///     .modelContainer(container)
/// ```
struct TaskStackView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    
    /// Configuration for all visual effects
    private var config = StackConfiguration()
    
    // MARK: - Initializers
    
    /// Creates a task stack view with default configuration
    init() {
        _tasks = Query(sort: [
            SortDescriptor(\Task.order, order: .forward),
            SortDescriptor(\Task.createdAt, order: .forward)
        ])
    }
    
    /// Creates a task stack view with custom configuration
    /// - Parameter configuration: The configuration to use for visual effects
    init(configuration: StackConfiguration) {
        self.config = configuration
        
        _tasks = Query(sort: [
            SortDescriptor(\Task.order, order: .forward),
            SortDescriptor(\Task.createdAt, order: .forward)
        ])
    }
    
    // MARK: - View Body
    
    var body: some View {
        ScrollView {
            ZStack {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                    TaskCardView(task: task) {
                        task.isCompleted.toggle()
                    }
                    .zIndex(Double(tasks.count - index))
                    .apply(if: config.overlap.enabled) { view in
                        view.cardOverlap(
                            index: index,
                            count: tasks.count,
                            amount: config.overlap.value,
                            mapper: config.overlap.mapper
                        )
                    }
                    .apply(if: config.rotation.enabled) { view in
                        view.card3DRotation(
                            index: index,
                            count: tasks.count,
                            degrees: config.rotation.value,
                            mapper: config.rotation.mapper
                        )
                    }
                    .apply(if: config.scaling.enabled) { view in
                        view.cardScaling(
                            index: index,
                            count: tasks.count,
                            factor: config.scaling.value,
                            mapper: config.scaling.mapper
                        )
                    }
                }
            }
            .padding()
        }
        .environment(\.stackConfiguration, config)
    }
    
    // MARK: - Effect Modifiers
    
    /// Applies vertical overlap effect to cards in the stack
    /// - Parameters:
    ///   - amount: Amount of overlap in points (default: 20)
    ///   - mapper: Function that maps (index, count) to a multiplier for the effect
    /// - Returns: A new TaskStackView with the overlap effect applied
    func cardOverlap(
        _ amount: CGFloat = 20,
        mapper: @escaping StackConfiguration.TransformMapper<CGFloat> = { index, _ in CGFloat(index) }
    ) -> TaskStackView {
        var newConfig = config
        newConfig.overlap = .init(enabled: true, value: amount, mapper: mapper)
        return TaskStackView(configuration: newConfig)
    }
    
    /// Applies 3D rotation effect to cards in the stack
    /// - Parameters:
    ///   - degrees: Base degrees of rotation (default: 5)
    ///   - mapper: Function that maps (index, count) to a multiplier for the effect
    /// - Returns: A new TaskStackView with the rotation effect applied
    func card3DRotation(
        _ degrees: Double = 5,
        mapper: @escaping StackConfiguration.TransformMapper<Double> = { index, _ in Double(index) }
    ) -> TaskStackView {
        var newConfig = config
        newConfig.rotation = .init(enabled: true, value: degrees, mapper: mapper)
        return TaskStackView(configuration: newConfig)
    }
    
    /// Applies scaling effect to cards in the stack
    /// - Parameters:
    ///   - factor: Scale reduction factor (default: 0.05 = 5% reduction per card)
    ///   - mapper: Function that maps (index, count) to a multiplier for the effect
    /// - Returns: A new TaskStackView with the scaling effect applied
    func cardScaling(
        _ factor: Double = 0.05,
        mapper: @escaping StackConfiguration.TransformMapper<Double> = { index, _ in Double(index) }
    ) -> TaskStackView {
        var newConfig = config
        newConfig.scaling = .init(enabled: true, value: factor, mapper: mapper)
        return TaskStackView(configuration: newConfig)
    }
    
}

/// Applies vertical overlapping effect to cards in a stack
struct CardOverlapModifier: ViewModifier {
    /// The position of the item in the stack (0-based index)
    let index: Int
    
    /// The total number of items in the stack
    let count: Int
    
    /// Amount of overlap in points
    let amount: CGFloat
    
    /// Function to map index to a multiplier value
    let mapper: (Int, Int) -> CGFloat
    
    func body(content: Content) -> some View {
        let offset = mapper(index, count) * amount
        return content.offset(y: offset)
    }
}

/// Applies 3D rotation effect to cards in a stack
struct Card3DRotationModifier: ViewModifier {
    /// The position of the item in the stack (0-based index)
    let index: Int
    
    /// The total number of items in the stack
    let count: Int
    
    /// Base degrees of rotation
    let degrees: Double
    
    /// Function to map index to a multiplier value
    let mapper: (Int, Int) -> Double
    
    func body(content: Content) -> some View {
        let rotation = mapper(index, count) * degrees
        return content.rotation3DEffect(
            .degrees(rotation),
            axis: (x: 1.0, y: 0, z: 0),
            anchor: .bottom,
            perspective: 0.5
        )
    }
}

/// Applies scaling effect to cards in a stack
struct CardScalingModifier: ViewModifier {
    /// The position of the item in the stack (0-based index)
    let index: Int
    
    /// The total number of items in the stack
    let count: Int
    
    /// Scale reduction factor per item
    let factor: Double
    
    /// Function to map index to a multiplier value
    let mapper: (Int, Int) -> Double
    
    func body(content: Content) -> some View {
        let scale = 1.0 - (mapper(index, count) * factor)
        return content.scaleEffect(scale, anchor: .bottom)
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
                .cardOverlap(100)
                .tabItem {
                    Label("1", systemImage: "list.bullet")
                }
            
            // Using the new modifier approach
            TaskStackView()
                .cardOverlap(20)
                .cardScaling(0.05)
                .tabItem {
                    Label("2", systemImage: "square.stack")
                }
            
            // Using the new modifier with custom mapping function
            TaskStackView()
                .cardOverlap(20) { index, count in
                    // Non-linear spacing - cards closer at the top
                    CGFloat(index) * (1.5 - CGFloat(index) / CGFloat(count) * 0.5)
                }
                .tabItem {
                    Label("3", systemImage: "square.stack.3d")
                }
            
            TaskStackView()
                .cardOverlap(20)
                .card3DRotation(-5)
                .tabItem {
                    Label("4", systemImage: "rotate.3d")
                }
            
            TaskStackView()
                .cardOverlap(20)
                .cardScaling(0.05)
                .tabItem {
                    Label("5", systemImage: "plus.forwardslash.minus")
                }
            
            // Combining multiple effects with animation
            TaskStackView()
                .cardOverlap(30)
                .card3DRotation(-2)
                .cardScaling(0.05)
                .tabItem {
                    Label("6", systemImage: "sparkles")
                }
        }
    }
}

#Preview("Task Stack View Options") {
    TaskStackViewPreviews()
        .modelContainer(TaskMockData.createPreviewContainer())
}
