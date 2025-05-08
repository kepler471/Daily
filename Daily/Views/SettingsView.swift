//
//  SettingsView.swift
//  Daily
//
//  Created with Claude Code.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    
    var body: some View {
        Form {
            Section(header: Text("General")) {
                HStack {
                    Toggle("Launch at Login", isOn: $settingsManager.launchAtLogin)
                        .toggleStyle(.switch)
                    
                    Spacer()
                    
                    Button(action: {
                        // Show explanation popup
                        let alert = NSAlert()
                        alert.messageText = "Launch at Login"
                        alert.informativeText = "When enabled, Daily will automatically start when you log in to your Mac. This ensures your tasks are always available throughout your workday."
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Section(header: Text("Task Reset")) {
                HStack {
                    Text("Reset tasks daily at:")
                    
                    Spacer()
                    
                    Picker("Reset Hour", selection: $settingsManager.resetHour) {
                        ForEach(0..<24) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 100)
                }
                
                Text("Tasks will reset automatically at the specified time each day.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Button("Restore Defaults") {
                    // Show confirmation dialog
                    let alert = NSAlert()
                    alert.messageText = "Restore Default Settings"
                    alert.informativeText = "This will reset all settings to their default values. Are you sure you want to continue?"
                    alert.addButton(withTitle: "Restore")
                    alert.addButton(withTitle: "Cancel")
                    
                    let response = alert.runModal()
                    if response == .alertFirstButtonReturn {
                        settingsManager.resetToDefaults()
                    }
                }
                .foregroundColor(.red)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 300)
    }
    
    /// Format hour for display in 12-hour format
    private func formatHour(_ hour: Int) -> String {
        let hourIn12Format = hour % 12 == 0 ? 12 : hour % 12
        let amPm = hour < 12 ? "AM" : "PM"
        return "\(hourIn12Format):00 \(amPm)"
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
}