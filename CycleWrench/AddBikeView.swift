import SwiftUI
import SwiftData

struct AddBikeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var odometer = "0"
    @State private var unit: String
    @State private var saveError: String?
    let onSave: (Bike) -> Void

    init(defaultUnit: String, onSave: @escaping (Bike) -> Void) {
        _unit = State(initialValue: defaultUnit)
        self.onSave = onSave
    }

    private var distance: Double? {
        guard let value = Double(odometer), value.isFinite, value >= 0 else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Bike name", text: $name)
                TextField("Current odometer", text: $odometer).keyboardType(.decimalPad)
                Picker("Distance unit", selection: $unit) {
                    Text("Kilometers").tag("km")
                    Text("Miles").tag("mi")
                }
            }
            .navigationTitle("Add bike")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || distance == nil)
                }
            }
            .alert("Couldn’t add bike", isPresented: Binding(
                get: { saveError != nil }, set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: { Text(saveError ?? "Please try again.") }
        }
    }

    private func save() {
        guard let distance else { return }
        let bike = Bike(name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                        distanceUnit: unit, odometer: distance)
        context.insert(bike)
        do {
            try context.save()
            onSave(bike)
            dismiss()
        } catch {
            context.rollback()
            saveError = error.localizedDescription
        }
    }
}
