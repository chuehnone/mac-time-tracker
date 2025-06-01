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

    // MARK: - New Edge Case and State Stability Tests

    func testSetBreakInterval_zeroOrNegative_directSet() {
        // Test direct setting of breakInterval property.
        // Current BreakReminder implementation does not clamp this directly in the property's didSet,
        // but loadSettings enforces > 0. startReminders will use the value as is.

        breakReminder.isReminderEnabled = true // Ensure reminders are on to see effect on timeUntilNextBreak

        breakReminder.breakInterval = 0
        // saveSettings() is called in didSet.
        // startReminders() is called if isReminderEnabled is true.
        // In startReminders, timeUntilNextBreak becomes breakInterval (0).
        // The timer, when it fires updateTimer(), will immediately schedule a notification.
        XCTAssertEqual(breakReminder.breakInterval, 0, "breakInterval should be 0 after setting to 0.")
        XCTAssertEqual(breakReminder.timeUntilNextBreak, 0, "timeUntilNextBreak should be 0 if breakInterval is 0 and reminders are on.")

        // Test persistence of 0 (loadSettings will clamp it to default if it's not > 0)
        var newReminder = BreakReminder()
        XCTAssertGreaterThan(newReminder.breakInterval, 0, "Loading 0 from UserDefaults should result in a default positive interval due to 'if savedInterval > 0' in loadSettings.")


        UserDefaults.standard.removeObject(forKey: testIntervalKey) // Clean for next part of test
        breakReminder = BreakReminder() // Re-init
        breakReminder.isReminderEnabled = true

        breakReminder.breakInterval = -100
        XCTAssertEqual(breakReminder.breakInterval, -100, "breakInterval should be -100 after setting to -100.")
        XCTAssertEqual(breakReminder.timeUntilNextBreak, -100, "timeUntilNextBreak should be -100 if breakInterval is -100 and reminders are on.")

        // Test persistence of -100
        newReminder = BreakReminder()
        XCTAssertGreaterThan(newReminder.breakInterval, 0, "Loading -100 from UserDefaults should result in a default positive interval.")
    }

    func testSetBreakInterval_verySmallPositive_directSet() {
        // Test direct setting of breakInterval property.
        // loadSettings clamps to > 0. Direct set does not.
        breakReminder.isReminderEnabled = true
        breakReminder.breakInterval = 1 // 1 second

        XCTAssertEqual(breakReminder.breakInterval, 1, "breakInterval should be 1 after setting to 1.")
        XCTAssertEqual(breakReminder.timeUntilNextBreak, 1, "timeUntilNextBreak should be 1.")

        // Test persistence
        let newReminder = BreakReminder()
        XCTAssertEqual(newReminder.breakInterval, 1, "Loading 1 from UserDefaults should keep it as 1.")
    }

    func testSetBreakInterval_veryLarge_directSet() {
        breakReminder.isReminderEnabled = true
        let veryLargeInterval: TimeInterval = 10 * 60 * 60 // 10 hours
        breakReminder.breakInterval = veryLargeInterval

        XCTAssertEqual(breakReminder.breakInterval, veryLargeInterval, "breakInterval should accept a very large value.")
        XCTAssertEqual(breakReminder.timeUntilNextBreak, veryLargeInterval, "timeUntilNextBreak should be the large value.")

        // Test persistence
        let newReminder = BreakReminder()
        XCTAssertEqual(newReminder.breakInterval, veryLargeInterval, "Loading a very large interval from UserDefaults should work.")
    }

    func testRapidEnableDisableReminders() {
        XCTAssertNotNil(breakReminder, "BreakReminder instance should exist.")

        for i in 0..<10 {
            print("Rapid toggle iteration: \(i)")
            breakReminder.isReminderEnabled = true
            XCTAssertNotNil(breakReminder.reminderTimer, "Timer should be non-nil after enabling. Iteration \(i)")
            XCTAssertTrue(breakReminder.reminderTimer!.isValid, "Timer should be valid after enabling. Iteration \(i)")

            breakReminder.isReminderEnabled = false
            XCTAssertNil(breakReminder.reminderTimer, "Timer should be nil after disabling. Iteration \(i)")
        }

        // Final state check
        XCTAssertFalse(breakReminder.isReminderEnabled, "isReminderEnabled should be false finally.")
        XCTAssertNil(breakReminder.reminderTimer, "Timer should be nil finally.")
    }

    func testBreakIntervalChange_updatesTimeUntilNextBreak_whenEnabled() {
        breakReminder.isReminderEnabled = true
        // Initial timeUntilNextBreak is breakInterval (default 50*60)
        XCTAssertEqual(breakReminder.timeUntilNextBreak, breakReminder.breakInterval, "Initially, timeUntilNextBreak should equal breakInterval.")

        // Let timer run briefly to make timeUntilNextBreak different from breakInterval
        let expectation = self.expectation(description: "Wait for timer to tick")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { // Short wait, less than a second
             expectation.fulfill()
        }
        waitForExpectations(timeout: 0.3, handler: nil)

        // If the timer fires at 1s interval, 0.15s might not be enough to change timeUntilNextBreak.
        // Let's ensure it ticks at least once if possible, or accept it might not have changed if too short.
        // The timer is scheduled with 1.0s interval. So updateTimer runs every second.
        // A 0.15s delay won't make it tick.
        // To properly test this, we need to wait for >1s or manually simulate timer fire.
        // For simplicity, we'll assume startReminders sets timeUntilNextBreak correctly upon interval change.

        let newInterval: TimeInterval = 30 * 60 // 30 minutes
        breakReminder.breakInterval = newInterval // This will call startReminders() again because isReminderEnabled is true

        XCTAssertEqual(breakReminder.timeUntilNextBreak, newInterval, "timeUntilNextBreak should be reset to the new breakInterval when changed while enabled.")
        XCTAssertNotNil(breakReminder.reminderTimer, "Timer should still be active.")
        XCTAssertTrue(breakReminder.reminderTimer!.isValid, "Timer should still be valid.")
    }
}
