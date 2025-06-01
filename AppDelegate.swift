import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    private var timeTracker: TimeTracker!
    private var breakReminder: BreakReminder!
    private var dataLogger: DataLogger! // Instance for data logging service
    private var settingsWindow: NSWindow? // To manage the settings window instance

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            // Try to set SF Symbol "timer"
            if let timerImage = NSImage(systemSymbolName: "timer", accessibilityDescription: "Timer Icon") {
                button.image = timerImage
            } else if let clockImage = NSImage(systemSymbolName: "clock", accessibilityDescription: "Clock Icon") {
                // Fallback to "clock" if "timer" is not available
                button.image = clockImage
            } else {
                // Fallback to a text title if symbols are not available
                button.title = "T"
            }
            button.action = #selector(togglePopover(_:))
            button.target = self // Ensure target is set
        }

        // Create the menu
        let menu = NSMenu()

        // Add "Settings..." menu item
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettingsWindow(_:)), keyEquivalent: ",")) // Using comma as a common shortcut

        // Add Separator
        menu.addItem(NSMenuItem.separator())

        // Add "Quit" menu item
        let quitMenuItem = NSMenuItem(title: "Quit TimeTrackerApp", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitMenuItem)

        statusItem?.menu = menu

        // Initialize services
        timeTracker = TimeTracker()
        breakReminder = BreakReminder()
        dataLogger = DataLogger() // Initialize DataLogger

        // Create the popover with TimeTrackerView
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 270) // Adjusted to TimeTrackerView's actual height
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: TimeTrackerView(timeTracker: self.timeTracker, breakReminder: self.breakReminder))
        self.popover = popover
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        // Ensure popover and statusItem button exist
        guard let popover = self.popover, let button = self.statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(sender)
            // Optional: NSApp.deactivate() or other focus handling if needed
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true) // Make app active to ensure popover can receive events
        }
    }

    @objc func openSettingsWindow(_ sender: AnyObject?) {
        if settingsWindow == nil {
            let settingsView = SettingsView(breakReminder: self.breakReminder, dataLogger: self.dataLogger)
            let hostingController = NSHostingController(rootView: settingsView)

            let window = NSWindow(contentViewController: hostingController)
            window.title = "TimeTrackerApp Settings"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false // Important to allow reopening
            window.center() // Center the window

            settingsWindow = window
            // Set a delegate to clear settingsWindow when closed, so it can be reopened.
            window.delegate = self
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true) // Bring the app to the front
    }
}

// Add NSWindowDelegate conformance to handle window closing
extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if (notification.object as? NSWindow) == settingsWindow {
            settingsWindow = nil // Allow the window to be recreated
            print("Settings window closed and cleared.")
        }
    }
}
