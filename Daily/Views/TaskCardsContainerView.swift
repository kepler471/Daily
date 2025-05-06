//
//  TaskCardsContainerView.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import SwiftUI
import SwiftData

// MARK: - Card Stack Modifiers

/// Applies overlapping effect to cards in a stack
struct CardOverlapModifier: ViewModifier {
    let index: Int
    let amount: CGFloat
    
    func body(content: Content) -> some View {
        content
            .offset(y: CGFloat(index) * amount)
    }
}

/// Applies 3D rotation effect to cards
struct Card3DRotationModifier: ViewModifier {
    let index: Int
    let degrees: Double
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(Double(index) * degrees),
                axis: (x: 1.0, y: 0, z: 0),
                anchor: .bottom,
                perspective: 0.5
            )
    }
}

/// Applies scaling effect to cards
struct CardScalingModifier: ViewModifier {
    let index: Int
    let factor: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(1.0 - (Double(index) * factor), anchor: .bottom)
    }
}

// MARK: - View Extensions

extension View {
    /// Applies an overlapping effect to cards
    func cardOverlap(index: Int, amount: CGFloat = 20) -> some View {
        self.modifier(CardOverlapModifier(index: index, amount: amount))
    }
    
    /// Applies a 3D rotation effect to cards
    func card3DRotation(index: Int, degrees: Double = 5) -> some View {
        self.modifier(Card3DRotationModifier(index: index, degrees: degrees))
    }
    
    /// Applies scaling to create depth effect
    func cardScaling(index: Int, factor: Double = 0.05) -> some View {
        self.modifier(CardScalingModifier(index: index, factor: factor))
    }
}

// MARK: - Task Stack View

struct TaskStackView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    
    var useOverlap: Bool = false
    var useRotation: Bool = false
    var useScaling: Bool = false
    var overlapAmount: CGFloat = 20
    var rotationDegrees: Double = 5
    var scaleFactor: Double = 0.05
    
    init(
        useOverlap: Bool = false,
        useRotation: Bool = false,
        useScaling: Bool = false,
        overlapAmount: CGFloat = 20,
        rotationDegrees: Double = 5,
        scaleFactor: Double = 0.05
    ) {
        self.useOverlap = useOverlap
        self.useRotation = useRotation
        self.useScaling = useScaling
        self.overlapAmount = overlapAmount
        self.rotationDegrees = rotationDegrees
        self.scaleFactor = scaleFactor
        
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
                        withAnimation {
                            task.isCompleted.toggle()
                        }
                    }
                    .zIndex(Double(tasks.count - index))
                    .apply(if: useOverlap) { view in
                        view.cardOverlap(index: index, amount: overlapAmount)
                    }
                    .apply(if: useRotation) { view in
                        view.card3DRotation(index: index, degrees: rotationDegrees)
                    }
                    .apply(if: useScaling) { view in
                        view.cardScaling(index: index, factor: scaleFactor)
                    }
                }
            }
            .padding()
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
                    Label("Basic", systemImage: "list.bullet")
                }
            
            TaskStackView(useOverlap: true)
                .tabItem {
                    Label("Overlap", systemImage: "square.stack")
                }
            
            TaskStackView(useRotation: true)
                .tabItem {
                    Label("Rotation", systemImage: "rotate.3d")
                }
            
            TaskStackView(useScaling: true)
                .tabItem {
                    Label("Scaling", systemImage: "plus.forwardslash.minus")
                }
            
            TaskStackView(useOverlap: true, useRotation: true, useScaling: true)
                .tabItem {
                    Label("All Effects", systemImage: "sparkles")
                }
        }
    }
}

#Preview("Task Stack View Test") {
    TaskStackView()
//        .overlapAmount(0.5)
        .modelContainer(TaskMockData.createPreviewContainer())
}

#Preview("Task Stack View Options") {
    TaskStackViewPreviews()
        .modelContainer(TaskMockData.createPreviewContainer())
}
