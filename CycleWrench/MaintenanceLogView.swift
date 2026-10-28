import SwiftUI
import SwiftData

struct MaintenanceLogView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ServiceEntry.date, order: .reverse) private var entries: [ServiceEntry]
    @Query(sort: \Bike.name) private var bikes: [Bike]
    @Query(sort: \OdometerReading.date, order: .reverse) private var readings: [OdometerReading]
    @Query(sort: \CustomComponent.name) private var customComponents: [CustomComponent]
    @AppStorage("distanceUnit") private var preferredUnit = "km"
    @AppStorage("selectedBikeID") private var selectedBikeID = ""
    @State private var activeSheet: Sheet?
    @State private var odometer = ""
    @State private var selections = [ComponentSelection()]
    @State private var didLoadStore = false
    @State private var selectedPanel: Panel?
    @State private var compactColumn = NavigationSplitViewColumn.sidebar
    @State private var saveError: String?
    @FocusState private var odometerFocused: Bool

    private enum Panel: String, Hashable {
        case components, history
    }
    private enum Sheet: String, Identifiable {
        case addBike, bikeSetup, settings, odometer, customComponent
        var id: String { rawValue }
    }
    private var bike: Bike? {
        bikes.first { $0.id.uuidString == selectedBikeID } ?? bikes.first
    }
    private var bikeEntries: [ServiceEntry] { entries.filter { $0.bikeID == bike?.id } }
    private var componentEstimates: [ComponentEstimate] {
        guard let bike else { return [] }
        return ComponentEstimate.calculate(bikeID: bike.id, odometer: displayedOdometer(bike),
            unit: preferredUnit, events: bikeEntries.map(MaintenanceEvent.init))
    }
    private var availableComponents: [ComponentDescriptor] {
        ComponentKind.allCases.filter { bike?.configuration.supports($0) ?? true }.map(ComponentDescriptor.init)
            + customComponents.filter { $0.restrictions.matches(bike?.configuration ?? BikeConfiguration()) }.map(\.descriptor)
    }
    private var distance: Double? {
        guard let value = Double(odometer), value.isFinite, value >= 0 else { return nil }
        return value
    }
    private var canSave: Bool {
        guard let bike, let distance, distance >= displayedOdometer(bike), !selections.isEmpty else { return false }
        return selections.allSatisfy { descriptor(for: $0.componentID) != nil }
    }
    private func descriptor(for id: String?) -> ComponentDescriptor? {
        availableComponents.first { $0.id == id }
    }

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $compactColumn) {
            List(selection: $selectedPanel) {
                Section {
                    if !bikes.isEmpty {
                        Picker("Bike", selection: $selectedBikeID) {
                            ForEach(bikes) { Text($0.name).tag($0.id.uuidString) }
                        }
                        .pickerStyle(.menu)
                    }
                    HStack {
                        Button("Add bike", systemImage: "plus") { activeSheet = .addBike }
                        Spacer()
                        if bike != nil {
                            Button("Bike setup", systemImage: "slider.horizontal.3") { activeSheet = .bikeSetup }
                        }
                    }
                    .buttonStyle(.borderless)
                    if let bike {
                        Button { activeSheet = .odometer } label: {
                            HStack {
                                Text("Current odometer").foregroundStyle(.primary)
                                Spacer()
                                Text("\(displayedOdometer(bike).formatted(.number.precision(.fractionLength(0...1)))) \(preferredUnit)")
                                    .font(.system(.headline, design: .rounded)).monospacedDigit()
                                Image(systemName: "pencil").font(.caption)
                            }
                        }
                        .accessibilityHint("Update this bike’s odometer")
                    }
                }
                if let bike {
                    Section("Log maintenance") {
                        HStack {
                            TextField("Odometer", text: $odometer)
                                .keyboardType(.decimalPad).focused($odometerFocused)
                                .accessibilityLabel("Maintenance odometer")
                            Text(preferredUnit).foregroundStyle(.secondary)
                        }
                        if let distance, distance < displayedOdometer(bike) {
                            Text("Enter a reading at least as high as the current odometer.")
                                .font(.caption).foregroundStyle(.red)
                        }
                        ForEach($selections) { $selection in
                            VStack(spacing: 12) {
                                Picker("Component", selection: $selection.componentID) {
                                    Text("Choose component").tag(nil as String?)
                                    ForEach(availableComponents) { item in
                                        Text(item.title).tag(Optional(item.id))
                                    }
                                }
                                .pickerStyle(.menu)
                                .onChange(of: selection.componentID) {
                                    if let item = descriptor(for: selection.componentID) {
                                        selection.action = item.defaultAction
                                    }
                                }
                                if let item = descriptor(for: selection.componentID) {
                                    if item.hasPosition {
                                        Picker("Position", selection: $selection.position) {
                                            ForEach(ComponentPosition.allCases) { Text($0.title).tag($0) }
                                        }
                                        .pickerStyle(.segmented)
                                    }
                                    Picker("Action", selection: $selection.action) {
                                        ForEach(ServiceAction.loggableCases) { Text($0.title).tag($0) }
                                    }
                                    TextField(item.builtIn == .bearings ? "Which bearings? (optional)" : "Notes (optional)",
                                        text: $selection.notes, axis: .vertical)
                                        .font(.subheadline)
                                }
                                if selections.count > 1 {
                                    Button("Remove component", role: .destructive) {
                                        selections.removeAll { $0.id == selection.id }
                                    }
                                    .font(.caption).frame(maxWidth: .infinity, alignment: .trailing)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        Button("Add another component", systemImage: "plus") {
                            selections.append(ComponentSelection())
                        }
                        Button("Create custom component", systemImage: "plus.circle") { activeSheet = .customComponent }
                    }
                    Section {
                        NavigationLink(value: Panel.components) {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Components", systemImage: "chart.bar.xaxis")
                                if let next = componentEstimates.first, let remaining = next.remainingDistance {
                                    Text("\(next.componentTitle) · ~\(abs(remaining).formatted(.number.precision(.fractionLength(0)))) \(preferredUnit) \(remaining <= 0 ? "past average" : "left")")
                                        .font(.caption)
                                        .foregroundStyle(CycleWrenchStyle.statusColor(next.attention))
                                }
                            }
                        }
                        NavigationLink(value: Panel.history) {
                            Label("Service history", systemImage: "clock.arrow.circlepath")
                        }
                    }

                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(CycleWrenchStyle.canvas)
            .navigationSplitViewColumnWidth(min: 320, ideal: 400, max: 480)
            .navigationTitle("CycleWrench")
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Settings", systemImage: "gearshape") { activeSheet = .settings }.labelStyle(.iconOnly)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).fontWeight(.semibold)
                        .disabled(!canSave).accessibilityLabel("Save maintenance")
                }
            }
            .sheet(item: $activeSheet) { sheet in sheetView(sheet) }
            .onChange(of: bike?.configuration) { refreshSelections() }
            .onChange(of: customComponents.map(\.id)) { refreshSelections() }
            .task {
                // Revisiting the sidebar or unfolding must not clear a draft.
                guard !didLoadStore else { return }
                do {
                    try BikeStore.adoptLegacyEntries(in: context, preferredUnit: preferredUnit)
                    let stored = try context.fetch(FetchDescriptor<Bike>(sortBy: [SortDescriptor(\.name)]))
                    if let current = stored.first(where: { $0.id.uuidString == selectedBikeID }) ?? stored.first {
                        selectedBikeID = current.id.uuidString
                        loadBike(current)
                    }
                    didLoadStore = true
                } catch { saveError = error.localizedDescription }
            }
            .onChange(of: bikes.map(\.id)) {
                if let bike, bike.id.uuidString != selectedBikeID {
                    selectedBikeID = bike.id.uuidString
                    loadBike(bike)
                }
            }
            .onChange(of: preferredUnit) { old, new in
                if let distance, let converted = DistanceUnit.convert(distance, from: old, to: new) {
                    odometer = String(converted)
                }
            }
            .onChange(of: selectedBikeID) { if let bike { loadBike(bike) } }
            .alert("Couldn’t save changes", isPresented: Binding(
                get: { saveError != nil }, set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: { Text(saveError ?? "Please try again.") }
        } detail: {
            if let bike {
                switch selectedPanel ?? .components {
                case .components:
                    ComponentHealthView(bikeName: bike.name, estimates: componentEstimates)
                case .history:
                    ServiceHistoryView(bikeID: bike.id, bikeName: bike.name)
                }
            } else {
                ContentUnavailableView("Add your first bike", systemImage: "bicycle",
                    description: Text("Your components and maintenance history will appear here."))
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func sheetView(_ sheet: Sheet) -> some View {
        switch sheet {
        case .settings: SettingsView()
        case .addBike:
            BikeEditorView(defaultUnit: preferredUnit) {
                selectedBikeID = $0.id.uuidString
                loadBike($0)
            }
        case .bikeSetup:
            if let bike { BikeEditorView(bike: bike, defaultUnit: preferredUnit) { _ in refreshSelections() } }
        case .odometer:
            if let bike {
                UpdateOdometerView(bike: bike, current: displayedOdometer(bike), unit: preferredUnit) {
                    odometer = String(displayedOdometer(bike))
                }
            }
        case .customComponent:
            CustomComponentEditorView { created in
                // Definitions can apply to another bike without entering this draft.
                guard created.restrictions.matches(bike?.configuration ?? BikeConfiguration()) else { return }
                let custom = created.descriptor
                if let index = selections.firstIndex(where: { $0.componentID == nil }) {
                    selections[index].componentID = custom.id
                    selections[index].action = custom.defaultAction
                } else {
                    selections.append(ComponentSelection(componentID: custom.id, action: custom.defaultAction))
                }
            }
        }
    }

    private func displayedOdometer(_ bike: Bike) -> Double {
        DistanceUnit.convert(BikeStore.currentOdometer(for: bike, entries: entries, readings: readings),
                             from: bike.distanceUnit, to: preferredUnit) ?? bike.odometer
    }
    private func loadBike(_ bike: Bike) {
        odometer = String(displayedOdometer(bike))
        selections = [ComponentSelection()]
        odometerFocused = false
    }
    private func refreshSelections() {
        for index in selections.indices where descriptor(for: selections[index].componentID) == nil {
            selections[index] = ComponentSelection()
        }
    }
    private func save() {
        guard canSave, let bike, let distance else { return }
        let date = Date()
        bike.odometer = DistanceUnit.convert(distance, from: preferredUnit, to: bike.distanceUnit) ?? distance
        context.insert(OdometerReading(bike: bike, date: date))
        // Deduplicate identical component/action pairs while allowing different actions.
        var pending: [String: (LoggedComponent, ServiceAction, Set<String>)] = [:]
        for selection in selections {
            guard let item = descriptor(for: selection.componentID) else { continue }
            for component in item.components(at: selection.position) {
                let key = "\(component.id)/\(selection.action.rawValue)"
                var notes = pending[key]?.2 ?? []
                let note = selection.notes.trimmingCharacters(in: .whitespacesAndNewlines)
                if !note.isEmpty { notes.insert(note) }
                pending[key] = (component, selection.action, notes)
            }
        }
        for key in pending.keys.sorted() {
            guard let (component, action, notes) = pending[key] else { continue }
            context.insert(ServiceEntry(date: date, odometer: bike.odometer, distanceUnit: bike.distanceUnit,
                componentID: component.id, componentName: component.title, action: action, bikeID: bike.id,
                notes: notes.sorted().joined(separator: "\n")))
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
    var componentID: String?
    var action = ServiceAction.replaced
    var position = ComponentPosition.front
    var notes = ""
}
