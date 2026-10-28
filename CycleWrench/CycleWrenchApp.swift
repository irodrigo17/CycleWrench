import SwiftUI
import SwiftData
import CoreData

@main
struct CycleWrenchApp: App {
    var body: some Scene {
        WindowGroup { PersistenceRootView() }
    }
}

private struct PersistenceRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var container: ModelContainer?
    @State private var startupError: String?
    @State private var cloudStatus = CloudSyncStatus()

    var body: some View {
        Group {
            if let container {
                MaintenanceLogView()
                    .modelContainer(container)
                    .environment(cloudStatus)
            } else if let startupError {
                ContentUnavailableView {
                    Label("Couldn’t open your data", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text(startupError)
                } actions: {
                    Button("Retry", action: openStore)
                }
            } else {
                ProgressView("Opening your bikes…")
            }
        }
        .task {
            if container == nil { openStore() }
            await cloudStatus.refreshAccount()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                Task { await cloudStatus.refreshAccount() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)) {
            cloudStatus.handle($0)
        }
    }

    private func openStore() {
        do {
            container = try AppPersistence.makeContainer()
            startupError = nil
        } catch {
            // Never replace a failed persistent store with an empty or in-memory store.
            startupError = error.localizedDescription
        }
    }
}
