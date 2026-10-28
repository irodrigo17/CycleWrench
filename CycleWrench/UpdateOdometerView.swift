import SwiftUI
import SwiftData

struct UpdateOdometerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let bike: Bike
    let unit: String
    let onSave: () -> Void
    @State private var value: String
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool

    init(bike: Bike, current: Double, unit: String, onSave: @escaping () -> Void) {
        self.bike = bike
        self.unit = unit
        self.onSave = onSave
        _value = State(initialValue: String(current))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(bike.name) {
                    HStack {
                        TextField("Current odometer", text: $value)
                            .keyboardType(.decimalPad).focused($isFocused)
                            .accessibilityLabel("Current odometer")
                        Text(unit).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Update odometer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            guard let distance = Double(value) else { return }
                            try BikeStore.updateOdometer(bike, distance: distance, unit: unit, in: context)
                            onSave()
                            dismiss()
                        } catch { errorMessage = error.localizedDescription }
                    }
                    .disabled(Double(value).map { !$0.isFinite || $0 < 0 } ?? true)
                }
            }
            .onAppear { isFocused = true }
            .alert("Couldn’t update odometer", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "Please try again.") }
        }
    }
}
