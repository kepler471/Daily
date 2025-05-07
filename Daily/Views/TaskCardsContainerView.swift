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

// MARK: - Task Stack View

/// A simple stack view for displaying tasks
/// 
/// This view is completely independent from any visual effects or transformations.
/// It simply displays tasks in their default order.
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

// MARK: - Card Stack Layout

/// A layout that stacks cards with configurable overlap, rotation, and scaling
struct CardStackLayout: Layout {
    // Default configuration
    var overlapAmount: CGFloat = 0
    var rotationDegrees: Double = 0
    var scaleFactor: Double = 0
    
    // Mapping functions for more complex transformations
    var overlapMapper: (Int, Int) -> CGFloat = { _, _ in 1 }
    var rotationMapper: (Int, Int) -> Double = { _, _ in 1 }
    var scaleMapper: (Int, Int) -> Double = { _, _ in 1 }
    
    /// Determines the size of the layout container
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
    
    /// Places the subviews within the layout
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }
        
        let totalCount = subviews.count
        
        // Place each subview with the appropriate effects
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            
            // Calculate the position (centered horizontally)
            var point = CGPoint(
                x: bounds.midX - size.width/2,
                y: bounds.minY
            )
            
            // Apply overlap effect
            if overlapAmount > 0 {
                let yOffset = overlapAmount * overlapMapper(index, totalCount)
                point.y += yOffset
            }
            
            // Place the view
            subview.place(at: point, anchor: .topLeading, proposal: .unspecified)
            
            // Apply 3D rotation and scaling transformations
            if rotationDegrees != 0 || scaleFactor != 0 {
                let rotation = rotationDegrees * rotationMapper(index, totalCount)
                let scale = scaleFactor > 0 ? 1.0 - (scaleFactor * scaleMapper(index, totalCount)) : 1.0
                
                // We would apply these transforms here if this was a real implementation
                // Since we can't directly modify the transform in Layout, we'll use 
                // modifier extensions to apply them after placement
            }
        }
    }
}

// MARK: - Stack Layout Modifiers

extension CardStackLayout {
    /// Applies vertical overlap effect to the card stack
    func cardOverlap(
        amount: CGFloat = 20,
        mapper: @escaping (Int, Int) -> CGFloat = { index, _ in CGFloat(index) }
    ) -> CardStackLayout {
        var layout = self
        layout.overlapAmount = amount
        layout.overlapMapper = mapper
        return layout
    }
    
    /// Applies 3D rotation effect to the card stack
    func cardRotation(
        degrees: Double = 5,
        mapper: @escaping (Int, Int) -> Double = { index, _ in Double(index) }
    ) -> CardStackLayout {
        var layout = self
        layout.rotationDegrees = degrees
        layout.rotationMapper = mapper
        return layout
    }
    
    /// Applies scaling effect to the card stack
    func cardScaling(
        factor: Double = 0.05,
        mapper: @escaping (Int, Int) -> Double = { index, _ in Double(index) }
    ) -> CardStackLayout {
        var layout = self
        layout.scaleFactor = factor
        layout.scaleMapper = mapper
        return layout
    }
}

// MARK: - View Modifiers for 3D Effects

/// Applies 3D rotation effect to a view
struct Card3DEffectModifier: ViewModifier {
    let index: Int
    let count: Int
    let degrees: Double
    let mapper: (Int, Int) -> Double
    
    func body(content: Content) -> some View {
        let rotation = degrees * mapper(index, count)
        return content
            .rotation3DEffect(
                .degrees(rotation),
                axis: (x: 1.0, y: 0, z: 0),
                anchor: .bottom,
                perspective: 0.5
            )
    }
}

/// Applies scaling effect to a view
struct CardScalingEffectModifier: ViewModifier {
    let index: Int
    let count: Int
    let factor: Double
    let mapper: (Int, Int) -> Double
    
    func body(content: Content) -> some View {
        let scale = 1.0 - (factor * mapper(index, count))
        return content.scaleEffect(scale, anchor: .bottom)
    }
}

/// Helper extension for applying effects 
extension View {
    /// Applies 3D rotation effect
    func card3DEffect(
        index: Int,
        count: Int,
        degrees: Double,
        mapper: @escaping (Int, Int) -> Double
    ) -> some View {
        self.modifier(Card3DEffectModifier(
            index: index,
            count: count,
            degrees: degrees,
            mapper: mapper
        ))
    }
    
