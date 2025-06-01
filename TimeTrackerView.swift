import SwiftUI

struct TimeTrackerView: View {
    @ObservedObject var timeTracker: TimeTracker
    @ObservedObject var breakReminder: BreakReminder // Added BreakReminder

    var body: some View {
        VStack(spacing: 12) { // Adjusted spacing
            // Task Tracking Section
            GroupBox("Task Tracking") {
                VStack(spacing: 10) {
                    TextField("Enter task name...", text: $timeTracker.taskName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(timeTracker.isTracking)
                        // Removed .padding(.horizontal) to use GroupBox padding

                    if timeTracker.isTracking {
                        Text("Tracking: \(timeTracker.taskName)")
                            .font(.headline)
                        Text(formattedElapsedTime(timeTracker.elapsedTime))
                            .font(.subheadline) // Slightly smaller for balance
                            .monospacedDigit()
                    } else if !timeTracker.taskName.isEmpty && timeTracker.elapsedTime > 0 {
                        Text("Last Task: \(timeTracker.taskName)")
                            .font(.headline)
                        Text("Duration: \(formattedElapsedTime(timeTracker.elapsedTime))")
                            .font(.subheadline)
                    } else {
                        Text("Enter a task to begin.")
                            .foregroundColor(.gray)
                    }

                    HStack(spacing: 10) {
                        Button(action: {
                            if timeTracker.isTracking {
                                _ = timeTracker.stopTracking()
                            } else {
                                timeTracker.startTracking()
                            }
                        }) {
                            Text(timeTracker.isTracking ? "Stop Tracking" : "Start Tracking")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(timeTracker.isTracking ? .red : .green)
                        .disabled(!timeTracker.isTracking && timeTracker.taskName.isEmpty)

                        if !timeTracker.isTracking && !timeTracker.taskName.isEmpty {
                            Button(action: {
                                timeTracker.clearTaskName()
                            }) {
                                Text("Clear Task")
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    // Removed .padding(.horizontal) to use GroupBox padding
                }
                .padding(.vertical, 8) // Padding inside GroupBox content
                .padding(.horizontal, 5)
            }
            .padding(.horizontal) // Padding for the GroupBox itself

            // Break Reminder Section
            GroupBox("Break Reminders") {
                VStack(spacing: 10) {
                    Toggle("Enable Break Reminders", isOn: $breakReminder.isReminderEnabled)
                        // Removed .padding(.horizontal)

                    if breakReminder.isReminderEnabled {
                        Text("Next break in: \(formattedElapsedTime(breakReminder.timeUntilNextBreak))")
                            .font(.subheadline)
                        Button("Take Break Now / Reset Timer") {
                            breakReminder.scheduleBreakNotification() // Notify immediately
                            breakReminder.resetCurrentBreakTimer()   // Reset timer
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Text("Break reminders are currently disabled.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8) // Padding inside GroupBox content
                .padding(.horizontal, 5)
            }
            .padding(.horizontal) // Padding for the GroupBox itself
        }
        .padding() // Overall padding for the VStack
        .frame(width: 300, height: 270) // Adjusted height for new section
    }

    // Using the same formatter for both elapsed time and break time for consistency
    private func formattedElapsedTime(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: interval) ?? "00:00:00"
    }
}

// Preview Provider for TimeTrackerView
struct TimeTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        let mockTimeTracker = TimeTracker()
        // mockTimeTracker.taskName = "Preview Task"
        // mockTimeTracker.isTracking = true
        // mockTimeTracker.elapsedTime = 150

        let mockBreakReminder = BreakReminder()
        // mockBreakReminder.isReminderEnabled = true
        // mockBreakReminder.timeUntilNextBreak = 30 * 60 // 30 minutes

        return TimeTrackerView(timeTracker: mockTimeTracker, breakReminder: mockBreakReminder)
    }
}
