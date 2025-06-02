# macOS Time Tracker & Break Reminder

A simple macOS menu bar application to help you track time spent on tasks and remind you to take regular breaks.

## Features

*   **Menu Bar Integration:** Runs discreetly in the macOS menu bar.
*   **Time Tracking:**
    *   Enter a task name and start/stop the timer.
    *   Live display of elapsed time for the current task.
*   **Data Persistence:**
    *   Completed tasks (name, start time, end time, duration) are automatically saved.
*   **Break Reminders:**
    *   Receive native macOS notifications to take breaks at configurable intervals.
    *   See a countdown to your next break.
*   **Settings:**
    *   Customize the break reminder interval.
    *   View the location of your task log data and open it in Finder.

## Prerequisites

*   **macOS:** Version 12.0 or later (adjust if a different deployment target was set during development).
*   **Xcode:** Version 14.0 or later (or the version used for development).

## How to Build and Run

1.  **Clone the Repository:**
    ```bash
    git clone <YOUR_REPOSITORY_URL>
    cd <YOUR_REPOSITORY_DIRECTORY>
    ```
    (Replace `<YOUR_REPOSITORY_URL>` with the URL you used to clone and `<YOUR_REPOSITORY_DIRECTORY>` with the name of the folder created.)

2.  **Open in Xcode:**
    *   Locate the `TimeTrackerApp.xcodeproj` file (or your project's `.xcodeproj` file) in the cloned directory.
    *   Double-click to open it in Xcode.
3.  **Select Scheme and Destination:**
    *   In Xcode, ensure the `TimeTrackerApp` scheme (or your project's scheme name) is selected.
    *   Choose "My Mac" (or your Mac's name) as the run destination.
4.  **Run the Application:**
    *   Click the "Play" button (▶) in the Xcode toolbar, or select "Product" > "Run" from the menu.
    *   The application icon (default is a timer symbol) will appear in your macOS menu bar.

## Running Tests

This project includes a suite of unit tests to verify the core logic of the application. To run these tests:

1.  **Open the Project in Xcode:**
    *   Open the `TimeTrackerApp.xcodeproj` file.

2.  **Navigate to the Test Navigator:**
    *   In the left sidebar of Xcode, click on the **Test Navigator** icon (it looks like a diamond or a sideways play button).

3.  **Run Tests:**
    *   **All Tests:** To run all unit tests, click the play button (▶) located next to the `TimeTrackerAppTests` target at the top of the Test Navigator.
    *   **Specific Test Classes or Methods:** You can also run tests for individual classes or specific test methods by clicking the play button that appears next to their names in the Test Navigator.
    *   **Keyboard Shortcut:** Alternatively, you can run all tests using the keyboard shortcut **Cmd+U** (or by selecting "Product" > "Test" from the Xcode menu).

4.  **View Test Results:**
    *   Xcode will display the test results in the Test Navigator. Green checkmarks indicate passing tests, while red 'x's indicate failures.
    *   You can click on individual tests to see more details or console output in the debug area.

## Data Storage

*   Tracked task data is stored locally in a JSON file located at:
    `~/Library/Application Support/<YourAppBundleID>/tasks.json`
    *   **Note:** Replace `<YourAppBundleID>` with the actual bundle identifier of the application.
    *   During development, if the bundle ID isn't explicitly set, it might default to something like `com.example.TimeTrackerApp` or a name derived from your Xcode project. You can find the bundle identifier in Xcode under your project's target settings ("General" > "Identity" > "Bundle Identifier"). The `DataLogger.swift` file also has a fallback `com.example.TimeTrackerApp.fallback` if the bundle ID cannot be determined at runtime, and `SettingsView` displays the actual path used.

## Directory Structure (Simplified)

This shows a typical layout. Your project might group files differently (e.g., into `Models`, `Views`, `Controllers` folders).

```
<repository_directory>/
├── TimeTrackerApp/  # Main application source code and resources folder
│   ├── AppDelegate.swift       # Manages app lifecycle, menu bar item, popover, settings window
│   ├── TimeTrackerAppApp.swift # Main SwiftUI App struct
│   ├── TimeTracker.swift       # Logic for time tracking (Model/ObservableObject)
│   ├── DataLogger.swift        # Logic for saving/loading task data
│   ├── BreakReminder.swift     # Logic for break notifications & settings persistence
│   ├── TimeTrackerView.swift   # SwiftUI View for the popover UI
│   ├── SettingsView.swift      # SwiftUI View for the settings window UI
│   └── Assets.xcassets       # App icons, etc.
├── TimeTrackerAppTests/    # Unit tests (if created)
│   ├── TimeTrackerTests.swift
│   ├── DataLoggerTests.swift
│   └── BreakReminderSettingsTests.swift
├── TimeTrackerApp.xcodeproj/ # Xcode project file
└── README.md                 # This file
```

(Note: The directory structure above is a conceptual representation. The actual project might have files like `Info.plist` directly under `TimeTrackerApp/` or group Swift files into subdirectories like `Models`, `Views`, etc.)
