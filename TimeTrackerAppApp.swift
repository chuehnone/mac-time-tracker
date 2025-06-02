import SwiftUI

@main
struct TimeTrackerAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No main window needed for a menu bar app,
        // but a Settings scene can be useful.
        Settings {
            EmptyView() // Placeholder for future settings
        }
    }
}
