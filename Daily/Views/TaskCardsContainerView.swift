//
//  TaskCardsContainerView.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import SwiftUI
import SwiftData

// 3D Card Stack Effect Modifier
struct Card3DStackModifier: ViewModifier {
    let index: Int
    let totalCount: Int
    let overlapAmount: CGFloat
    
    func body(content: Content) -> some View {
        content
            .zIndex(Double(totalCount - index)) // Higher z-index for items at the top
            .offset(y: CGFloat(index) * -overlapAmount) // Negative offset to create overlap
            .rotation3DEffect(
                .degrees(index == 0 ? 0 : -2), // Slight rotation for 3D effect
                axis: (x: 1.0, y: 0.0, z: 0.0), // Rotate around X axis
                anchor: .top // Pivot from the top
            )
            .scaleEffect(1.0 - CGFloat(index) * 0.01) // Subtle scaling to enhance 3D effect
            .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 3 + CGFloat(index))
            .transition(
                .asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity).combined(with: .offset(y: -20))
                )
            )
    }
}

// Extension to add the 3D card stack modifier
extension View {
    func card3DStack(index: Int, totalCount: Int, overlapAmount: CGFloat = 30) -> some View {
        self.modifier(Card3DStackModifier(
            index: index,
            totalCount: totalCount,
            overlapAmount: overlapAmount
        ))
    }
}

struct TaskCardsContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    
    init(category: TaskCategory? = nil) {
        if let category = category {
            let categoryString = category.rawValue
            _tasks = Query(filter: #Predicate<Task> { task in
                task.categoryRaw == categoryString
            }, sort: [
                SortDescriptor(\Task.order, order: .forward),
                SortDescriptor(\Task.createdAt, order: .forward)
            ])
        } else {
            _tasks = Query(sort: [
                SortDescriptor(\Task.order, order: .forward),
                SortDescriptor(\Task.createdAt, order: .forward)
            ])
        }
    }
    
    var body: some View {
        ScrollView {
            ZStack(alignment: .top) {
                // We use the ZStack with top alignment for the overlapping effect
                VStack(spacing: 0) {
                    // Reserve space for all cards (minus their overlap)
                    // Each card is about 110-150px tall and we want to offset by the overlapping amount
                    if !tasks.isEmpty {
                        let totalHeight = CGFloat(tasks.count) * 140 - CGFloat(tasks.count - 1) * 30
                        Color.clear
                            .frame(height: totalHeight)
                    }
                }
                
                VStack(spacing: 0) {
                    ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                        TaskCardView(task: task) {
                            toggleTaskCompletion(task)
                        }
                        .card3DStack(index: index, totalCount: tasks.count, overlapAmount: 30)
                    }
                    
                    // Empty view at the bottom for better UX when scrolling
                    Color.clear
                        .frame(height: 40)
                }
            }
            .padding(.top)
        }
        .scrollIndicators(.hidden)
        .animation(.spring(duration: 0.3), value: tasks.map(\.isCompleted))
        .animation(.spring(duration: 0.5), value: tasks.count) // Animate when tasks are added/removed
    }
    
    private func toggleTaskCompletion(_ task: Task) {
        withAnimation {
            task.isCompleted.toggle()
        }
    }
}

// Preview for regular stack with no overlapping
struct CardStackView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    
    init() {
        _tasks = Query(sort: [
            SortDescriptor(\Task.order, order: .forward),
            SortDescriptor(\Task.createdAt, order: .forward)
        ])
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(tasks) { task in
                    TaskCardView(task: task) {
                        withAnimation {
                            task.isCompleted.toggle()
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// Preview helper to demonstrate the 3D stack modifier directly
struct CustomStack3DPreview: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    
    init() {
        _tasks = Query(sort: [
            SortDescriptor(\Task.order, order: .forward),
            SortDescriptor(\Task.createdAt, order: .forward)
        ])
    }
    
    var body: some View {
        ScrollView {
            // Reserve space for all cards (minus their overlap)
            let totalHeight = CGFloat(tasks.count) * 140 - CGFloat(tasks.count - 1) * 40
            
            ZStack(alignment: .top) {
                Color.clear.frame(height: totalHeight)
                
                VStack(spacing: 0) {
                    ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                        TaskCardView(task: task) {
                            withAnimation {
                                task.isCompleted.toggle()
                            }
                        }
                        // Using a different overlap amount (40) to demonstrate customization
                        .card3DStack(index: index, totalCount: tasks.count, overlapAmount: 40)
                    }
                }
            }
            .padding(.top)
        }
        .scrollIndicators(.hidden)
    }
}

#Preview("Regular Stack Layout (No Overlap)") {
    CardStackView()
        .modelContainer(TaskMockData.createPreviewContainer())
}

#Preview("3D Overlapping Cards") {
    CustomStack3DPreview()
        .modelContainer(TaskMockData.createPreviewContainer())
}

