//
//  Task.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/05/2025.
//

import Foundation
import SwiftData

enum TaskCategory: String, Codable, Hashable {
    case required
    case suggested
}

@Model
final class Task {
    var title: String
    var order: Int
    var categoryRaw: String
    var scheduledTime: Date?
    var isCompleted: Bool
    var createdAt: Date
    
    var category: TaskCategory {
        get {
            TaskCategory(rawValue: categoryRaw) ?? .required
        }
        set {
            categoryRaw = newValue.rawValue
        }
    }
    
    init(title: String, order: Int, category: TaskCategory = .required, scheduledTime: Date? = nil) {
        self.title = title
        self.order = order
        self.categoryRaw = category.rawValue
        self.scheduledTime = scheduledTime
        self.isCompleted = false
        self.createdAt = Date()
    }
    
    // SwiftData sometimes needs an empty initializer
    init() {
        self.title = ""
        self.order = 0
        self.categoryRaw = TaskCategory.required.rawValue
        self.scheduledTime = nil
        self.isCompleted = false
        self.createdAt = Date()
    }
}