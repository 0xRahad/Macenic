import SwiftUI

@main
struct MacenicApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            DashboardView()
                .environment(appState)
        } label: {
            Image("MenuBarIcon")
        }
        .menuBarExtraStyle(.window)
    }
}
