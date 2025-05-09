//
//  CardStackLayout.swift
//  Daily
//
//  Created by Stelios Georgiou on 07/05/2025.
//  Custom layout for overlapping stack of cards.
//

import SwiftUI

/// A custom layout for creating stacked cards with configurable offsets
/// This layout allows precise control over the vertical stacking of cards
/// with either a constant offset or a function that varies offset by index
struct CardStackLayout: Layout {
    // MARK: - Properties
    
    /// The vertical offset between each card in the stack
    /// This is a function that takes an index and returns an offset value
    var verticalOffset: (Int) -> CGFloat
    
    // MARK: - Initialization
    
    /// Initialize with a constant vertical offset
    /// - Parameter verticalOffset: The constant offset to apply between all cards
    init(verticalOffset: CGFloat = 10) {
        self.verticalOffset = { _ in verticalOffset }
    }
    
    /// Initialize with a mapping function that takes the subview index and returns the vertical offset
    /// - Parameter verticalOffsetForIndex: A function that calculates offset based on index
    init(verticalOffsetForIndex: @escaping (Int) -> CGFloat) {
        self.verticalOffset = verticalOffsetForIndex
    }
    
    // MARK: - Layout Methods
    
    /// Calculate the size needed for the layout
    /// - Parameters:
    ///   - proposal: The proposed size for the layout
    ///   - subviews: The views to be arranged
    ///   - cache: Cache for layout calculations (unused in this implementation)
    /// - Returns: The size required to display all subviews with proper offsets
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        
        // Find the maximum width among all subviews
        let maxWidth = subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
        
        // Calculate the total height required
        var totalHeight: CGFloat = 0
        
        if let lastSubview = subviews.last {
            // Get the height of the last subview (fully visible)
            let lastSubviewHeight = lastSubview.sizeThatFits(.unspecified).height
            
            // Calculate the total vertical offset for all cards except the last one
            let totalOffset: CGFloat = (0..<subviews.count-1).reduce(0) { result, index in
                result + verticalOffset(index)
            }
            
            // Total height is the height of the last card plus all the offsets
            totalHeight = lastSubviewHeight + totalOffset
        }
        
        // Return the size required for the layout
        return CGSize(width: maxWidth, height: totalHeight)
    }
    
    /// Place the subviews within the layout
    /// - Parameters:
    ///   - bounds: The bounds in which to place the subviews
    ///   - proposal: The proposed size for each subview
    ///   - subviews: The views to be arranged
    ///   - cache: Cache for layout calculations (unused in this implementation)
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        guard !subviews.isEmpty else { return }
        
        // Iterate through subviews in reverse (bottom to top of the stack)
        // This ensures the first subview is on top visually
        var currentY: CGFloat = bounds.maxY
        
        for (index, subview) in subviews.enumerated().reversed() {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            // Calculate the position for this subview
            let x = bounds.midX - subviewSize.width / 2
            let y = currentY - subviewSize.height
            
            // Place the subview
            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: subviewSize.width, height: subviewSize.height)
            )
            
            // Update the y position for the next (upper) subview
            if index > 0 {
                currentY = y - verticalOffset(index - 1)
            }
        }
    }
}
