import SwiftUI
import SwiftData

struct MaintenanceLogView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ServiceEntry.date, order: .reverse) private var entries: [ServiceEntry]
    @Query(sort: \Bike.name) private var bikes: [Bike]
    @Query(sort: \OdometerReading.date, order: .reverse) private var readings: [OdometerReading]
    @AppStorage("distanceUnit") private var preferredUnit = "km"
    @AppStorage("selectedBikeID") private var selectedBikeID = ""
    @State private var showingAddBike = false
    @State private var odometerOnly = false

    private var bike: Bike? { bikes.first { $0.id.uuidString == selectedBikeID } }
    private var bikeEntries: [ServiceEntry] {
        guard let bike else { return [] }
        return entries.filter { $0.bikeID == bike.id }
    }
    private var bikeReadings: [OdometerReading] {
        guard let bike else { return [] }
        return readings.filter { $0.bikeID == bike.id }
    }
    private var canSave: Bool {
        guard let bike, let distance, distance >= bike.odometer else { return false }
        return odometerOnly || (!selections.isEmpty && selections.allSatisfy { $0.kind != nil })
    }
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
                Section("Bike") {
                    if !bikes.isEmpty {
                        Picker("Bike", selection: $selectedBikeID) {
                            ForEach(bikes) { bike in
                                Text(bike.name).tag(bike.id.uuidString)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    Button("Add bike", systemImage: "plus") { showingAddBike = true }
                    if let bike {
                        LabeledContent("Current odometer",
                            value: "\(bike.odometer.formatted()) \(bike.distanceUnit)")
                    }
                }
                if let bike {
                    Section {
                        Picker("Entry", selection: $odometerOnly) {
                            Text("Maintenance").tag(false)
                            Text("Odometer only").tag(true)
                        }
                        .pickerStyle(.segmented)
                        HStack {
                            TextField("Current odometer", text: $odometer)
                                .keyboardType(.decimalPad)
                                .focused($odometerFocused)
                                .accessibilityLabel("Current odometer")
                            Text(bike.distanceUnit).foregroundStyle(.secondary)
                        }
                        if let distance, distance < bike.odometer {
                            Text("Enter a reading at least as high as the current odometer.")
                                .font(.caption).foregroundStyle(.red)
                        }
                        if !odometerOnly {
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
                    }

                    Section("Service history") {
                        if bikeEntries.isEmpty {
                            ContentUnavailableView("Ready for your next tune-up",
                                systemImage: "wrench.and.screwdriver",
                                description: Text("Enter your odometer and select the parts you worked on."))
                        }
                        ForEach(bikeEntries) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.componentTitle).font(.headline)
                                Text("\(entry.action.capitalized) · \(entry.odometer.formatted()) \(entry.distanceUnit)")
                                Text(entry.date, style: .date)
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    if !bikeReadings.isEmpty {
                        Section("Odometer updates") {
                            ForEach(bikeReadings) { reading in
                                HStack {
                                    Text(reading.date, style: .date)
                                    Spacer()
                                    Text("\(reading.distance.formatted()) \(reading.distanceUnit)")
                                }
                            }
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
                        .disabled(!canSave)
                        .accessibilityLabel(odometerOnly ? "Save odometer" : "Save maintenance")
                }
            }
            .sheet(isPresented: $showingAddBike) {
                AddBikeView(defaultUnit: preferredUnit) { newBike in
                    selectedBikeID = newBike.id.uuidString
                    loadBike(newBike)
                }
            }
            .task {
                do {
                    try BikeStore.adoptLegacyEntries(in: context, preferredUnit: preferredUnit)
                    let stored = try context.fetch(FetchDescriptor<Bike>(sortBy: [SortDescriptor(\.name)]))
                    if let current = stored.first(where: { $0.id.uuidString == selectedBikeID }) ?? stored.first {
                        selectedBikeID = current.id.uuidString
                        loadBike(current)
                    }
                } catch { saveError = error.localizedDescription }
            }
            .onChange(of: selectedBikeID) {
                if let bike { loadBike(bike) }
            }
            .alert("Couldn’t save changes", isPresented: Binding(
                get: { saveError != nil }, set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "Please try again.")
            }
        }
    }

    private func loadBike(_ bike: Bike) {
        odometer = String(bike.odometer)
        selections = [ComponentSelection()]
        odometerFocused = false
    }

    private func save() {
        guard canSave, let bike, let distance else { return }
        let selected = odometerOnly ? Set<BicycleComponent>() : Set(selections.flatMap { selection in
            selection.kind?.components(at: selection.position) ?? []
        })
        let date = Date()
        bike.odometer = distance
        if odometerOnly {
            context.insert(OdometerReading(bike: bike, date: date))
        }
        for component in BicycleComponent.allCases where selected.contains(component) {
            context.insert(ServiceEntry(date: date, odometer: distance,
                distanceUnit: bike.distanceUnit, component: component, action: action, bikeID: bike.id))
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
