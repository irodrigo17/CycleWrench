import XCTest
import SwiftData
@testable import CycleWrench

final class BikeStoreTests: XCTestCase {
    @MainActor
    func testLegacyAdoptionConvertsUnitsAndIsIdempotent() throws {
        let container = try ModelContainer(for: Bike.self, ServiceEntry.self, OdometerReading.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let older = ServiceEntry(date: .now.addingTimeInterval(-100), odometer: 100,
            distanceUnit: "mi", component: .chain, action: .replaced)
        let newer = ServiceEntry(date: .now, odometer: 150,
            distanceUnit: "km", component: .frontBrakePads, action: .replaced)
        let existing = Bike(name: "Road bike")
        let linked = ServiceEntry(date: .now, odometer: 20, distanceUnit: "km",
            component: .chain, action: .serviced, bikeID: existing.id)
        context.insert(existing)
        context.insert(older)
        context.insert(newer)
        context.insert(linked)
        try context.save()
        try BikeStore.adoptLegacyEntries(in: context, preferredUnit: "mi")
        try BikeStore.adoptLegacyEntries(in: context, preferredUnit: "mi")
        let bikes = try context.fetch(FetchDescriptor<Bike>())
        XCTAssertEqual(bikes.count, 2)
        let adopted = try XCTUnwrap(bikes.first { $0.id != existing.id })
        XCTAssertEqual(adopted.distanceUnit, "km")
        XCTAssertEqual(adopted.odometer, 160.9344, accuracy: 0.0001)
        XCTAssertEqual(older.bikeID, adopted.id)
        XCTAssertEqual(newer.bikeID, adopted.id)
        XCTAssertEqual(linked.bikeID, existing.id)
        XCTAssertEqual(older.odometer, 100)
        XCTAssertEqual(older.distanceUnit, "mi")
    }

    @MainActor
    func testOdometerUpdatePersistsWithoutServiceAndDoesNotChangeOtherBike() throws {
        let container = try ModelContainer(for: Bike.self, ServiceEntry.self, OdometerReading.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let first = Bike(name: "Gravel", distanceUnit: "mi", odometer: 100)
        let second = Bike(name: "MTB", odometer: 250)
        context.insert(first)
        context.insert(second)
        first.odometer = 125
        context.insert(OdometerReading(bike: first))
        try context.save()
        let fresh = ModelContext(container)
        let bikes = try fresh.fetch(FetchDescriptor<Bike>())
        XCTAssertEqual(bikes.first { $0.id == first.id }?.odometer, 125)
        XCTAssertEqual(bikes.first { $0.id == second.id }?.odometer, 250)
        XCTAssertTrue(try fresh.fetch(FetchDescriptor<ServiceEntry>()).isEmpty)
        let reading = try XCTUnwrap(fresh.fetch(FetchDescriptor<OdometerReading>()).first)
        XCTAssertEqual(reading.bikeID, first.id)
        XCTAssertEqual(reading.distanceUnit, "mi")
        XCTAssertEqual(reading.distance, 125)
    }

    @MainActor
    func testOriginalStoreMigratesWithoutLosingHistory() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("migration.store")
        try writeLegacyStore(at: url)
        let container = try ModelContainer(for: Bike.self, ServiceEntry.self, OdometerReading.self,
            configurations: ModelConfiguration(url: url))
        let context = container.mainContext
        try BikeStore.adoptLegacyEntries(in: context, preferredUnit: "km")
        let entries = try context.fetch(FetchDescriptor<ServiceEntry>())
        XCTAssertEqual(entries.count, 1)
        let entry = try XCTUnwrap(entries.first)
        XCTAssertEqual(entry.component, "rearTire")
        XCTAssertEqual(entry.odometer, 420)
        XCTAssertEqual(entry.action, "replaced")
        XCTAssertNotNil(entry.bikeID)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Bike>()).first?.odometer, 420)
    }

    @MainActor
    private func writeLegacyStore(at url: URL) throws {
        let container = try ModelContainer(for: OriginalStore.ServiceEntry.self,
            configurations: ModelConfiguration(url: url))
        let context = ModelContext(container)
        context.insert(OriginalStore.ServiceEntry())
        try context.save()
    }
}

// Exact original entity name and stored attributes, before bike support.
private enum OriginalStore {
    @Model
    final class ServiceEntry {
        var date: Date
        var odometer: Double
        var distanceUnit: String
        var component: String
        var action: String
        init() {
            date = .now
            odometer = 420
            distanceUnit = "km"
            component = "rearTire"
            action = "replaced"
        }
    }
}
