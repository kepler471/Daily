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
    var category: TaskCategory
    var scheduledTime: Date?
    var isCompleted: Bool
    var createdAt: Date
    
    init(title: String, order: Int, category: TaskCategory = .required, scheduledTime: Date? = nil) {
        self.title = title
        self.order = order
        self.category = category
        self.scheduledTime = scheduledTime
        self.isCompleted = false
        self.createdAt = Date()
    }
}