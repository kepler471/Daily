//
//  ResetDataView.swift
//  Daily
//
//  Created by Stelios Georgiou on 06/05/2025.
//

import SwiftUI
import SwiftData

/// A button view that allows users to reset all data and recreate sample todos
struct ResetDataView: View {
    // MARK: - Properties
    
    /// The data manager for handling data reset operations
    @StateObject private var dataManager = DataManager.shared
    
    /// Optional callback that gets triggered after data reset
    var onReset: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        Button(action: resetData) {
            Image(systemName: "trash")
                .font(.footnote)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.red)
                )
        }
        #if os(macOS)
        .help("Reset all data to default")
        #endif
        .accessibilityLabel("Reset all data")
        .accessibilityHint("Deletes all todos and recreates sample data")
    }
    
    // MARK: - Data Operations
    
    /// Resets all data by delegating to the DataManager
    private func resetData() {
        Task {
            // Use the centralized data manager to reset all data
            let success = await dataManager.resetAllData(onReset: onReset)
            if !success {
                print("Failed to reset all data")
            }
        }
    }
}

// MARK: - Previews

#Preview {
    ResetDataView()
        .environmentObject(NotificationManager.shared)
        .padding()
}
