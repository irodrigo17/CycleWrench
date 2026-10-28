import SwiftUI
import SwiftData

struct MaintenanceLogView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ServiceEntry.date, order: .reverse) private var entries: [ServiceEntry]
    @AppStorage("distanceUnit") private var unit = "km"
    @State private var odometer = ""
    @State private var selected: Set<BicycleComponent> = []
    @State private var action = ServiceAction.replaced
    @State private var saveError: String?

    private var distance: Double? {
        guard let value = Double(odometer), value.isFinite, value >= 0 else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Log maintenance") {
                    HStack {
                        TextField("Current odometer", text: $odometer)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Current odometer")
                        Picker("Unit", selection: $unit) {
                            Text("km").tag("km")
                            Text("mi").tag("mi")
                        }
                        .labelsHidden()
                        .fixedSize()
                    }
                    Picker("Action", selection: $action) {
                        ForEach(ServiceAction.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    ForEach(BicycleComponent.allCases) { component in
                        Button {
                            if selected.contains(component) {
                                selected.remove(component)
                            } else {
                                selected.insert(component)
                            }
                        } label: {
                            HStack {
                                Text(component.title).foregroundStyle(.primary)
                                Spacer()
                                if selected.contains(component) {
                                    Image(systemName: "checkmark").foregroundStyle(.tint)
                                }
                            }
                        }
                        .accessibilityAddTraits(selected.contains(component) ? .isSelected : [])
                    }
                    Button("Save maintenance", action: save)
                        .disabled(distance == nil || selected.isEmpty)
                }

                Section("History") {
                    if entries.isEmpty {
                        ContentUnavailableView("Ready for your next tune-up",
                            systemImage: "wrench.and.screwdriver",
                            description: Text("Enter your odometer and select the parts you worked on."))
                    }
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.componentTitle).font(.headline)
                            Text("\(entry.action.capitalized) · \(entry.odometer.formatted()) \(entry.distanceUnit)")
                            Text(entry.date, style: .date)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("CycleWrench")
            .alert("Couldn’t save maintenance", isPresented: Binding(
                get: { saveError != nil }, set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "Please try again.")
            }
        }
    }

    private func save() {
        guard let distance, !selected.isEmpty else { return }
        let date = Date()
        for component in BicycleComponent.allCases where selected.contains(component) {
            context.insert(ServiceEntry(date: date, odometer: distance,
                distanceUnit: unit, component: component, action: action))
        }
        do {
            try context.save()
            selected.removeAll()
        } catch {
            context.rollback()
            saveError = error.localizedDescription
        }
    }
}
