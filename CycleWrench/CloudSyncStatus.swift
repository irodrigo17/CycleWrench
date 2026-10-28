import CloudKit
import CoreData
import Observation

@MainActor
@Observable
final class CloudSyncStatus {
    var accountMessage = AppPersistence.usesCloud ? "Checking iCloud account…" : "Local storage in simulator"
    var accountAvailable = false
    var lastUpload: Date?
    var lastDownload: Date?
    var syncError: String?
    private var activeEvents: Set<UUID> = []

    var isSyncing: Bool { !activeEvents.isEmpty }

    func refreshAccount() async {
        guard AppPersistence.usesCloud else { return }
        do {
            let status = try await CKContainer(identifier: AppPersistence.cloudContainerID).accountStatus()
            accountAvailable = status == .available
            switch status {
            case .available: accountMessage = "iCloud account available"
            case .noAccount: accountMessage = "Sign in to iCloud in device Settings"
            case .restricted: accountMessage = "iCloud access is restricted"
            case .temporarilyUnavailable: accountMessage = "iCloud temporarily unavailable"
            case .couldNotDetermine: accountMessage = "Couldn’t check iCloud account"
            @unknown default: accountMessage = "iCloud status unavailable"
            }
        } catch {
            accountAvailable = false
            accountMessage = "Couldn’t check iCloud account"
            syncError = error.localizedDescription
        }
    }

    func handle(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else { return }
        if event.endDate == nil {
            activeEvents.insert(event.identifier)
            return
        }
        activeEvents.remove(event.identifier)
        guard event.succeeded else {
            syncError = event.error?.localizedDescription ?? "iCloud sync couldn’t finish. Changes remain on this device."
            return
        }
        switch event.type {
        case .export:
            lastUpload = event.endDate
            syncError = nil
        case .import:
            lastDownload = event.endDate
        case .setup: break
        @unknown default: break
        }
    }
}
