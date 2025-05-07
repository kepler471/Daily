//
//  CardStackLayout.swift
//  Daily
//
//  Created using Claude Code.
//  Custom layout for overlapping stack of cards.
//

import SwiftUI

/// A custom layout for creating stacked cards with configurable offsets
struct CardStackLayout: Layout {
    /// The vertical offset between each card in the stack
    var verticalOffset: (Int) -> CGFloat
    
    /// Initialize with a constant vertical offset
    init(verticalOffset: CGFloat = 10) {
        self.verticalOffset = { _ in verticalOffset }
    }
    
    /// Initialize with a mapping function that takes the subview index and returns the vertical offset
    init(verticalOffsetForIndex: @escaping (Int) -> CGFloat) {
        self.verticalOffset = verticalOffsetForIndex
    }
    
    /// Calculate the size needed for the layout
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
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        guard !subviews.isEmpty else { return }
        
        // Iterate through subviews in reverse (bottom to top of the stack)
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