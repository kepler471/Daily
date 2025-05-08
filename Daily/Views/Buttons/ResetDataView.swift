//
//  ResetDataView.swift
//  Daily
//
//  Created by Stelios Georgiou on 06/05/2025.
//

import SwiftUI
import SwiftData

struct ResetDataView: View {
    @Environment(\.modelContext) private var modelContext
    var onReset: (() -> Void)?
    
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
    }
    
    private func resetData() {
        // Delete all tasks
        do {
            try modelContext.delete(model: Task.self)
            
            // Re-add sample data
            try TaskMockData.createSampleTasks(in: modelContext)
            
            // Call the onReset callback if provided
            onReset?()
        } catch {
            print("Error resetting data: \(error)")
        }
    }
}

#Preview {
    ResetDataView()
        .padding()
}
