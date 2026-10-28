import SwiftUI

struct SettingsView: View {
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
