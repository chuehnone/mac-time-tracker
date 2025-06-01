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
}
