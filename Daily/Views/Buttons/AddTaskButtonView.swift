//
//  AddTaskView.swift
//  Daily
//
//  Created by Stelios Georgiou on 06/05/2025.
//

import SwiftUI
import SwiftData
import UserNotifications

/// A button view that triggers the task creation overlay
struct AddTaskButtonView: View {
    // MARK: - Properties

    /// Binding to control the presentation of the add task overlay
    @Binding var showingAddTask: Bool

    /// The foreground color of the plus icon (defaults to a darker secondary color for better contrast)
    var foregroundColor: Color = .secondary.opacity(0.8)

    /// The background color of the button (defaults to light gray with higher opacity for better contrast)
    var backgroundColor: Color = Color.gray.opacity(0.25)

    /// The width of the pill button (defaults to 100)
    var width: CGFloat = 100

    /// The height of the pill button (defaults to 36)
    var height: CGFloat = 36

    /// The font size for the plus icon (defaults to 24)
    var iconSize: CGFloat = 24

    // MARK: - Body

    var body: some View {
        // Add task button
        Button {
            showingAddTask = true
        } label: {
            HStack {
                Spacer()

                Image(systemName: "plus")
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundColor(foregroundColor)

                Spacer()
            }
            .frame(width: width, height: height)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Capsule())
        .focusable(false)
        .accessibilityLabel("Add new task")
    }
}

// MARK: - View Extension

extension View {
    /// Adds an add task button as an overlay in the top-right corner
    /// - Parameters:
    ///   - isPresented: Binding to control the presentation of the add task view
    ///   - foregroundColor: The foreground color of the plus icon (defaults to secondary color)
    ///   - backgroundColor: The background color of the button (defaults to light gray)
    ///   - width: The width of the pill button (defaults to 100)
    ///   - height: The height of the pill button (defaults to 36)
    ///   - iconSize: The font size for the plus icon (defaults to 24)
    ///   - topPadding: Top padding value (defaults to 16)
    ///   - trailingPadding: Trailing padding value (defaults to 16)
    /// - Returns: A view with the add task button overlay
    func withAddTaskButton(
        isPresented: Binding<Bool>,
        foregroundColor: Color = .secondary.opacity(0.8),
        backgroundColor: Color = Color.gray.opacity(0.95),
        width: CGFloat = 100,
        height: CGFloat = 36,
        iconSize: CGFloat = 24,
        topPadding: CGFloat = 16,
        trailingPadding: CGFloat = 16
    ) -> some View {
        self.overlay(
            AddTaskButtonView(
                showingAddTask: isPresented,
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
                width: width,
                height: height,
                iconSize: iconSize
            )
            .padding([.top], topPadding)
            .padding([.trailing], trailingPadding),
            alignment: .topTrailing
        )
    }
}

// MARK: - Previews
#Preview("Add Task Button") {
    struct PreviewWrapper: View {
        @State private var showingAddTask = false

        var body: some View {
            VStack(spacing: 20) {
                // Default button
                AddTaskButtonView(showingAddTask: $showingAddTask)

                // Custom colors and size
                AddTaskButtonView(
                    showingAddTask: $showingAddTask,
                    foregroundColor: .blue,
                    backgroundColor: Color.blue.opacity(0.1),
                    width: 150,
                    height: 40,
                    iconSize: 18
                )

                // Match system appearance
                ZStack {
                    Color.gray.opacity(0.1)
                        .edgesIgnoringSafeArea(.all)

                    VStack {
                        Text("Context example")
                            .padding()

                        AddTaskButtonView(showingAddTask: $showingAddTask)
                    }
                    .frame(width: 300, height: 200)
                    .background(Color.white)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("With Add Task Button Extension") {
    struct PreviewWrapper: View {
        @State private var showingAddTask = false

        var body: some View {
            ZStack {
                Color.gray.opacity(0.1)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    Text("Content with add task button")
                        .padding()
                }
                .frame(width: 300, height: 200)
                .background(Color.white)
                .cornerRadius(12)
                .withAddTaskButton(isPresented: $showingAddTask)
            }
        }
    }

    return PreviewWrapper()
}

#Preview("Dark Mode") {
    struct PreviewWrapper: View {
        @State private var showingAddTask = false

        var body: some View {
            VStack(spacing: 20) {
                Text("Dark Mode Preview")
                    .font(.headline)

                // Default button
                AddTaskButtonView(showingAddTask: $showingAddTask)

                // Custom colors
                AddTaskButtonView(
                    showingAddTask: $showingAddTask,
                    foregroundColor: .primary,
                    backgroundColor: Color.white.opacity(0.2)
                )

                // Example in context
                ZStack {
                    Color.black.opacity(0.9)
                        .edgesIgnoringSafeArea(.all)

                    VStack {
                        Text("Dark mode context")
                            .foregroundColor(.white)
                            .padding()

                        AddTaskButtonView(showingAddTask: $showingAddTask)
                    }
                    .frame(width: 300, height: 200)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                }
            }
            .padding()
            .preferredColorScheme(.dark)
        }
    }

    return PreviewWrapper()
}
