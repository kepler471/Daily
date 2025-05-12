//
//  Todo.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import Foundation
import SwiftData
import UserNotifications
import SwiftUI

// MARK: - Enums

/// Represents the category of a todo in the Daily app
/// - required: Todos that must be completed daily
/// - suggested: Optional todos for daily completion
enum TodoCategory: String, Codable, Hashable {
    case required
    case suggested
}

// MARK: - Todo Model

/// Represents a daily todo that can be tracked and completed
/// 
/// The `Todo` model is the core data structure used in the Daily app. It stores
/// information about todos that need to be completed, including their title,
/// order, category, completion status, and creation time.
@Model
final class Todo {
    // MARK: Properties

    /// Stable UUID for the todo (used for notification identification)
    var uuid: UUID

    /// The title or description of the todo
    var title: String

    /// The display order for the todo (lower numbers appear first)
    var order: Int

    /// The raw string representation of the todo category (for SwiftData compatibility)
    var categoryRaw: String

    /// Optional scheduled time for when the todo should be completed
    var scheduledTime: Date?

    /// Whether the todo has been completed
    var isCompleted: Bool

    /// When the todo was created
    var createdAt: Date
    
    // MARK: Computed Properties
    
    /// The category of the todo (required or suggested)
    var category: TodoCategory {
        get {
            TodoCategory(rawValue: categoryRaw) ?? .required
        }
        set {
            categoryRaw = newValue.rawValue
        }
    }
    
    // MARK: Initializers
    
    /// Creates a new todo with the specified attributes
    /// - Parameters:
    ///   - title: The title of the todo
    ///   - order: The display order (lower numbers appear first)
    ///   - category: The category of the todo (default: .required)
    ///   - scheduledTime: Optional scheduled time for the todo
    init(title: String, order: Int, category: TodoCategory = .required, scheduledTime: Date? = nil) {
        self.uuid = UUID()
        self.title = title
        self.order = order
        self.categoryRaw = category.rawValue
        self.scheduledTime = scheduledTime
        self.isCompleted = false
        self.createdAt = Date()
    }

    /// Empty initializer required by SwiftData for model creation
    init() {
        self.uuid = UUID()
        self.title = ""
        self.order = 0
        self.categoryRaw = TodoCategory.required.rawValue
        self.scheduledTime = nil
        self.isCompleted = false
        self.createdAt = Date()
    }

    // MARK: - Notification Scheduling

    /// Schedule a notification for this todo
    /// - Parameter settings: The settings manager to check notification preferences
    @MainActor
    func scheduleNotification(settings: SettingsManager) async {
        await NotificationManager.shared.scheduleNotification(for: self, settings: settings)
    }

    /// Cancel any notification for this todo
    @MainActor
    func cancelNotification() async {
        await NotificationManager.shared.cancelNotification(for: self)
    }
}
