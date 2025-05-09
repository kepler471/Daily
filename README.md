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

- iOS support with iCloud sync
- Widget support for macOS
- Smart task scheduling and prioritization
- Progress trends and analytics

## Contributing

Contributions are welcome! Feel free to submit pull requests or create issues for bugs and feature requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.