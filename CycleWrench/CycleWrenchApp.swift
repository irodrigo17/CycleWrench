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
        .onReceive(NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .receive(on: RunLoop.main)) {
            cloudStatus.handle($0)
        }
    }

    private func openStore() {
        do {
            let opened = try AppPersistence.makeContainer()
            #if DEBUG
            if let encoded = ProcessInfo.processInfo.environment["CYCLEWRENCH_IMPORT_ARCHIVE"],
               let data = Data(base64Encoded: encoded) {
                let archive = try ServiceLogArchive.decode(data)
                let imported = try ServiceLogImporter.importArchive(archive, into: opened.mainContext)
                UserDefaults.standard.set(imported.bike.id.uuidString, forKey: "selectedBikeID")
                UserDefaults.standard.set(archive.distanceUnit, forKey: "distanceUnit")
            }
            #endif
            container = opened
            startupError = nil
        } catch {
            // Never replace a failed persistent store with an empty or in-memory store.
            startupError = error.localizedDescription
        }
    }
}
