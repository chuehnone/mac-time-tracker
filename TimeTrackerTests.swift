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

    // MARK: - New Test Cases

    func testStartTracking_calledMultipleTimes_sameTask() {
        timeTracker.taskName = "Repeat Task"
        timeTracker.startTracking()

        let initialStartTime = timeTracker.startTime
        XCTAssertNotNil(initialStartTime, "Initial start time should not be nil.")
        XCTAssertEqual(timeTracker.elapsedTime, 0, "Elapsed time should be 0 initially.")

        // Call startTracking() again immediately
        timeTracker.startTracking()

        XCTAssertTrue(timeTracker.isTracking, "TimeTracker should still be tracking.")
        XCTAssertEqual(timeTracker.startTime, initialStartTime, "Start time should not change on subsequent calls to startTracking if already tracking.")
        // Elapsed time might advance very slightly due to processing, check it's still very small.
        XCTAssertLessThanOrEqual(timeTracker.elapsedTime, 0.1, "Elapsed time should remain close to 0.")

        // Optional: Wait a very short moment to ensure the original timer is running
        let expectation = self.expectation(description: "Wait for timer to confirm it's running")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.3, handler: nil)

        XCTAssertGreaterThan(timeTracker.elapsedTime, 0.1, "Elapsed time should have advanced, confirming timer is running from initial start.")

        _ = timeTracker.stopTracking()
    }

    func testStartTracking_calledMultipleTimes_differentTask() {
        timeTracker.taskName = "Task One"
        timeTracker.startTracking()

        let taskOneStartTime = timeTracker.startTime
        XCTAssertNotNil(taskOneStartTime, "Task One start time should not be nil.")

        // Attempt to start a different task while the first is running
        timeTracker.taskName = "Task Two" // This change will be ignored by startTracking if already tracking
        timeTracker.startTracking()

        XCTAssertTrue(timeTracker.isTracking, "TimeTracker should still be tracking.")
        // Current TimeTracker.startTracking() has a guard: `guard !taskName.isEmpty, !isTracking else { return }`
        // This means if it's already tracking, it just returns. The taskName property remains "Task Two"
        // but the *active* tracking session is still for "Task One".
        // If the requirement was to PREVENT changing taskName while tracking, that would be a UI/ViewModel concern.
        // The model here allows taskName to be changed, but startTracking() won't restart.

        // The taskName property of TimeTracker would have been updated to "Task Two" by the assignment.
        // However, the *running* task context (startTime, original taskName for logging) is from "Task One".
        // The stopTracking method uses the timeTracker.taskName *at the moment of stopping*.
        // This might be a point of discussion for desired behavior.
        // The current implementation of stopTracking uses `self.taskName` (which would be "Task Two").
        // Let's adjust assertions based on current `startTracking` and `stopTracking` behavior.

        // With current implementation:
        // 1. Start "Task One" -> isTracking = true, startTime set, internal task is "Task One"
        // 2. Set taskName = "Task Two"
        // 3. Call startTracking() -> returns immediately because isTracking is true.
        // 4. Active timer is still for "Task One" (original startTime).
        // 5. stopTracking() is called. It uses `self.taskName` (which is "Task Two") but `self.startTime` (from "Task One").

        XCTAssertEqual(timeTracker.startTime, taskOneStartTime, "Start time should still be from Task One.")

        let loggedEntry = timeTracker.stopTracking()
        XCTAssertNotNil(loggedEntry, "A task entry should be logged.")
        XCTAssertEqual(loggedEntry?.taskName, "Task Two", "Logged task name should be 'Task Two' as taskName property was changed before stop.")
        XCTAssertEqual(loggedEntry?.startTime, taskOneStartTime, "Logged start time should be from 'Task One'.")
    }

    func testStopTracking_calledMultipleTimes() {
        timeTracker.taskName = "Test Task Stop Multiple"
        timeTracker.startTracking()

        let expectation = self.expectation(description: "Wait for a short delay")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.2, handler: nil)

        let firstLoggedEntry = timeTracker.stopTracking()
        XCTAssertNotNil(firstLoggedEntry, "First stop should produce a log entry.")
        XCTAssertFalse(timeTracker.isTracking, "TimeTracker should not be tracking after the first stop.")
        let elapsedTimeAfterFirstStop = timeTracker.elapsedTime
        XCTAssertGreaterThan(elapsedTimeAfterFirstStop, 0.05, "Elapsed time should be > 0.05s after first stop.")

        // Call stopTracking() again
        let secondLoggedEntry = timeTracker.stopTracking()
        XCTAssertNil(secondLoggedEntry, "Second stop should not produce a new log entry if not tracking.")
        XCTAssertFalse(timeTracker.isTracking, "TimeTracker should still not be tracking.")
        XCTAssertEqual(timeTracker.elapsedTime, elapsedTimeAfterFirstStop, "Elapsed time should not change after second stop if not tracking.")

        // Verify DataLogger only has one entry from this test.
        // This requires DataLogger to be cleaned before this test or to check its state carefully.
        // setUpWithError already calls clearAllLogs.
        let dataLogger = DataLogger() // Use a new instance to check logs
        let tasks = dataLogger.loadTasks()
        XCTAssertEqual(tasks.count, 1, "There should be only one task logged from this test method.")
        XCTAssertEqual(tasks.first?.id, firstLoggedEntry?.id, "The logged task should be the one from the first stop.")
    }

    func testClearTaskName_whenTracking() {
        timeTracker.taskName = "Active Task"
        timeTracker.startTracking()

        // Current implementation of clearTaskName:
        // func clearTaskName() {
        //    self.taskName = ""
        //    if !isTracking { // Only resets elapsedTime if not tracking
        //        self.elapsedTime = 0
        //    }
        // }
        // So, taskName *will* be cleared, but tracking continues with original context.
        // The logged task name on stop will be empty.

        timeTracker.clearTaskName()

        XCTAssertEqual(timeTracker.taskName, "", "TaskName should be cleared by clearTaskName().")
        XCTAssertTrue(timeTracker.isTracking, "TimeTracker should still be tracking.")

        let loggedEntry = timeTracker.stopTracking()
        XCTAssertNotNil(loggedEntry)
        XCTAssertEqual(loggedEntry?.taskName, "", "Logged task name should be empty as it was cleared mid-tracking.")
    }

    func testClearTaskName_whenNotTracking() {
        timeTracker.taskName = "Idle Task"
        timeTracker.elapsedTime = 100 // Set some dummy elapsed time
        XCTAssertFalse(timeTracker.isTracking, "TimeTracker should not be tracking.")

        timeTracker.clearTaskName()

        XCTAssertEqual(timeTracker.taskName, "", "TaskName should be empty.")
        XCTAssertEqual(timeTracker.elapsedTime, 0, "Elapsed time should be reset to 0 when not tracking and clearing task name.")
    }
}
