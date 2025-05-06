//
//  TaskCardsContainerView.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import SwiftUI
import SwiftData

// Preference key to track scroll position
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct TaskCardsContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    @State private var scrollOffset: CGFloat = 0
    
    // Constants to control the overlap behavior
    private let baseOverlap: CGFloat = 30    // Base overlap when not scrolling
    private let minOverlap: CGFloat = 5      // Minimum overlap to maintain between cards
    private let maxOverlap: CGFloat = 80     // Maximum overlap between cards to compress them
    
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
                    // Reserve space for all cards (minus their average overlap)
                    // Each card is about 140px tall and we want to offset by the overlapping amount
                    if !tasks.isEmpty {
                        let totalHeight = CGFloat(tasks.count) * 140 - CGFloat(tasks.count - 1) * baseOverlap
                        Color.clear
                            .frame(height: totalHeight)
                    }
                }
                
                // GeometryReader to track scroll position
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scrollView")).minY)
                }
                .frame(height: 0)
                
                VStack(spacing: 0) {
                    ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                        TaskCardView(task: task) {
                            toggleTaskCompletion(task)
                        }
                        .zIndex(Double(tasks.count - index)) // Higher z-index for items at the top
                        .offset(y: offsetForCard(at: index)) // Dynamic offset based on scroll position
                        .rotation3DEffect(
                            .degrees(index == 0 ? 0 : -2), // Slight rotation for 3D effect
                            axis: (x: 1.0, y: 0.0, z: 0.0), // Rotate around X axis
                            anchor: .top // Pivot from the top
                        )
                        .scaleEffect(1.0 - CGFloat(index) * 0.01) // Subtle scaling to enhance 3D effect
                        .transition(
                            .asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale(scale: 0.9).combined(with: .opacity).combined(with: .offset(y: -20))
                            )
                        )
                        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 3 + CGFloat(index))
                    }
                    
                    // Empty view at the bottom for better UX when scrolling
                    Color.clear
                        .frame(height: 40)
                }
            }
            .padding(.top)
        }
        .coordinateSpace(name: "scrollView") // Named coordinate space for tracking scroll
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
        }
        .scrollIndicators(.hidden)
        .animation(.spring(duration: 0.3), value: tasks.map(\.isCompleted))
        .animation(.spring(duration: 0.5), value: tasks.count) // Animate when tasks are added/removed
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: scrollOffset) // Animate scroll changes
    }
    
    // Calculate the dynamic offset for each card based on its index and the current scroll position
    private func offsetForCard(at index: Int) -> CGFloat {
        if tasks.isEmpty { return 0 }
        
        // Card height and number of cards that can fit in the visible area
        let cardHeight: CGFloat = 140
        let viewportCardCapacity = 3 // Approximate number of fully visible cards
        
        // Normalize scroll position to a value between 0-1 that represents progress through the list
        let contentHeight = CGFloat(tasks.count) * cardHeight
        // Use a multiplier (3.0) to make the effect more pronounced with less scrolling
        let normalizedScroll = min(max(0, -scrollOffset / contentHeight * 3.0), 1)
        
        // Calculate a "focus point" - the card index that should be most visible based on scroll position
        // As you scroll down, this focus point moves down the list
        let focusPoint = normalizedScroll * CGFloat(max(0, tasks.count - viewportCardCapacity))
        
        // Calculate how far this card is from the current focus point
        let distanceFromFocus = abs(CGFloat(index) - focusPoint)
        
        // Cards at the focus point should have minimum overlap
        // Cards further away (above or below) should have increasing overlap
        // The rate of change should be higher for cards above the focus (they get hidden faster)
        let overlapFactor: CGFloat
        if CGFloat(index) < focusPoint {
            // Cards above the focus - compress them more aggressively
            overlapFactor = minOverlap + (distanceFromFocus * 1.5 * (maxOverlap - minOverlap) / CGFloat(tasks.count))
        } else {
            // Cards below the focus - more gradual compression
            overlapFactor = minOverlap + (distanceFromFocus * (maxOverlap - minOverlap) / CGFloat(tasks.count))
        }
        
        // Ensure overlap stays within defined bounds
        let clampedOverlap = min(max(minOverlap, overlapFactor), maxOverlap)
        
        // Calculate the final offset for this card
        return -clampedOverlap * CGFloat(index)
    }
    
    private func toggleTaskCompletion(_ task: Task) {
        withAnimation {
            task.isCompleted.toggle()
        }
    }
}

// Alternative Grid Layout Option
struct TaskCardsGridView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    
    let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 16)
    ]
    
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
            LazyVGrid(columns: columns, spacing: 16) {
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

// Alternative staggered layout option that can be enabled
extension TaskCardsContainerView {
    var staggeredBody: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                    TaskCardView(task: task) {
                        toggleTaskCompletion(task)
                    }
                    .offset(x: index % 2 == 0 ? -8 : 8)
                    .scaleEffect(task.isCompleted ? 0.95 : 1.0)
                }
                
                Color.clear
                    .frame(height: 40)
            }
            .padding(.top)
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    TaskCardsContainerView()
        .modelContainer(TaskMockData.createPreviewContainer())
}
