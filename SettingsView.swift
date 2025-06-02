import SwiftUI

struct SettingsView: View {
    @ObservedObject var breakReminder: BreakReminder
    var dataLogger: DataLogger // Pass the instance for path, or just the path string

    // State for stepper, converting TimeInterval (seconds) to Int (minutes)
    @State private var breakIntervalMinutes: Int

    // Min/max for break interval in minutes
    private let minIntervalMinutes = 5
    private let maxIntervalMinutes = 120

    init(breakReminder: BreakReminder, dataLogger: DataLogger) {
        self.breakReminder = breakReminder
        self.dataLogger = dataLogger
        // Initialize state from the breakReminder's current interval
        _breakIntervalMinutes = State(initialValue: Int(breakReminder.breakInterval / 60))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.largeTitle)
                .padding(.bottom)

            GroupBox("Break Reminder Settings") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Set how often you want to be reminded to take a break.")
                        .font(.callout)
                        .foregroundColor(.gray)

                    HStack {
                        Text("Break Interval:")
                        Stepper(value: $breakIntervalMinutes,
                                in: minIntervalMinutes...maxIntervalMinutes,
                                step: 1) {
                            // Label for the stepper value
                            Text("\(breakIntervalMinutes) minutes")
                        }
                        .onChange(of: breakIntervalMinutes) { newValue in
                            breakReminder.breakInterval = TimeInterval(newValue * 60)
                            // breakReminder.saveSettings() is called automatically by breakInterval's didSet
                            // If reminders are active, it will also restart with the new interval
                        }
                    }
                }
                .padding()
            }

            GroupBox("Data Settings") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your tracked tasks are saved locally on your computer.")
                        .font(.callout)
                        .foregroundColor(.gray)

                    Text("Log file directory:")
                        .font(.headline)

                    if let logDir = dataLogger.getLogFileDirectoryPath() {
                        Text(logDir)
                            .font(.caption) // Smaller font for path
                            .textSelection(.enabled) // Allow copying the path

                        Button("Show in Finder") {
                            if let url = dataLogger.getLogFileDirectoryURL() { // Need this method in DataLogger
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .padding(.top, 5)
                    } else {
                        Text("Log directory not available.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }

            Spacer() // Push content to the top
        }
        .padding()
        .frame(width: 450, height: 350) // Suitable size for a settings window
    }
}

// Preview Provider
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        // Create mock instances for preview
        let mockBreakReminder = BreakReminder()
        let mockDataLogger = DataLogger() // Assuming DataLogger() can be init'd for preview

        // Example: Set a value for break interval for preview
        // mockBreakReminder.breakInterval = 30 * 60 // 30 minutes

        return SettingsView(breakReminder: mockBreakReminder, dataLogger: mockDataLogger)
    }
}
