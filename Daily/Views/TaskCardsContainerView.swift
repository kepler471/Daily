//
//  TaskCardsContainerView.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//
//  A customizable card stack view for displaying tasks with visual effects.
//  This implementation uses SwiftUI's layout protocol for better separation of concerns.

import SwiftUI
import SwiftData

// MARK: - Environment Keys

/// Environment key for card overlap amount
private struct CardOverlapKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

/// Environment key for overlap mapping function
private struct CardOverlapMapperKey: EnvironmentKey {
    static let defaultValue: (Int, Int) -> CGFloat = { index, _ in CGFloat(index) }
}

/// Environment key for card rotation degrees
private struct CardRotationKey: EnvironmentKey {
    static let defaultValue: Double = 0
}

/// Environment key for rotation mapping function
private struct CardRotationMapperKey: EnvironmentKey {
    static let defaultValue: (Int, Int) -> Double = { index, _ in Double(index) }
}

/// Environment key for card scale factor
private struct CardScaleKey: EnvironmentKey {
    static let defaultValue: Double = 0
}

/// Environment key for scale mapping function
private struct CardScaleMapperKey: EnvironmentKey {
    static let defaultValue: (Int, Int) -> Double = { index, _ in Double(index) }
}

extension EnvironmentValues {
    /// Amount of vertical overlap between cards
    var cardOverlap: CGFloat {
        get { self[CardOverlapKey.self] }
        set { self[CardOverlapKey.self] = newValue }
    }
    
    /// Function that maps card index to overlap factor
    var cardOverlapMapper: (Int, Int) -> CGFloat {
        get { self[CardOverlapMapperKey.self] }
        set { self[CardOverlapMapperKey.self] = newValue }
    }
    
    /// Degrees of 3D rotation for cards
    var cardRotation: Double {
        get { self[CardRotationKey.self] }
        set { self[CardRotationKey.self] = newValue }
    }
    
    /// Function that maps card index to rotation factor
    var cardRotationMapper: (Int, Int) -> Double {
        get { self[CardRotationMapperKey.self] }
        set { self[CardRotationMapperKey.self] = newValue }
    }
    
    /// Scale reduction factor for cards
    var cardScale: Double {
        get { self[CardScaleKey.self] }
        set { self[CardScaleKey.self] = newValue }
    }
    
    /// Function that maps card index to scale factor
    var cardScaleMapper: (Int, Int) -> Double {
        get { self[CardScaleMapperKey.self] }
        set { self[CardScaleMapperKey.self] = newValue }
    }
}

// MARK: - Card Stack Layout

/// A layout that arranges cards in a stack with optional 3D effects
struct CardStackLayout: Layout {
    // Access all effect parameters from environment
    @Environment(\.cardOverlap) private var overlapAmount
    @Environment(\.cardOverlapMapper) private var overlapMapper
    @Environment(\.cardRotation) private var rotationDegrees
    @Environment(\.cardRotationMapper) private var rotationMapper
    @Environment(\.cardScale) private var scaleFactor
    @Environment(\.cardScaleMapper) private var scaleMapper
    
    /// Calculate the size needed for the layout
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        
        // Find the largest subview to determine base size
        var maxSize = CGSize.zero
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            maxSize.width = max(maxSize.width, size.width)
            maxSize.height = max(maxSize.height, size.height)
        }
        
        // Calculate total height with overlap effect
        let totalCount = subviews.count
        var totalHeight = maxSize.height
        
        if overlapAmount > 0 && totalCount > 1 {
            // Calculate height based on the overlap of the last item
            let lastIndex = totalCount - 1
            let lastOverlap = overlapAmount * overlapMapper(lastIndex, totalCount)
            totalHeight += lastOverlap
        }
        
        return CGSize(width: maxSize.width, height: totalHeight)
    }
    
    /// Position the subviews with effects applied
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }
        
        let totalCount = subviews.count
        
        // Apply z-index to ensure proper stacking order
        for (index, subview) in subviews.enumerated() {
            // Calculate z-index (higher index = further back in stack)
            let zIndex = Double(totalCount - index)
            
            // Position the subview
            let size = subview.sizeThatFits(.unspecified)
            
            // Center horizontally, position vertically based on overlap
            var point = CGPoint(
                x: bounds.midX - size.width/2,
                y: bounds.minY
            )
            
            // Apply overlap based on mapping function
            if overlapAmount > 0 {
                let yOffset = overlapAmount * overlapMapper(index, totalCount)
                point.y += yOffset
            }
            
            // Place the view with proposal and anchor
            subview.place(
                at: point,
                anchor: .topLeading,
                proposal: .unspecified
            )
            
            // 3D rotation and scaling are applied through transform effects
            // We can't directly apply them in the layout, so they'll be handled
            // by modifiers on the subviews in the ContentUnavailableView
        }
    }
}

