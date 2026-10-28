import SwiftUI
import SwiftData

struct CustomComponentEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var defaultAction = ServiceAction.serviced
    @State private var hasPosition = false
    @State private var restrictions = ComponentRestrictions()
    @State private var errorMessage: String?
    let onSave: (CustomComponent) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Component name", text: $name)
                Picker("Default action", selection: $defaultAction) {
                    ForEach(ServiceAction.loggableCases) { action in Text(action.title).tag(action) }
                }
                Toggle("Separate front and rear", isOn: $hasPosition)
                Section {
                    Picker("Power", selection: $restrictions.drive) {
                        ForEach(BikeConfiguration.Drive.allCases) { option in
                            Text(option == .unspecified ? "Any power type" : option.title).tag(option)
                        }
                    }
                    Picker("Suspension", selection: $restrictions.suspension) {
                        ForEach(BikeConfiguration.Suspension.allCases) { option in
                            Text(option == .unspecified ? "Any suspension" : option.title).tag(option)
                        }
                    }
                    Picker("Brakes", selection: $restrictions.brakes) {
                        ForEach(BikeConfiguration.Brakes.allCases) { option in
                            Text(option == .unspecified ? "Any brakes" : option.title).tag(option)
                        }
                    }
                } header: {
                    Text("Bike restrictions (optional)")
                } footer: {
                    Text(restrictions.isUnrestricted
                        ? "Available for all bikes. You can change the action when logging work."
                        : "Only shown for matching bikes. Unset bike options keep components available until you choose a setup. Existing history is kept.")
                }
            }
            .navigationTitle("Custom component")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        do {
                            let custom = try CustomComponentStore.add(name: name, defaultAction: defaultAction,
                                hasPosition: hasPosition, restrictions: restrictions, in: context)
                            onSave(custom)
                            dismiss()
                        } catch { errorMessage = error.localizedDescription }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Couldn’t add component", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "Please try again.") }
        }
    }
}
