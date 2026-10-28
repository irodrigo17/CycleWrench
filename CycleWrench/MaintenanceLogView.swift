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
    @State private var showingSettings = false
    @State private var odometerOnly = false

    private var bike: Bike? {
        bikes.first { $0.id.uuidString == selectedBikeID } ?? bikes.first
    }
    private var bikeEntries: [ServiceEntry] {
        guard let bike else { return [] }
        return entries.filter { $0.bikeID == bike.id }.sorted {
            if $0.dateIsKnown != $1.dateIsKnown { return $0.dateIsKnown }
            if $0.dateIsKnown && $0.date != $1.date { return $0.date > $1.date }
            if $0.odometer != $1.odometer { return $0.odometer > $1.odometer }
            return $0.component < $1.component
        }
    }
    private var bikeReadings: [OdometerReading] {
        guard let bike else { return [] }
        return readings.filter { $0.bikeID == bike.id }
    }
    private var componentEstimates: [ComponentEstimate] {
        guard let bike else { return [] }
        return ComponentEstimate.calculate(bikeID: bike.id, odometer: displayedOdometer(bike),
            unit: preferredUnit, events: bikeEntries.map(MaintenanceEvent.init))
    }
    private var canSave: Bool {
        guard let bike, let distance, distance >= displayedOdometer(bike) else { return false }
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
                            value: "\(displayedOdometer(bike).formatted(.number.precision(.fractionLength(0...1)))) \(preferredUnit)")
                    }
                }
                if let bike {
                    Section {
                        NavigationLink {
                            ComponentHealthView(bikeName: bike.name, estimates: componentEstimates)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Components", systemImage: "chart.bar.xaxis")
                                if let next = componentEstimates.first, let remaining = next.remainingDistance {
                                    Text("\(next.component.title) · ~\(abs(remaining).formatted(.number.precision(.fractionLength(0)))) \(preferredUnit) \(remaining <= 0 ? "past average" : "left")")
                                        .font(.caption).foregroundStyle(.secondary)
                                } else {
                                    Text("Learn lifespans from your maintenance history")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
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
                            Text(preferredUnit).foregroundStyle(.secondary)
                        }
                        if let distance, distance < displayedOdometer(bike) {
                            Text("Enter a reading at least as high as the current odometer.")
                                .font(.caption).foregroundStyle(.red)
                        }
                        if !odometerOnly {
                            Picker("Action", selection: $action) {
                                ForEach(ServiceAction.loggableCases) { item in
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
                                    if selection.kind != nil {
                                        TextField(selection.kind == .bearings
                                            ? "Which bearings? (optional)" : "Notes (optional)",
                                            text: $selection.notes, axis: .vertical)
                                            .font(.subheadline)
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
                                Text("\(ServiceAction(rawValue: entry.action)?.title ?? entry.action.capitalized) · \(displayDistance(entry.odometer, from: entry.distanceUnit)) \(preferredUnit)")
                                if !entry.notes.isEmpty {
                                    Text(entry.notes).font(.subheadline).foregroundStyle(.secondary)
                                }
                                if entry.dateIsKnown {
                                    Text(entry.date, style: .date)
                                        .font(.caption).foregroundStyle(.secondary)
                                } else {
                                    Text("Date not recorded").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    if !bikeReadings.isEmpty {
                        Section("Odometer history") {
                            ForEach(bikeReadings) { reading in
                                HStack {
                                    Text(reading.date, style: .date)
                                    Spacer()
                                    Text("\(displayDistance(reading.distance, from: reading.distanceUnit)) \(preferredUnit)")
                                }
                            }
                        }
                    }
                }

            }
            .navigationTitle("CycleWrench")
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Settings", systemImage: "gearshape") { showingSettings = true }
                        .labelStyle(.iconOnly)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                        .accessibilityLabel(odometerOnly ? "Save odometer" : "Save maintenance")
                }
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
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
            .onChange(of: bikes.map(\.id)) {
                if let bike, bike.id.uuidString != selectedBikeID {
                    selectedBikeID = bike.id.uuidString
                    loadBike(bike)
                }
            }
            .onChange(of: preferredUnit) { oldUnit, newUnit in
                if let distance, let converted = DistanceUnit.convert(distance, from: oldUnit, to: newUnit) {
                    odometer = String(converted)
                }
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

    private func displayedOdometer(_ bike: Bike) -> Double {
        DistanceUnit.convert(BikeStore.currentOdometer(for: bike, entries: entries, readings: readings),
                             from: bike.distanceUnit, to: preferredUnit) ?? bike.odometer
    }

    private func displayDistance(_ distance: Double, from unit: String) -> String {
        (DistanceUnit.convert(distance, from: unit, to: preferredUnit) ?? distance)
            .formatted(.number.precision(.fractionLength(0...1)))
    }

    private func loadBike(_ bike: Bike) {
        odometer = String(displayedOdometer(bike))
        selections = [ComponentSelection()]
        odometerFocused = false
    }

    private func notes(for component: BicycleComponent) -> String {
        let notes = selections.filter { $0.kind?.components(at: $0.position).contains(component) == true }
            .map { $0.notes.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return Array(Set(notes)).sorted().joined(separator: "\n")
    }

    private func save() {
        guard canSave, let bike, let distance else { return }
        let selected = odometerOnly ? Set<BicycleComponent>() : Set(selections.flatMap { selection in
            selection.kind?.components(at: selection.position) ?? []
        })
        let date = Date()
        bike.odometer = DistanceUnit.convert(distance, from: preferredUnit, to: bike.distanceUnit) ?? distance
        context.insert(OdometerReading(bike: bike, date: date))
        for component in BicycleComponent.allCases where selected.contains(component) {
            context.insert(ServiceEntry(date: date, odometer: bike.odometer,
                distanceUnit: bike.distanceUnit, component: component, action: action, bikeID: bike.id,
                notes: notes(for: component)))
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
    var notes = ""
}