// MARK: - Effect Modifiers

/// Modifier to set card overlap amount
struct CardOverlapModifier: ViewModifier {
    let amount: CGFloat
    let mapper: (Int, Int) -> CGFloat
    
    func body(content: Content) -> some View {
        content
            .environment(\.cardOverlap, amount)
            .environment(\.cardOverlapMapper, mapper)
    }
}

/// Modifier to set card rotation amount
struct CardRotationModifier: ViewModifier {
    let degrees: Double
    let mapper: (Int, Int) -> Double
    
    func body(content: Content) -> some View {
        content
            .environment(\.cardRotation, degrees)
            .environment(\.cardRotationMapper, mapper)
    }
}

/// Modifier to set card scaling amount
struct CardScalingModifier: ViewModifier {
    let factor: Double
    let mapper: (Int, Int) -> Double
    
    func body(content: Content) -> some View {
        content
            .environment(\.cardScale, factor)
            .environment(\.cardScaleMapper, mapper)
    }
}

// MARK: - View Extensions

extension View {
    /// Sets the overlap amount for cards in a CardStackLayout
    func cardStackOverlap(
        _ amount: CGFloat = 20,
        mapper: @escaping (Int, Int) -> CGFloat = { index, _ in CGFloat(index) }
    ) -> some View {
        modifier(CardOverlapModifier(amount: amount, mapper: mapper))
    }
    
    /// Sets the rotation amount for cards in a CardStackLayout
    func cardStackRotation(
        _ degrees: Double = 5,
        mapper: @escaping (Int, Int) -> Double = { index, _ in Double(index) }
    ) -> some View {
        modifier(CardRotationModifier(degrees: degrees, mapper: mapper))
    }
    
    /// Sets the scaling factor for cards in a CardStackLayout
    func cardStackScaling(
        _ factor: Double = 0.05,
        mapper: @escaping (Int, Int) -> Double = { index, _ in Double(index) }
    ) -> some View {
        modifier(CardScalingModifier(factor: factor, mapper: mapper))
    }
}

// MARK: - Task Stack View

/// A simple stack view for displaying tasks
/// 
/// This view is completely independent from any visual effects or transformations.
/// It simply displays tasks using the CardStackLayout.
struct TaskStackView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    
    init() {
        _tasks = Query(sort: [
            SortDescriptor(\Task.order, order: .forward),
            SortDescriptor(\Task.createdAt, order: .forward)
        ])
    }
    
    var body: some View {
        CardStackLayout {
            ForEach(tasks) { task in
                TaskCardView(task: task) {
                    task.isCompleted.toggle()
                }
            }
        }
        .padding()
    }
}

// MARK: - Previews

struct TaskStackViewPreviews: View {
    var body: some View {
        TabView {
            // Basic view with no effects
            TaskStackView()
                .tabItem {
                    Label("Basic", systemImage: "list.bullet")
                }
            
            // Simple overlap effect
            TaskStackView()
                .cardStackOverlap(20)
                .tabItem {
                    Label("Overlap", systemImage: "square.stack")
                }
            
            // With rotation
            TaskStackView()
                .cardStackOverlap(20)
                .cardStackRotation(-5)
                .tabItem {
                    Label("Rotation", systemImage: "rotate.3d")
                }
            
            // With scaling
            TaskStackView()
                .cardStackOverlap(20)
                .cardStackScaling(0.05)
                .tabItem {
                    Label("Scaling", systemImage: "plus.forwardslash.minus")
                }
            
            // Custom mapping function
            TaskStackView()
                .cardStackOverlap(25) { index, count in
                    // Non-linear spacing - cards closer at the top
                    CGFloat(index) * (1.5 - CGFloat(index) / CGFloat(count) * 0.5)
                }
                .tabItem {
                    Label("Custom", systemImage: "square.stack.3d")
                }
            
            // Combined effects
            TaskStackView()
                .cardStackOverlap(30)
                .cardStackRotation(-2)
                .cardStackScaling(0.05)
                .tabItem {
                    Label("Combined", systemImage: "sparkles")
                }
        }
    }
}

#Preview("Card Stack Options") {
    TaskStackViewPreviews()
        .modelContainer(TaskMockData.createPreviewContainer())
}
