import XCTest
@testable import TimeTrackerApp // Replace TimeTrackerApp with your actual module name

class DataLoggerTests: XCTestCase {

    var dataLogger: DataLogger!
    // For these tests, we'll use the default log file location and ensure it's cleaned up.
    // A more advanced setup might involve injecting a custom URL for the log file during tests.

    override func setUpWithError() throws {
        try super.setUpWithError()
        dataLogger = DataLogger()
        // Clean up any existing log file before each test to ensure a clean state
        dataLogger.clearAllLogs()
    }

    override func tearDownWithError() throws {
        // Clean up the log file after each test
        dataLogger.clearAllLogs()
        dataLogger = nil
        try super.tearDownWithError()
    }

    func testGetLogFileDirectoryPath() {
        let path = dataLogger.getLogFileDirectoryPath()
        XCTAssertNotNil(path, "Log file directory path should not be nil.")
        XCTAssertFalse(path!.isEmpty, "Log file directory path should not be empty.")

        // Check if the path seems reasonable (contains Application Support)
        XCTAssertTrue(path!.contains("Application Support"), "Path should typically be in Application Support.")
    }

    func testGetLogFileDirectoryURL() {
        let url = dataLogger.getLogFileDirectoryURL()
        XCTAssertNotNil(url, "Log file directory URL should not be nil.")
        XCTAssertTrue(url!.isFileURL, "URL should be a file URL.")
        XCTAssertTrue(url!.path.contains("Application Support"), "URL path should typically be in Application Support.")
    }

    func testLogAndLoadSingleTask() {
        let testID = UUID()
        let startTime = Date().addingTimeInterval(-3600) // 1 hour ago
        let endTime = Date()
        let taskEntry = TaskLogEntry(id: testID,
                                     taskName: "Test Log Task 1",
                                     startTime: startTime,
                                     endTime: endTime,
                                     duration: 3600)

        dataLogger.logTask(taskData: taskEntry)

        let loadedTasks = dataLogger.loadTasks()
        XCTAssertEqual(loadedTasks.count, 1, "Should load one task.")

        let firstLoadedTask = loadedTasks.first
        XCTAssertNotNil(firstLoadedTask, "First loaded task should not be nil.")
        XCTAssertEqual(firstLoadedTask?.id, testID, "Logged task ID should match.")
        XCTAssertEqual(firstLoadedTask?.taskName, "Test Log Task 1", "Logged task name should match.")
        XCTAssertEqual(firstLoadedTask?.startTime.timeIntervalSinceReferenceDate, startTime.timeIntervalSinceReferenceDate, accuracy: 0.001, "Start times should match.")
        XCTAssertEqual(firstLoadedTask?.endTime.timeIntervalSinceReferenceDate, endTime.timeIntervalSinceReferenceDate, accuracy: 0.001, "End times should match.")
        XCTAssertEqual(firstLoadedTask?.duration, 3600, "Logged task duration should match.")
    }

    func testLogMultipleTasks() {
        let taskEntry1 = TaskLogEntry(id: UUID(), taskName: "Task Alpha", startTime: Date(), endTime: Date(), duration: 100)
        let taskEntry2 = TaskLogEntry(id: UUID(), taskName: "Task Beta", startTime: Date().addingTimeInterval(100), endTime: Date().addingTimeInterval(200), duration: 100)

        dataLogger.logTask(taskData: taskEntry1)
        dataLogger.logTask(taskData: taskEntry2)

        let loadedTasks = dataLogger.loadTasks()
        XCTAssertEqual(loadedTasks.count, 2, "Should load two tasks.")

        // Verify tasks (order of loading is typically order of appending)
        XCTAssertEqual(loadedTasks[0].taskName, "Task Alpha")
        XCTAssertEqual(loadedTasks[1].taskName, "Task Beta")
    }

    func testLoadTasks_noFileExists() {
        // setUpWithError already calls clearAllLogs, so the file shouldn't exist
        let loadedTasks = dataLogger.loadTasks()
        XCTAssertTrue(loadedTasks.isEmpty, "Should return an empty array if no log file exists.")
    }

    func testClearAllLogs() {
        let taskEntry = TaskLogEntry(id: UUID(), taskName: "Temporary Task", startTime: Date(), endTime: Date(), duration: 50)
        dataLogger.logTask(taskData: taskEntry)

        var loadedTasks = dataLogger.loadTasks()
        XCTAssertFalse(loadedTasks.isEmpty, "Log should not be empty before clearing.")

        dataLogger.clearAllLogs()

        loadedTasks = dataLogger.loadTasks()
        XCTAssertTrue(loadedTasks.isEmpty, "Log should be empty after calling clearAllLogs.")
    }

    func testLogFileCreation() {
        // Ensure the directory exists after trying to get its URL (which creates it)
        guard let logDirURL = dataLogger.getLogFileDirectoryURL() else {
            XCTFail("Could not get log directory URL.")
            return
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: logDirURL.path), "Log directory should be created by getLogFileDirectoryURL.")

        // Log a task to create the actual file
        let taskEntry = TaskLogEntry(id: UUID(), taskName: "File Creation Test", startTime: Date(), endTime: Date(), duration: 10)
        dataLogger.logTask(taskData: taskEntry)

