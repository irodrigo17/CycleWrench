import SwiftUI
import SwiftData

struct ServiceHistoryView: View {
    let bikeID: UUID
    let bikeName: String
    @AppStorage("distanceUnit") private var unit = "km"
    @Query(sort: \ServiceEntry.date, order: .reverse) private var allEntries: [ServiceEntry]
    @Query(sort: \OdometerReading.date, order: .reverse) private var allReadings: [OdometerReading]

    private var entries: [ServiceEntry] {
        allEntries.filter { $0.bikeID == bikeID }.sorted {
            if $0.dateIsKnown != $1.dateIsKnown { return $0.dateIsKnown }
            if $0.dateIsKnown && $0.date != $1.date { return $0.date > $1.date }
            if $0.odometer != $1.odometer { return $0.odometer > $1.odometer }
            return $0.component < $1.component
        }
    }
    private var readings: [OdometerReading] { allReadings.filter { $0.bikeID == bikeID } }

    var body: some View {
        List {
            Section("Service history") {
                if entries.isEmpty {
                    ContentUnavailableView("No maintenance yet", systemImage: "wrench.and.screwdriver",
                        description: Text("Your saved services and replacements will appear here."))
                }
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.componentTitle).font(.headline)
                        Text("\(ServiceAction(rawValue: entry.action)?.title ?? entry.action) · \(distance(entry.odometer, from: entry.distanceUnit))")
                        if !entry.notes.isEmpty {
                            Text(entry.notes).font(.subheadline).foregroundStyle(.secondary)
                        }
                        if entry.dateIsKnown {
                            Text(entry.date, style: .date).font(.caption).foregroundStyle(.secondary)
                        } else {
                            Text("Date not recorded").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            if !readings.isEmpty {
                Section("Odometer history") {
                    ForEach(readings) { reading in
                        HStack {
                            Text(reading.date, style: .date)
                            Spacer()
                            Text(distance(reading.distance, from: reading.distanceUnit))
                        }
                    }
                }
            }
        }
        .navigationTitle("Service history")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Text(bikeName).font(.caption).foregroundStyle(.secondary)
                .padding(8).frame(maxWidth: .infinity).background(.bar)
        }
    }

    private func distance(_ value: Double, from source: String) -> String {
        let converted = DistanceUnit.convert(value, from: source, to: unit) ?? value
        return "\(converted.formatted(.number.precision(.fractionLength(0...1)))) \(unit)"
    }
}
