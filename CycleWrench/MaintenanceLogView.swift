import SwiftUI
import SwiftData

struct MaintenanceLogView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ServiceEntry.date, order: .reverse) private var entries: [ServiceEntry]
    @AppStorage("distanceUnit") private var unit = "km"
    @State private var odometer = ""
    @State private var selections = [ComponentSelection()]
    @FocusState private var odometerFocused: Bool
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
                            .focused($odometerFocused)
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
                    ForEach($selections) { $selection in
                        VStack(spacing: 12) {
                            Picker("Component", selection: $selection.kind) {
                                Text("Choose component").tag(nil as ComponentKind?)
                                ForEach(ComponentKind.allCases) { kind in
                                    Text(kind.title).tag(Optional(kind))
                                }
                            }
                            .pickerStyle(.menu)

                            if selection.kind?.hasPosition == true {
                                Picker("Position", selection: $selection.position) {
                                    ForEach(ComponentPosition.allCases) { position in
                                        Text(position.title).tag(position)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            if selections.count > 1 {
                                Button("Remove component", role: .destructive) {
                                    selections.removeAll { $0.id == selection.id }
                                }
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    Button("Add another component", systemImage: "plus") {
                        selections.append(ComponentSelection())
                    }

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
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(distance == nil || selections.contains { $0.kind == nil })
                        .accessibilityLabel("Save maintenance")
                }
            }
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
        guard let distance, !selections.isEmpty,
              selections.allSatisfy({ $0.kind != nil }) else { return }
        // Overlapping selections (e.g. both tires plus front tire) log each part once.
        let selected = Set(selections.flatMap { selection in
            selection.kind?.components(at: selection.position) ?? []
        })
        let date = Date()
        for component in BicycleComponent.allCases where selected.contains(component) {
            context.insert(ServiceEntry(date: date, odometer: distance,
                distanceUnit: unit, component: component, action: action))
        }
        do {
            try context.save()
            selections = [ComponentSelection()]
            odometerFocused = false
        } catch {
            context.rollback()
            saveError = error.localizedDescription
        }
    }
}

private struct ComponentSelection: Identifiable {
    let id = UUID()
    var kind: ComponentKind?
    var position = ComponentPosition.front
}