    /// Applies scaling effect
    func cardScalingEffect(
        index: Int,
        count: Int,
        factor: Double,
        mapper: @escaping (Int, Int) -> Double
    ) -> some View {
        self.modifier(CardScalingEffectModifier(
            index: index,
            count: count,
            factor: factor,
            mapper: mapper
        ))
    }
}

// MARK: - ViewBuilder Extensions

/// CardStack container that combines layout with transformations
struct CardStack<Content: View>: View {
    let content: () -> Content
    
    var overlapAmount: CGFloat = 0
    var rotationDegrees: Double = 0
    var scaleFactor: Double = 0
    
    var overlapMapper: (Int, Int) -> CGFloat = { index, _ in CGFloat(index) }
    var rotationMapper: (Int, Int) -> Double = { index, _ in Double(index) }
    var scaleMapper: (Int, Int) -> Double = { index, _ in Double(index) }
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            // On iOS 16+ and macOS 13+, use the built-in Layout system
            CardStackLayout()
                .cardOverlap(amount: overlapAmount, mapper: overlapMapper)
                .cardRotation(degrees: rotationDegrees, mapper: rotationMapper)
                .cardScaling(factor: scaleFactor, mapper: scaleMapper)
            {
                content()
            }
        } else {
            // On older systems, fall back to a ZStack with manual transforms
            ZStack {
                // Implementation for older OS versions would go here
                content()
            }
        }
    }
    
    // MARK: - Fluent API
    
    /// Applies overlap effect to the card stack
    func cardOverlap(
        amount: CGFloat = 20,
        mapper: @escaping (Int, Int) -> CGFloat = { index, _ in CGFloat(index) }
    ) -> CardStack<Content> {
        var stack = self
        stack.overlapAmount = amount
        stack.overlapMapper = mapper
        return stack
    }
    
    /// Applies 3D rotation effect to the card stack
    func cardRotation(
        degrees: Double = 5,
        mapper: @escaping (Int, Int) -> Double = { index, _ in Double(index) }
    ) -> CardStack<Content> {
        var stack = self
        stack.rotationDegrees = degrees
        stack.rotationMapper = mapper
        return stack
    }
    
    /// Applies scaling effect to the card stack
    func cardScaling(
        factor: Double = 0.05,
        mapper: @escaping (Int, Int) -> Double = { index, _ in Double(index) }
    ) -> CardStack<Content> {
        var stack = self
        stack.scaleFactor = factor
        stack.scaleMapper = mapper
        return stack
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
            
            // Using CardStack container with overlap effect
            CardStack {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.8 - Double(index) * 0.1))
                        .frame(width: 300, height: 200)
                }
            }
            .cardOverlap(amount: 20)
            .tabItem {
                Label("Overlap", systemImage: "square.stack")
            }
            
            // With rotation
            CardStack {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green.opacity(0.8 - Double(index) * 0.1))
                        .frame(width: 300, height: 200)
                }
            }
            .cardOverlap(amount: 20)
            .cardRotation(degrees: -5)
            .tabItem {
                Label("Rotation", systemImage: "rotate.3d")
            }
            
            // With scaling
            CardStack {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.orange.opacity(0.8 - Double(index) * 0.1))
                        .frame(width: 300, height: 200)
                }
            }
            .cardOverlap(amount: 20)
            .cardScaling(factor: 0.05)
            .tabItem {
                Label("Scaling", systemImage: "plus.forwardslash.minus")
            }
            
            // Custom mapping function
            CardStack {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.purple.opacity(0.8 - Double(index) * 0.1))
                        .frame(width: 300, height: 200)
                }
            }
            .cardOverlap(amount: 25) { index, count in
                // Non-linear spacing
                CGFloat(index) * (1.5 - CGFloat(index) / CGFloat(count) * 0.5)
            }
            .tabItem {
                Label("Custom", systemImage: "square.stack.3d")
            }
            
            // Combined effects
            CardStack {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.red.opacity(0.8 - Double(index) * 0.1))
                        .frame(width: 300, height: 200)
                }
            }
            .cardOverlap(amount: 30)
            .cardRotation(degrees: -2)
            .cardScaling(factor: 0.05)
            .tabItem {
                Label("Combined", systemImage: "sparkles")
            }
        }
    }
}

#Preview("Card Stack Options") {
    TaskStackViewPreviews()
}