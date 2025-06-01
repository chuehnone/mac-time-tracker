import Foundation
import UserNotifications
import Combine // For ObservableObject

class BreakReminder: ObservableObject {
    // UserDefaults Keys
    static let userDefaultsKeyIsEnabled = "breakReminderIsEnabled"
    static let userDefaultsKeyInterval = "breakReminderInterval"

    @Published var isReminderEnabled: Bool = true {
        didSet {
            saveSettings()
            if isReminderEnabled {
                startReminders()
            } else {
                stopReminders()
            }
        }
    }

    @Published var timeUntilNextBreak: TimeInterval

    var breakInterval: TimeInterval = 50 * 60 { // Default 50 minutes
        didSet {
            saveSettings()
            // If reminders are active, restart with new interval
            if isReminderEnabled {
                startReminders()
            }
        }
    }

    private var reminderTimer: Timer?

    init() {
        // Initialize timeUntilNextBreak with breakInterval to avoid 0 at start if not loaded
        self.timeUntilNextBreak = self.breakInterval
        loadSettings() // Load saved settings, which might update timeUntilNextBreak
        requestNotificationPermission()

        if isReminderEnabled {
            startReminders()
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
            if granted {
                print("Notification permission granted.")
            } else {
                print("Notification permission denied.")
                // Optionally, update UI or state to reflect that reminders can't be shown
                DispatchQueue.main.async {
                    // self.isReminderEnabled = false // Or handle this more gracefully
                }
            }
        }
    }

    func startReminders() {
        print("Starting break reminders. Interval: \(breakInterval)s, Time until next: \(timeUntilNextBreak)s")
        // Ensure isReminderEnabled is true, as this might be called directly
        if !self.isReminderEnabled { self.isReminderEnabled = true }


        reminderTimer?.invalidate() // Invalidate existing timer

        // If timeUntilNextBreak has elapsed or is at default, reset to full interval
        if timeUntilNextBreak <= 0 || timeUntilNextBreak == breakInterval {
             timeUntilNextBreak = breakInterval
        }
        // Otherwise, continue from the current countdown

        reminderTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }

    func stopReminders() {
        print("Stopping break reminders.")
         // Ensure isReminderEnabled is false, as this might be called directly
        if self.isReminderEnabled { self.isReminderEnabled = false }

        reminderTimer?.invalidate()
        reminderTimer = nil
        // Optionally reset timeUntilNextBreak or leave it as is for visual feedback
        // timeUntilNextBreak = breakInterval // Reset to full interval for display
    }

    @objc private func updateTimer() {
        guard isReminderEnabled else {
            stopReminders() // Should already be stopped if isReminderEnabled is false
            return
        }

        if timeUntilNextBreak > 0 {
            timeUntilNextBreak -= 1
        } else {
            scheduleBreakNotification()
            timeUntilNextBreak = breakInterval // Reset for the next cycle
        }
    }

    func scheduleBreakNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Break Time!"
        content.body = "Time to take a short break and stretch."
        content.sound = UNNotificationSound.default

        // Schedule immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UUID().uuidString // Unique ID for the request
        let notificationRequest = UNNotificationRequest(identifier: request, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(notificationRequest) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Break notification scheduled.")
            }
        }
    }

    private func loadSettings() {
        let defaults = UserDefaults.standard
        // Check if the key exists to avoid overwriting 'true' with default 'false' if not set
        if defaults.object(forKey: BreakReminder.userDefaultsKeyIsEnabled) != nil {
            self.isReminderEnabled = defaults.bool(forKey: BreakReminder.userDefaultsKeyIsEnabled)
        } else {
            // If no setting saved, default to true
            self.isReminderEnabled = true
        }

        let savedInterval = defaults.double(forKey: BreakReminder.userDefaultsKeyInterval)
        if savedInterval > 0 { // Ensure it's a valid interval
            self.breakInterval = savedInterval
        }
        // Initialize timeUntilNextBreak based on loaded settings
        self.timeUntilNextBreak = self.isReminderEnabled ? self.breakInterval : 0
        print("Loaded settings: isReminderEnabled=\(isReminderEnabled), breakInterval=\(breakInterval)")
    }

    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(isReminderEnabled, forKey: BreakReminder.userDefaultsKeyIsEnabled)
        defaults.set(breakInterval, forKey: BreakReminder.userDefaultsKeyInterval)
        print("Saved settings: isReminderEnabled=\(isReminderEnabled), breakInterval=\(breakInterval)")
    }

    // Call this if the user manually wants to reset the current break timer
    func resetCurrentBreakTimer() {
        if isReminderEnabled {
            timeUntilNextBreak = breakInterval
            print("User reset current break timer to \(breakInterval)s.")
        }
    }
}
