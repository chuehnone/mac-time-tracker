import Foundation
import Combine // For ObservableObject

class TimeTracker: ObservableObject {
    @Published var taskName: String = ""
    @Published var isTracking: Bool = false
    @Published var startTime: Date?
    @Published var elapsedTime: TimeInterval = 0

    private var timer: Timer?
    private let dataLogger = DataLogger() // For logging tasks

    func startTracking() {
        guard !taskName.isEmpty, !isTracking else { return }

        isTracking = true
        startTime = Date()
        elapsedTime = 0

        // Invalidate any existing timer before starting a new one
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
    }

    // The TaskLogEntry struct is now defined in DataLogger.swift and is used for logging.
    // We ensure this class uses that definition when interacting with DataLogger.

    func stopTracking() -> TaskLogEntry? { // Return type changed to TaskLogEntry
        guard isTracking, let startTime = startTime else { return nil }

        isTracking = false
        timer?.invalidate()
        timer = nil

        // Calculate final elapsedTime before resetting startTime
        let endTime = Date()
        elapsedTime = endTime.timeIntervalSince(startTime)

        let entry = TaskLogEntry(id: UUID(),
                                 taskName: self.taskName,
                                 startTime: startTime,
                                 endTime: endTime,
                                 duration: self.elapsedTime)

        dataLogger.logTask(taskData: entry)

        // Reset taskName for the next task after logging
        self.taskName = ""

        return entry
    }

    func updateElapsedTime() {
        guard isTracking, let startTime = startTime else { return }
        elapsedTime = Date().timeIntervalSince(startTime)
    }

    // Call this method if you want to clear the task name from UI
    func clearTaskName() {
        self.taskName = ""
        // If not tracking, also reset elapsedTime display
        if !isTracking {
            self.elapsedTime = 0
        }
    }
}
