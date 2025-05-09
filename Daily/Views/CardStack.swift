//
//  CardStack.swift
//  Daily
//
//  Created by Stelios Georgiou on 07/05/2025.
//  A container view that uses CardStackLayout for displaying cards with overlap effects.
//

import SwiftUI

/// A container view that displays subviews in a stack with configurable offset effects
/// Serves as a convenient wrapper around the CardStackLayout for easy use in SwiftUI views
struct CardStack<Content: View>: View {
    // MARK: - Properties
    
    /// The content of the stack
    let content: Content
    
    /// The vertical offset mapping function that determines spacing between cards
    private var verticalOffsetForIndex: (Int) -> CGFloat
    
    // MARK: - Initialization
    
    /// Initialize with a constant vertical offset
    /// - Parameters:
    ///   - verticalOffset: The constant spacing between cards
    ///   - content: The content view builder closure that provides the card views
    init(verticalOffset: CGFloat = 15, @ViewBuilder content: () -> Content) {
        self.verticalOffsetForIndex = { _ in verticalOffset }
        self.content = content()
    }
    
    /// Initialize with a custom mapping function for vertical offsets
    /// - Parameters:
    ///   - verticalOffsetForIndex: A function that determines offset based on index
    ///   - content: The content view builder closure that provides the card views
    init(verticalOffsetForIndex: @escaping (Int) -> CGFloat, @ViewBuilder content: () -> Content) {
        self.verticalOffsetForIndex = verticalOffsetForIndex
        self.content = content()
    }
    
    // MARK: - Body
    
    var body: some View {
        CardStackLayout(verticalOffsetForIndex: verticalOffsetForIndex) {
            content
        }
    }
}

// MARK: - View Modifiers

extension View {
    /// Apply a vertical offset to each card in the stack with a scalar value
    /// - Parameter offset: The constant offset value for card spacing
    /// - Returns: A view with the card stack layout applied
    func stackOffset(_ offset: CGFloat) -> some View {
        CardStack(verticalOffset: offset) {
            self
        }
    }
    
    /// Apply a vertical offset to each card in the stack with a mapping function
    /// - Parameter mappingFunction: A function that computes offset based on index
    /// - Returns: A view with the card stack layout applied
    func stackOffset(forIndex mappingFunction: @escaping (Int) -> CGFloat) -> some View {
        CardStack(verticalOffsetForIndex: mappingFunction) {
            self
        }
    }
}

// MARK: - Previews

struct CardStack_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            // Example of a basic card stack with constant offset
            CardStack(verticalOffset: 15) {
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 200, height: 100)
                        .overlay(
                            Text("Card \(index + 1)")
                                .foregroundColor(.black)
                        )
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Card \(index + 1)")
                }
            }
            .padding(.bottom, 50)
            
            // Example of a card stack with a custom mapping function
            CardStack(verticalOffsetForIndex: { index in
                return CGFloat(10 + index * 5)  // Increasing offset
            }) {
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 200, height: 100)
                        .overlay(
                            Text("Card \(index + 1)")
                                .foregroundColor(.black)
                        )
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Card \(index + 1)")
                }
            }
        }
        .padding()
    }
}
