//
//  AddTodoView.swift
//  Daily
//
//  Created by Stelios Georgiou on 06/05/2025.
//

import SwiftUI
import SwiftData
import UserNotifications

/// A view that provides the user interface for creating a new todo
// TODO: Wrap up this UI into a Todo Card like View
struct AddTodoView: View {
    // MARK: - Environment and State

    /// The model context for saving new todos
    @Environment(\.modelContext) private var modelContext

    /// The settings manager for notification preferences
    @EnvironmentObject private var settingsManager: SettingsManager

    /// The title of the new todo
    @State private var title = ""

    /// The selected category for the new todo
    @State private var selectedCategory: TodoCategory = .required

    /// Components for the custom time picker
    @State private var selectedHour = Calendar.current.component(.hour, from: Date()) % 12
    @State private var selectedMinute = Calendar.current.component(.minute, from: Date())
    @State private var isAM = Calendar.current.component(.hour, from: Date()) < 12

    /// Binding to control the visibility of this view
    @Binding var isPresented: Bool

    /// The scheduled time for the todo calculated from picker components
    private var scheduledTime: Date {
        let calendar = Calendar.current
        let hour = selectedHour + (isAM ? 0 : 12)
        let minute = selectedMinute

        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour == 12 && isAM ? 0 : (hour == 0 && !isAM ? 12 : hour)
        components.minute = minute

        return calendar.date(from: components) ?? Date()
    }
    
    /// Focus state for the title text field
    @FocusState private var isTitleFieldFocused: Bool
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // MARK: Background

            // Translucent blurred background overlay that can be tapped to dismiss
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    // Close the view when tapping on the background
                    isPresented = false
                }

            // MARK: Content

            VStack(spacing: 20) {
                // Title section
                Text("New Todo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                // MARK: Todo Card

                VStack(spacing: 20) {
                    // MARK: - Todo title

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        TextField("Todo name", text: $title)
                            .font(.system(size: 18, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                            .focused($isTitleFieldFocused)
                            .accessibilityIdentifier("todoTitleField")
                            .onSubmit {
                                if !title.isEmpty {
                                    addTodo()
                                    isPresented = false
                                }
                            }
                    }

                    // MARK: - Category selection

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Picker("", selection: $selectedCategory) {
                            Text("Required").tag(TodoCategory.required)
                            Text("Suggested").tag(TodoCategory.suggested)
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .padding(.vertical, 5)
                        .accessibilityIdentifier("categoryPicker")
                        .accessibilityLabel("Todo Category")
                    }

                    // MARK: - Time settings

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Scheduled Time")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        // Time selection components
                        HStack(alignment: .center, spacing: 4) {
                            // Hours picker
                            VStack(alignment: .center, spacing: 2) {
                                Picker("", selection: $selectedHour) {
                                    ForEach(1...12, id: \.self) { hour in
                                        Text("\(hour)").tag(hour == 12 ? 0 : hour)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 60)
                                .fixedSize()
                                .accessibilityLabel("Hour")
                            }

                            // Minutes picker
                            VStack(alignment: .center, spacing: 2) {
                                Picker("", selection: $selectedMinute) {
                                    ForEach(0..<60) { minute in
                                        Text(String(format: "%02d", minute)).tag(minute)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 60)
                                .fixedSize()
                                .accessibilityLabel("Minute")
                            }

                            // AM/PM picker
                            VStack(alignment: .center, spacing: 2) {
                                Picker("", selection: $isAM) {
                                    Text("AM").tag(true)
                                    Text("PM").tag(false)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 100)
                                .accessibilityLabel("AM or PM")
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                    }

                    Spacer()
                        .frame(height: 10)

                    // MARK: - Add button

                    Button {
                        addTodo()
                        isPresented = false
                    } label: {
                        Text("Add Todo")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(title.isEmpty ? Color.gray.opacity(0.5) : selectedCategory == .required ? Color.blue : Color.purple)
                            )
                            .contentShape(Rectangle())
                    }
                    .disabled(title.isEmpty)
                    .buttonStyle(.borderless)
                    .focusable(false)
                    .accessibilityIdentifier("addTodoButton")
                    .accessibilityHint("Creates a new todo with the provided details and scheduled time")
                }
                .padding(30)
                .background(
                    Rectangle()
                        .fill(.regularMaterial)
                        .opacity(0.9)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            selectedCategory == .required ? .blue.opacity(0.5) : .purple.opacity(0.5),
                                            selectedCategory == .required ? .teal.opacity(0.3) : .pink.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .contentShape(Rectangle())
                .allowsHitTesting(true) // Ensure taps on the card don't pass through
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
            .frame(maxWidth: 600)
        }
        .onAppear {
            // Auto-focus the title field when the view appears
            isTitleFieldFocused = true
        }
        .withCloseButton(
            action: { isPresented = false },
            size: 36,
            iconSize: 18
        )
    }
    
    // MARK: - Helper Methods
    
    // MARK: - Initialization

    /// Creates a new add todo view
    /// - Parameter isPresented: Binding to control the visibility of the view
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    /// Creates and saves a new todo with the current input values
    private func addTodo() {
        withAnimation {
            // Use the shared DataManager to create the todo
            let dataManager = DataManager.shared
            
            // Set the settings manager if needed
            if dataManager.settingsManager == nil {
                dataManager.setSettingsManager(settingsManager)
            }
            
            // Create the todo using the centralized manager
            _ = dataManager.addTodo(
                title: title,
                category: selectedCategory,
                scheduledTime: scheduledTime
            )
        }
    }
}

// MARK: - Previews

#Preview("Add Todo View") {
    AddTodoView(isPresented: .constant(true))
        .environmentObject(SettingsManager())
}
