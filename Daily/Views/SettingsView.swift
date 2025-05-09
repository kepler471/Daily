//
//  SettingsView.swift
//  Daily
//
//  Created with Claude Code.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    
    // State for UI interactions
    @State private var showingLaunchExplanation = false
    @State private var showingRestoreConfirmation = false
    @State private var showingLoginItemsInstructions = false
    
    var body: some View {
        Form {
            Section(header: Text("General")) {
                HStack {
                    Toggle("Launch at Login", isOn: $settingsManager.launchAtLogin)
                        .toggleStyle(.switch)
                    
                    Spacer()
                    
                    Button(action: {
                        // Show SwiftUI explanation popup
                        showingLaunchExplanation = true
                    }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingLaunchExplanation, arrowEdge: .top) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Launch at Login")
                                .font(.headline)
                            
                            Text("When enabled, Daily will automatically start when you log in to your Mac. This ensures your tasks are always available throughout your workday.")
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                            
                            Button("OK") {
                                showingLaunchExplanation = false
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding()
                        .frame(width: 300, height: 150)
                    }
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
                    // Show SwiftUI confirmation dialog
                    showingRestoreConfirmation = true
                }
                .foregroundColor(.red)
                .confirmationDialog(
                    "Restore Default Settings",
                    isPresented: $showingRestoreConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Cancel", role: .cancel) { }
                    
                    Button("Restore", role: .destructive) {
                        settingsManager.resetToDefaults()
                    }
                } message: {
                    Text("This will reset all settings to their default values. Are you sure you want to continue?")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 300)
        .onAppear {
            // Set up notification observer for login items instructions
            NotificationCenter.default.addObserver(forName: .showLoginItemInstructions,
                                                  object: nil,
                                                  queue: .main) { _ in
                showingLoginItemsInstructions = true
            }
        }
        .alert("Launch at Login", isPresented: $showingLoginItemsInstructions) {
            Button("Open Login Items") {
                // Open Login Items preferences
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!)
            }
            
            Button("OK", role: .cancel) { }
        } message: {
            Text("To enable 'Launch at Login', open System Settings, go to 'General > Login Items', and add Daily to the list of applications.")
        }
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