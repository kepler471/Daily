//
//  CloseButtonView.swift
//  Daily
//
//  Created by Stelios Georgiou on 11/05/2025.
//

import SwiftUI

/// A reusable minimalist close button for use across the app
struct CloseButtonView: View {
    // MARK: - Properties
    
    /// The action to perform when the button is tapped
    var action: () -> Void
    
    /// The size of the button (defaults to 28)
    var size: CGFloat = 28
    
    /// The font size for the X icon (defaults to 14)
    var iconSize: CGFloat = 14
    
    /// The foreground color of the X (defaults to secondary color)
    var foregroundColor: Color = .secondary
    
    /// The background color of the button (defaults to light gray)
    var backgroundColor: Color = Color.gray.opacity(0.15)
    
    /// Top padding value (defaults to 16)
    var topPadding: CGFloat = 16
    
    /// Leading padding value (defaults to 16)
    var leadingPadding: CGFloat = 16
    
    // MARK: - Body
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundColor(foregroundColor)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(backgroundColor)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel("Close")
        .padding([.top], topPadding)
        .padding([.leading], leadingPadding)
    }
}

// MARK: - View Extension

extension View {
    /// Adds a close button as an overlay in the top-left corner
    /// - Parameters:
    ///   - action: The action to perform when the button is tapped
    ///   - size: The size of the button (defaults to 28)
    ///   - iconSize: The font size for the X icon (defaults to 14)
    ///   - foregroundColor: The foreground color of the X (defaults to secondary color)
    ///   - backgroundColor: The background color of the button (defaults to light gray)
    ///   - topPadding: Top padding value (defaults to 16)
    ///   - leadingPadding: Leading padding value (defaults to 16)
    /// - Returns: A view with the close button overlay
    func withCloseButton(
        action: @escaping () -> Void,
        size: CGFloat = 28,
        iconSize: CGFloat = 14,
        foregroundColor: Color = .secondary,
        backgroundColor: Color = Color.gray.opacity(0.15),
        topPadding: CGFloat = 16,
        leadingPadding: CGFloat = 16
    ) -> some View {
        self.overlay(
            CloseButtonView(
                action: action,
                size: size,
                iconSize: iconSize,
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
                topPadding: topPadding,
                leadingPadding: leadingPadding
            ),
            alignment: .topLeading
        )
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .edgesIgnoringSafeArea(.all)
        
        VStack {
            Text("Content behind close button")
                .padding()
        }
        .frame(width: 300, height: 200)
        .background(Color.white)
        .cornerRadius(12)
        .withCloseButton {
            print("Close button tapped")
        }
    }
}