        // The logFileURL is private, but we can infer its location from getLogFileDirectoryURL
        let expectedFileURL = logDirURL.appendingPathComponent("tasks.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedFileURL.path), "tasks.json file should be created after logging a task.")
    }

    // MARK: - New Error Handling and Data Integrity Tests

    func testLoadTasks_corruptedJSONFile() {
        guard let logDirURL = dataLogger.getLogFileDirectoryURL() else {
            XCTFail("Could not get log directory URL for test setup.")
            return
        }
        let logFileURL = logDirURL.appendingPathComponent("tasks.json")

        // Write malformed JSON data
        // Example 1: Incomplete JSON
        // let corruptedJSONString = "[{\"id\":\"some-uuid\", \"taskName\":\"Test\""
        // Example 2: Type mismatch (taskName as number) - though Codable might handle some coercions or this might not be "corrupt" enough
        let corruptedJSONString = "[{\"id\":\"c6a9b3a0-4136-4c3f-951a-6c118234a20e\",\"taskName\":12345,\"startTime\":\"2023-01-01T12:00:00Z\",\"endTime\":\"2023-01-01T13:00:00Z\",\"duration\":3600}]"


        do {
            try corruptedJSONString.write(to: logFileURL, atomically: true, encoding: .utf8)
        } catch {
            XCTFail("Failed to write corrupted JSON to file for test: \(error)")
            return
        }

        let tasks = dataLogger.loadTasks()
        XCTAssertTrue(tasks.isEmpty, "loadTasks should return an empty array when JSON data is corrupted.")
        // Also good to check if the corrupted file was deleted or handled by DataLogger,
        // current implementation of loadTasks just prints an error and returns [].
        // If it tried to delete/rename a corrupt file, we'd test that too.
    }

    func testLoadTasks_emptyJSONFile_emptyString() {
        guard let logDirURL = dataLogger.getLogFileDirectoryURL() else {
            XCTFail("Could not get log directory URL for test setup.")
            return
        }
        let logFileURL = logDirURL.appendingPathComponent("tasks.json")
        let emptyJSONString = "" // Empty content

        do {
            try emptyJSONString.write(to: logFileURL, atomically: true, encoding: .utf8)
        } catch {
            XCTFail("Failed to write empty JSON to file for test: \(error)")
            return
        }

        let tasks = dataLogger.loadTasks()
        XCTAssertTrue(tasks.isEmpty, "loadTasks should return an empty array for an empty file.")
    }

    func testLoadTasks_emptyJSONFile_emptyArray() {
        guard let logDirURL = dataLogger.getLogFileDirectoryURL() else {
            XCTFail("Could not get log directory URL for test setup.")
            return
        }
        let logFileURL = logDirURL.appendingPathComponent("tasks.json")
        let emptyJSONArrayString = "[]" // Valid empty JSON array

        do {
            try emptyJSONArrayString.write(to: logFileURL, atomically: true, encoding: .utf8)
        } catch {
            XCTFail("Failed to write empty JSON array to file for test: \(error)")
            return
        }

        let tasks = dataLogger.loadTasks()
        XCTAssertTrue(tasks.isEmpty, "loadTasks should return an empty array for a file containing an empty JSON array.")
    }

    func testLoggedTasksHaveUniqueIDs() {
        // TaskLogEntry generates its own UUID upon initialization if not provided.
        // The DataLogger.logTask expects a TaskLogEntry.
        // TimeTracker creates entries like: TaskLogEntry(id: UUID(), taskName: ..., startTime: ..., ...)
        // So, we mimic that creation pattern.

        let date1 = Date()
        let entry1 = TaskLogEntry(id: UUID(), taskName: "Test Task A", startTime: date1, endTime: date1.addingTimeInterval(10), duration: 10)

        // Ensure a slight time difference for startTime if it matters for other logic, though UUID is the focus here.
        let date2 = date1.addingTimeInterval(1)
        let entry2 = TaskLogEntry(id: UUID(), taskName: "Test Task B", startTime: date2, endTime: date2.addingTimeInterval(20), duration: 20)

        dataLogger.logTask(taskData: entry1)
        dataLogger.logTask(taskData: entry2)

        let loadedTasks = dataLogger.loadTasks()
        XCTAssertEqual(loadedTasks.count, 2, "Should have logged and loaded two tasks.")

        // Check for distinct IDs
        XCTAssertNotEqual(loadedTasks[0].id, loadedTasks[1].id, "Logged tasks should have unique IDs.")

        // Also check if the correct tasks were loaded (sanity check)
        // Order is preserved by loadTasks/logTask
        XCTAssertTrue((loadedTasks[0].id == entry1.id && loadedTasks[1].id == entry2.id) || (loadedTasks[0].id == entry2.id && loadedTasks[1].id == entry1.id), "Loaded task IDs should match one of the original entry IDs")
        if loadedTasks[0].id == entry1.id {
             XCTAssertEqual(loadedTasks[0].taskName, "Test Task A")
             XCTAssertEqual(loadedTasks[1].taskName, "Test Task B")
        } else {
             XCTAssertEqual(loadedTasks[0].taskName, "Test Task B")
             XCTAssertEqual(loadedTasks[1].taskName, "Test Task A")
        }
    }
}
