import XCTest
@testable import TimeTrackerApp // Replace TimeTrackerApp with your actual module name

class TimeTrackerTests: XCTestCase {

    var timeTracker: TimeTracker!

    override func setUpWithError() throws {
        try super.setUpWithError()
        timeTracker = TimeTracker()
        // Note: TimeTracker initializes its own DataLogger. For these tests,
        // we are testing TimeTracker's logic, not its interaction with a specific
        // state of DataLogger (which would be an integration test).
        // We will clear any logs created by TimeTracker's internal DataLogger after tests if necessary.
        // For now, TimeTracker's stopTracking also clears taskName.
        let dataLogger = DataLogger() // Create a separate instance for cleanup if needed
        dataLogger.clearAllLogs()
    }

    override func tearDownWithError() throws {
        // Clean up any logs that might have been created if TimeTracker's DataLogger wrote something.
        let dataLogger = DataLogger()
        dataLogger.clearAllLogs()
        timeTracker = nil
        try super.tearDownWithError()
    }

    func testStartTracking() {
        timeTracker.taskName = "Test Task"
        timeTracker.startTracking()

        XCTAssertTrue(timeTracker.isTracking, "TimeTracker should be tracking.")
        XCTAssertNotNil(timeTracker.startTime, "Start time should be set.")
        XCTAssertEqual(timeTracker.elapsedTime, 0, "Elapsed time should be 0 at the start.")
    }

    func testStopTracking() {
        timeTracker.taskName = "Test Task"
        timeTracker.startTracking()

        let expectation = self.expectation(description: "Wait for elapsedTime to advance")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { // Wait for 1.1 seconds
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.5, handler: nil)

        let loggedEntry = timeTracker.stopTracking()

        XCTAssertFalse(timeTracker.isTracking, "TimeTracker should not be tracking after stop.")
        XCTAssertNotNil(loggedEntry, "stopTracking should return a log entry.")
        XCTAssertGreaterThan(loggedEntry!.duration, 0.9, "Elapsed time (duration) should be greater than 0.9s.")
        XCTAssertLessThan(loggedEntry!.duration, 1.5, "Elapsed time (duration) should be less than 1.5s (accounting for delay).")
        XCTAssertEqual(timeTracker.taskName, "", "Task name should be empty after stopping.")
        // Also, elapsedTime on the tracker itself should reflect the final duration.
        XCTAssertEqual(timeTracker.elapsedTime, loggedEntry!.duration, "Tracker's elapsedTime should match the logged duration.")
    }

    func testElapsedTimeUpdate() {
        timeTracker.taskName = "Test Task For ElapsedTime"
        timeTracker.startTracking()

        let expectation = self.expectation(description: "Wait for timer to update elapsedTime")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.5, handler: nil)

        // Timer should have fired and updated elapsedTime automatically.
        // No need to call updateElapsedTime() directly unless testing that specific call.
        XCTAssertGreaterThan(timeTracker.elapsedTime, 0.9, "Elapsed time should be greater than 0.9s after internal timer fires.")
        XCTAssertLessThan(timeTracker.elapsedTime, 1.5, "Elapsed time should be less than 1.5s.")

        _ = timeTracker.stopTracking() // Stop tracking to clean up the timer and log.
    }

    func testStartTracking_emptyTaskName() {
        timeTracker.taskName = "" // Ensure task name is empty
        timeTracker.startTracking()

        XCTAssertFalse(timeTracker.isTracking, "TimeTracker should not start tracking with an empty task name.")
        XCTAssertNil(timeTracker.startTime, "Start time should not be set if tracking didn't start.")
    }

    func testStopTracking_whenNotTracking() {
        // Ensure not tracking
        XCTAssertFalse(timeTracker.isTracking)

        let result = timeTracker.stopTracking()

        XCTAssertNil(result, "stopTracking should return nil if called when not tracking.")
        XCTAssertFalse(timeTracker.isTracking, "isTracking should remain false.")
    }
}
