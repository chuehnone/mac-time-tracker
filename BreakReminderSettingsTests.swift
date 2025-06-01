import XCTest
@testable import TimeTrackerApp // Replace TimeTrackerApp with your actual module name

class BreakReminderSettingsTests: XCTestCase {

    var breakReminder: BreakReminder!
    // Use a specific suite for testing to avoid interfering with app's actual UserDefaults
    // However, BreakReminder directly uses UserDefaults.standard.
    // For these tests, we will manipulate UserDefaults.standard directly but ensure keys are cleaned up.
    // A refactor in BreakReminder to allow UserDefaults injection would be ideal for more robust tests.

    let testIsEnabledKey = BreakReminder.userDefaultsKeyIsEnabled
    let testIntervalKey = BreakReminder.userDefaultsKeyInterval

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Clear potentially conflicting keys before each test
        UserDefaults.standard.removeObject(forKey: testIsEnabledKey)
        UserDefaults.standard.removeObject(forKey: testIntervalKey)

        // BreakReminder loads from UserDefaults in its init()
        breakReminder = BreakReminder()
    }

    override func tearDownWithError() throws {
        // Clean up keys after each test
        UserDefaults.standard.removeObject(forKey: testIsEnabledKey)
        UserDefaults.standard.removeObject(forKey: testIntervalKey)
        breakReminder.stopReminders() // Stop any timers if running
        breakReminder = nil
        try super.tearDownWithError()
    }

    func testDefaultSettings() {
        // Test assumes default isReminderEnabled = true and default interval = 50*60
        // These defaults are set if no value exists in UserDefaults

        // Clear any existing keys to ensure defaults are applied on next init
        UserDefaults.standard.removeObject(forKey: testIsEnabledKey)
        UserDefaults.standard.removeObject(forKey: testIntervalKey)

        let newReminder = BreakReminder() // Loads defaults in init

        XCTAssertTrue(newReminder.isReminderEnabled, "Default isReminderEnabled should be true if no setting is saved.")
        XCTAssertEqual(newReminder.breakInterval, 50 * 60, "Default breakInterval should be 50 minutes (3000 seconds).")
    }

    func testSaveAndLoadIsEnabled_True() {
        breakReminder.isReminderEnabled = true // This setter also calls saveSettings()

        // Create a new instance, which will load settings in its init
        let newReminder = BreakReminder()
        XCTAssertTrue(newReminder.isReminderEnabled, "isReminderEnabled should be true after saving and reloading.")
    }

    func testSaveAndLoadIsEnabled_False() {
        breakReminder.isReminderEnabled = false // This setter also calls saveSettings()

        let newReminder = BreakReminder()
        XCTAssertFalse(newReminder.isReminderEnabled, "isReminderEnabled should be false after saving and reloading.")
    }

    func testSaveAndLoadBreakInterval() {
        let newInterval: TimeInterval = 30 * 60 // 30 minutes
        breakReminder.breakInterval = newInterval // This setter also calls saveSettings()

        // Create a new instance
        let newReminder = BreakReminder()
        XCTAssertEqual(newReminder.breakInterval, newInterval, "breakInterval should match the saved value after reloading.")
    }

    func testIsReminderEnabledToggle_StartsAndStopsTimer() {
        // Start with reminders disabled
        breakReminder.isReminderEnabled = false
        XCTAssertNil(breakReminder.reminderTimer, "Timer should be nil when reminders are disabled.")

        // Enable reminders
        breakReminder.isReminderEnabled = true
        // Timer might take a fraction of a second to schedule, but should be non-nil quickly.
        // For this test, direct check is okay, can add expectation for more robustness.
        XCTAssertNotNil(breakReminder.reminderTimer, "Timer should be created when reminders are enabled.")
        XCTAssertTrue(breakReminder.reminderTimer!.isValid, "Timer should be valid when reminders are enabled.")

        // Disable reminders again
        breakReminder.isReminderEnabled = false
        XCTAssertNil(breakReminder.reminderTimer, "Timer should be nil after disabling reminders again.")
    }

    func testBreakIntervalChange_RestartsTimerIfActive() {
        // Ensure reminders are active
        breakReminder.isReminderEnabled = true
        let oldTimer = breakReminder.reminderTimer
        XCTAssertNotNil(oldTimer, "Timer should exist.")

        // Change break interval
        breakReminder.breakInterval = 25 * 60 // 25 minutes

        let newTimer = breakReminder.reminderTimer
        XCTAssertNotNil(newTimer, "New timer should exist after interval change.")
        XCTAssertNotEqual(oldTimer, newTimer, "Timer should be a new instance after interval change if it was active.")
        XCTAssertTrue(newTimer!.isValid, "New timer should be valid.")
        XCTAssertEqual(breakReminder.timeUntilNextBreak, 25 * 60, "timeUntilNextBreak should be reset to the new interval.")
    }
}