#Preview("Container with 3D Stack") {
    TaskCardsContainerView()
        .modelContainer(TaskMockData.createPreviewContainer())
}



struct ScrollingCarouselView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    @State private var screenHeight: CGFloat = 0
    @State private var cardWidth: CGFloat = 0
    @State var dragOffset: CGFloat = 0
    @State var activeCardIndex = 0
    let heightScale = 0.4
    let cardAspectRadio = 1.5
    
    init(category: TaskCategory? = nil) {
        if let category = category {
            let categoryString = category.rawValue
            _tasks = Query(filter: #Predicate<Task> { task in
                task.categoryRaw == categoryString
            }, sort: [
                SortDescriptor(\Task.order, order: .forward),
                SortDescriptor(\Task.createdAt, order: .forward)
            ])
        } else {
            _tasks = Query(sort: [
                SortDescriptor(\Task.order, order: .forward),
                SortDescriptor(\Task.createdAt, order: .forward)
            ])
        }
    }
    
    var body: some View {

        GeometryReader { reader in
            ZStack {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                    // TaskCardView(task: task, onToggleComplete: () -> Void)
                    TaskCardView(task: task) {
                        toggleTaskCompletion(task)
                    }
                    .frame(width: cardWidth, height: screenHeight * heightScale)
                    .shadow(radius: 12)
                    .zIndex(-Double(index))
                    .offset(y: cardOffset(for: index))
                    .gesture(
                        DragGesture().onChanged{ value in
                            self.dragOffset = value.translation.height
                        }.onEnded{ value in
                            let threshold = screenHeight * 0.2
                            
                            withAnimation {
                                if value.translation.height < -threshold {
                                    activeCardIndex = min(activeCardIndex + 1, tasks.count - 1)
                                } else if value.translation.height > threshold {
                                    activeCardIndex = max(activeCardIndex - 1, 0)
                                }
                            }
                            
                            withAnimation {
                                dragOffset = 0
                            }

                        }
                    )
                    
                }
            }
            .onAppear() {
                screenHeight = reader.size.height
                cardWidth = screenHeight * heightScale * cardAspectRadio
            }
            .offset(x: 30, y: 0)
        }
    }
                        
    func cardOffset(for index: Int) -> CGFloat {
        let adjustedIndex = index - activeCardIndex
        let cardSpacing: CGFloat = 60
        let initialOffset = cardSpacing * CGFloat(adjustedIndex)
        let progress = min(abs(dragOffset)/(screenHeight/2), 1)
        let maxCardMovement = cardSpacing
        
        if adjustedIndex < 0 {
            if dragOffset > 0 && index == activeCardIndex - 1 {
                let distanceToMove = (initialOffset + screenHeight) * progress
                return -screenHeight + distanceToMove
            } else {
                return -screenHeight
            }
        } else if index > activeCardIndex {
            let distanceToMove = progress * maxCardMovement
            return initialOffset - (dragOffset < 0 ? distanceToMove : -distanceToMove)
        } else {
            if dragOffset < 0 {
                return dragOffset
            } else {
                let distanceToMove = maxCardMovement * progress
                return initialOffset - (dragOffset < 0 ? distanceToMove : -distanceToMove)
            }
        }
    }
    
    private func toggleTaskCompletion(_ task: Task) {
        withAnimation {
            task.isCompleted.toggle()
        }
    }
}


#Preview("Scrolling Carousel") {
    ScrollingCarouselView()
        .modelContainer(TaskMockData.createPreviewContainer())
}

