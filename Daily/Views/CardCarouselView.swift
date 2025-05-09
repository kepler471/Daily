//
//  CardCarouselView.swift
//  Daily
//
//  Created by Stelios Georgiou on 06/05/2025.
//

import SwiftUI
import SwiftData

/// A scrollable carousel view that displays task cards in a vertically scrollable stack
/// allowing users to swipe through their tasks with a drag gesture
struct ScrollingCarouselView: View {
    // MARK: - Properties
    
    /// Model context for saving task changes
    @Environment(\.modelContext) private var modelContext
    
    /// Query for retrieving tasks from SwiftData
    @Query private var tasks: [Task]
    
    /// The height of the screen/container
    @State private var screenHeight: CGFloat = 0
    
    /// The calculated width of each card
    @State private var cardWidth: CGFloat = 0
    
    /// The current vertical drag offset while gesturing
    @State var dragOffset: CGFloat = 0
    
    /// The index of the currently active (visible) card
    @State var activeCardIndex = 0
    
    /// Height scale factor for cards relative to the screen height
    let heightScale = 0.4
    
    /// Aspect ratio for card width calculation
    let cardAspectRadio = 1.5
    
    // MARK: - Initialization
    
    /// Initialize the carousel with an optional task category filter
    /// - Parameter category: The task category to filter by, or nil for all tasks
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
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { reader in
            ZStack {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
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
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Task \(index + 1) of \(tasks.count): \(task.title)")
                    .accessibilityHint("Swipe up or down to navigate between tasks")
                }
            }
            .onAppear() {
                screenHeight = reader.size.height
                cardWidth = screenHeight * heightScale * cardAspectRadio
            }
            .offset(x: 30, y: 0)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculates the vertical offset for a card at the given index
    /// - Parameter index: The index of the card in the tasks array
    /// - Returns: The vertical offset position for the card
    func cardOffset(for index: Int) -> CGFloat {
        let adjustedIndex = index - activeCardIndex
        let cardSpacing: CGFloat = 60
        let initialOffset = cardSpacing * CGFloat(adjustedIndex)
        let progress = min(abs(dragOffset)/(screenHeight/2), 1)
        let maxCardMovement = cardSpacing
        
        if adjustedIndex < 0 {
            // Cards that should be off-screen above the current card
            if dragOffset > 0 && index == activeCardIndex - 1 {
                let distanceToMove = (initialOffset + screenHeight) * progress
                return -screenHeight + distanceToMove
            } else {
                return -screenHeight
            }
        } else if index > activeCardIndex {
            // Cards that are below the current card
            let distanceToMove = progress * maxCardMovement
            return initialOffset - (dragOffset < 0 ? distanceToMove : -distanceToMove)
        } else {
            // The active card
            if dragOffset < 0 {
                return dragOffset
            } else {
                let distanceToMove = maxCardMovement * progress
                return initialOffset - (dragOffset < 0 ? distanceToMove : -distanceToMove)
            }
        }
    }
    
    /// Toggles the completion state of a task
    /// - Parameter task: The task to toggle completion for
    private func toggleTaskCompletion(_ task: Task) {
        withAnimation {
            task.isCompleted.toggle()
        }
    }
}

// MARK: - Previews

#Preview("Scrolling Carousel") {
    ScrollingCarouselView()
        .modelContainer(TaskMockData.createPreviewContainer())
}

