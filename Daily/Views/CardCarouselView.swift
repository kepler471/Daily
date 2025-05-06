//
//  CardCarouselView.swift
//  Daily
//
//  Created by Stelios Georgiou on 06/05/2025.
//

import SwiftUI
import SwiftData

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

