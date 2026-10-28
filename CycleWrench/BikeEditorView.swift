import SwiftUI
import SwiftData

struct BikeEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let bike: Bike?
    @State private var configuration: BikeConfiguration
    @State private var name: String
    @State private var odometer = "0"
    let unit: String
    @State private var saveError: String?
    let onSave: (Bike) -> Void

    init(bike: Bike? = nil, defaultUnit: String, onSave: @escaping (Bike) -> Void) {
        self.bike = bike
        _name = State(initialValue: bike?.name ?? "")
        _configuration = State(initialValue: bike?.configuration ?? BikeConfiguration())
        unit = defaultUnit
        self.onSave = onSave
    }

    private var distance: Double? {
        guard let value = Double(odometer), value.isFinite, value >= 0 else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Bike") {
                    TextField("Bike name", text: $name)
                    if bike == nil {
                        TextField("Current odometer", text: $odometer).keyboardType(.decimalPad)
                        LabeledContent("Distance unit", value: unit)
                    }
                }
                Section {
                    Picker("Power", selection: $configuration.drive) {
                        ForEach(BikeConfiguration.Drive.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    Picker("Suspension", selection: $configuration.suspension) {
                        ForEach(BikeConfiguration.Suspension.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    Picker("Brakes", selection: $configuration.brakes) {
                        ForEach(BikeConfiguration.Brakes.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                } header: {
                    Text("Setup")
                } footer: {
                    Text("Choose your setup to show relevant components. Leave a field unset to show all options for it. Your existing history is always kept.")
                }

            }
            .navigationTitle(bike == nil ? "Add bike" : "Bike setup")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(bike == nil ? "Add" : "Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (bike == nil && distance == nil))
                }
            }
            .alert("Couldn’t save bike", isPresented: Binding(
                get: { saveError != nil }, set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: { Text(saveError ?? "Please try again.") }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let savedBike: Bike
        if let bike {
            savedBike = bike
            savedBike.name = trimmedName
            savedBike.configuration = configuration
        } else {
            guard let distance else { return }
            savedBike = Bike(name: trimmedName, distanceUnit: "km",
                odometer: DistanceUnit.convert(distance, from: unit, to: "km") ?? distance,
                configuration: configuration)
            context.insert(savedBike)
        }
        do {
            try context.save()
            onSave(savedBike)
            dismiss()
        } catch {
            context.rollback()
            saveError = error.localizedDescription
        }
    }
}
