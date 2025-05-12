# Daily - Task Management for macOS

Daily is a macOS menu bar application designed to help you track and complete daily tasks with a simple, focused interface.

![Daily App Screenshot](Daily.png)

## Features

- **Menu Bar Integration**: Easily accessible from the macOS menu bar
- **Required and Suggested Tasks**: Categorize tasks based on importance
- **Focused Mode**: Emphasizes the top required task to help you focus
- **Task Completion Tracking**: Track daily task completion and reset progress
- **Scheduled Tasks**: Set specific times for tasks to be completed
- **Keyboard Shortcuts**: Quickly access app functionality without using the mouse

## Architecture

### Technology Stack

- **SwiftUI**: Used for all UI components and navigation
- **SwiftData**: Handles persistence of task data
- **AppKit Integration**: Used for menu bar functionality and system integration

### Core Components

#### Models

- **Task.swift**: Core data model representing a task with properties like title, category, completion status
- **Task+Extensions.swift**: Query predicates and ModelContext extensions for working with tasks

#### Managers

- **TaskResetManager**: Manages the daily reset of task completion statuses
- **SettingsManager**: Handles application settings and preferences
- **MenuBarManager**: Controls the menu bar functionality
- **KeyboardShortcutManager**: Manages global keyboard shortcuts

#### Views

- **MainView**: Primary interface showing both required and suggested task columns
- **TaskStackView**: Displays a stack of task cards for a specific category
- **TaskCardView**: Individual card showing task details and completion controls
- **FocusedTaskView**: Modal view focusing on the most important required task
- **CompletedTaskView**: Shows completed tasks with options to reopen them

#### App Structure

- **DailyApp.swift**: Main entry point that sets up the SwiftData model container and app configuration
- **AppDelegate.swift**: Handles AppKit integration and popover management

### Data Flow

1. The app initializes with `DailyApp.swift`, which creates the SwiftData container
2. Tasks are stored using SwiftData, enabling persistence across app launches
3. The `MainView` displays tasks grouped by category (Required/Suggested)
4. User interactions (like marking tasks complete) update the SwiftData model
5. Notifications are used to coordinate between different parts of the app, especially for menu bar actions

## Development Environment

### Requirements

- macOS 14.0+
- Xcode 16.0+
- Swift 6.0+

### Build and Run

To build and run the project:
1. Open `Daily.xcodeproj` in Xcode
2. Select "My Mac" as the destination device
3. Press Cmd+R or click the play button

### Common Commands

- **Building**: `xcodebuild -project Daily.xcodeproj -scheme Daily -configuration Debug -destination 'platform=macOS' -quiet build`
- **Testing**: `xcodebuild -project Daily.xcodeproj -scheme Daily -destination 'platform=macOS' -quiet test`
- **Clean**: `xcodebuild -project Daily.xcodeproj -scheme Daily -quiet clean`

### Keyboard Shortcuts

- **⌘+F**: Focus on top required task
- **⌘+N**: Add new task
- **⌘+C**: Show completed tasks
- **⌘+R**: Reset today's tasks
- **⌘+,**: Open settings

## Task Management System

Daily uses two categories of tasks:

1. **Required Tasks**: Must be completed daily, shown in the left column
2. **Suggested Tasks**: Optional tasks for daily completion, shown in the right column

Each day, task completion statuses can be reset to start fresh.

## Future Plans

### Current Priorities
- [ ] Notifications
- [ ] Focus timer
- [ ] Do not disturb activation, sync with timer
- [x] Stop the blank window opening on launch
- [ ] Show a more persistent notification
- [ ] Use a custom notification sound
- [ ] Can we include icons in the notification?
- [ ] Bring settings window to the front
- [ ] Settings sizing wraps to content, no need to scroll
- [ ] allow ⌘-w for window close, and try adding other common bindings for the app
- [ ] Seems like daily reset deletes all tasks?
- [ ] Enter from add task view should work

### Advanced Features
- [ ] Task Sorting and Filtering (by priority, due date, title)
- [ ] Search Functionality with history
- [ ] Expanded Keyboard Shortcuts with visual hints
- [ ] Statistics and Insights Dashboard
- [ ] Drag and Drop Task Reordering
- [ ] Task Reminders and Time Blocking
- [ ] Dark/Light Mode Toggle
- [ ] Task Tags and Color Coding
- [ ] Task Notes and Attachments
- [ ] Task Sharing and Collaboration

### Platform Expansion
- [ ] iOS support with iCloud sync
- [ ] Widget support for macOS
- [ ] Smart task scheduling and prioritization
- [ ] Progress trends and analytics
- [ ] Time sensitive notifications - https://developer.apple.com/design/human-interface-guidelines/managing-notifications

# Database Reset Utility
This utility is a
  crucial part of our notification system implementation as it helps handle database
  migration issues that may occur during development or app updates.

  Key features of the DatabaseResetUtility:

  1. Database Reset Functionality: It can safely delete corrupted database files when
  migration errors occur, allowing the app to create a fresh database.
  2. In-Memory Fallback: If the persistent storage completely fails, it provides an
  in-memory container as a last resort to prevent app crashes.
  3. Thorough Cleanup: It properly cleans up all related database files to ensure a complete
   reset.
  4. Safe Error Handling: Includes detailed error reporting and safe deletion operations.

  This is an important reliability enhancement for the Daily app, ensuring that users don't
  experience crashes due to database schema changes or corruption.
