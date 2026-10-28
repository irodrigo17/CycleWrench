import SwiftUI
import SwiftData

struct CustomComponentEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var defaultAction = ServiceAction.serviced
    @State private var hasPosition = false
    @State private var errorMessage: String?
    let onSave: (ComponentDescriptor) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Component name", text: $name)
                Picker("Default action", selection: $defaultAction) {
                    ForEach(ServiceAction.loggableCases) { action in Text(action.title).tag(action) }
                }
                Toggle("Separate front and rear", isOn: $hasPosition)
                Section {
                    Text("Available in the component picker for all your bikes. You can change the action when logging work.")
                        .font(.footnote).foregroundStyle(.secondary)
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
                                hasPosition: hasPosition, in: context)
                            onSave(custom.descriptor)
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
