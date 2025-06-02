import Foundation

// This struct matches the definition that will also be used in TimeTracker.swift
struct TaskLogEntry: Codable, Identifiable {
    let id: UUID
    let taskName: String
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
}

class DataLogger {

    private var logFileURL: URL? {
        guard let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("Error: Could not find Application Support directory.")
            return nil
        }

        // Attempt to get bundle ID, fallback to a default if not available (e.g., during testing or if Info.plist isn't set up)
        let bundleID = Bundle.main.bundleIdentifier ?? "com.example.TimeTrackerApp.fallback"
        let logDir = appSupportDir.appendingPathComponent(bundleID, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating directory \(logDir): \(error)")
            return nil
        }

        return logDir.appendingPathComponent("tasks.json")
    }

    // Helper to get just the directory URL
    private func getLogDirectoryURL() -> URL? {
        guard let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("Error: Could not find Application Support directory.")
            return nil
        }
        let bundleID = Bundle.main.bundleIdentifier ?? "com.example.TimeTrackerApp.fallback"
        let logDir = appSupportDir.appendingPathComponent(bundleID, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true, attributes: nil)
            return logDir
        } catch {
            print("Error creating directory \(logDir): \(error)")
            return nil
        }
    }

    // Public method to get the directory path as a String
    public func getLogFileDirectoryPath() -> String? {
        return getLogDirectoryURL()?.path
    }

    // Public method to get the directory URL (for opening in Finder)
    public func getLogFileDirectoryURL() -> URL? {
        return getLogDirectoryURL()
    }

    func logTask(taskData: TaskLogEntry) {
        guard let fileURL = logFileURL else {
            print("Error: Log file URL is not available.")
            return
        }

        var tasks: [TaskLogEntry] = loadTasks() // Load existing tasks

        tasks.append(taskData) // Append new task

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601 // Use ISO8601 for dates
            if #available(macOS 10.13, *) { // Pretty printing available on newer macOS
                encoder.outputFormatting = .prettyPrinted
            }
            let jsonData = try encoder.encode(tasks)
            try jsonData.write(to: fileURL, options: .atomicWrite)
            print("Successfully logged task to: \(fileURL.path)")
        } catch {
            print("Error logging task: \(error)")
        }
    }

    func loadTasks() -> [TaskLogEntry] {
        guard let fileURL = logFileURL else {
            print("Error: Log file URL is not available for loading.")
            return []
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Log file does not exist at \(fileURL.path), starting with empty task list.")
            return []
        }

        do {
            let jsonData = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601 // Use ISO8601 for dates
            let tasks = try decoder.decode([TaskLogEntry].self, from: jsonData)
            return tasks
        } catch {
            print("Error loading tasks: \(error). Returning empty list.")
            return []
        }
    }

    // Optional: A method to clear all logs, could be useful for development/testing
    func clearAllLogs() {
        guard let fileURL = logFileURL else {
            print("Error: Log file URL is not available for clearing.")
            return
        }
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("Successfully cleared all logs from: \(fileURL.path)")
        } catch {
            print("Error clearing logs: \(error)")
        }
    }
}
