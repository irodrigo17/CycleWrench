import SwiftUI

struct SettingsView: View {
    @Environment(CloudSyncStatus.self) private var cloudStatus
    @Environment(\.dismiss) private var dismiss
    @AppStorage("distanceUnit") private var distanceUnit = "km"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Distance", selection: $distanceUnit) {
                        ForEach(DistanceUnit.allCases) { unit in
                            Text(unit.title).tag(unit.rawValue)
                        }
                    }
                } header: {
                    Text("Units")
                } footer: {
                    Text("Applies to every bike, service record, and component estimate. Changing units converts readings without changing the original history.")
                }
                Section {
                    Label(cloudStatus.accountMessage, systemImage: "icloud")
                    if cloudStatus.isSyncing { ProgressView("Syncing…") }
                    if let date = cloudStatus.lastUpload {
                        LabeledContent("Last upload this session") { Text(date, style: .relative) }
                    } else if AppPersistence.usesCloud {
                        Text("No upload confirmed this session.").font(.caption).foregroundStyle(.secondary)
                    }
                    if let date = cloudStatus.lastDownload {
                        LabeledContent("Last download this session") { Text(date, style: .relative) }
                    }
                    if let error = cloudStatus.accountError {
                        Text(error).font(.caption).foregroundStyle(.red)
                    }
                    if let error = cloudStatus.syncError {
                        Text(error).font(.caption).foregroundStyle(.red)
                    }
                    if AppPersistence.usesCloud {
                        Button("Check iCloud account") {
                            Task { await cloudStatus.refreshAccount() }
                        }
                    }
                } header: {
                    Text("iCloud")
                } footer: {
                    Text(AppPersistence.usesCloud
                        ? "Bikes and history sync privately through your iCloud account. Changes save on this device first. Let uploads finish before deleting the app; only uploaded data can be restored after reinstalling."
                        : "This build stores data locally. Run a signed Xcode build with CloudKit configured to enable iCloud on a simulator or device.")
                }
                Section("Your data") {
                    NavigationLink("Import service log") { ImportServiceLogView() }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
