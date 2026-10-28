import XCTest
import SwiftData
@testable import CycleWrench

final class BikeStoreTests: XCTestCase {
    @MainActor
    func testLegacyAdoptionConvertsUnitsAndIsIdempotent() throws {
        let container = try ModelContainer(for: Bike.self, ServiceEntry.self, OdometerReading.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
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
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
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
            configurations: ModelConfiguration(url: url, cloudKitDatabase: .none))
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
    func testCurrentOdometerCannotRegressWhenAnOlderDeviceSyncs() throws {
        let bike = Bike(name: "Gravel", odometer: 100)
        let other = Bike(name: "Other bike", odometer: 9000)
        bike.odometer = 150
        let reading = OdometerReading(bike: bike)
        bike.odometer = 100 // Simulate the stale Bike record winning a cloud merge.
        let entry = ServiceEntry(date: .now, odometer: 100, distanceUnit: "mi",
            component: .chain, action: .replaced, bikeID: bike.id)
        let unrelated = OdometerReading(bike: other)
        XCTAssertEqual(BikeStore.currentOdometer(for: bike, entries: [entry], readings: [reading, unrelated]),
                       160.9344, accuracy: 0.0001)
    }

    @MainActor
    func testExistingMultiBikeStoreMigratesToCloudCompatibleDefaultsAndNotes() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("previous.store")
        let id = UUID()
        try writePreviousBikeStore(at: url, bikeID: id)
        let container = try ModelContainer(for: Bike.self, ServiceEntry.self, OdometerReading.self,
            configurations: ModelConfiguration(url: url, cloudKitDatabase: .none))
        let context = container.mainContext
        let bike = try XCTUnwrap(context.fetch(FetchDescriptor<Bike>()).first)
        let entry = try XCTUnwrap(context.fetch(FetchDescriptor<ServiceEntry>()).first)
        let reading = try XCTUnwrap(context.fetch(FetchDescriptor<OdometerReading>()).first)
        XCTAssertEqual(bike.id, id)
        XCTAssertEqual(bike.name, "Existing bike")
        XCTAssertEqual(bike.distanceUnit, "mi")
        XCTAssertEqual(bike.odometer, 600)
        XCTAssertEqual(entry.bikeID, id)
        XCTAssertEqual(entry.component, "rearBrakePads")
        XCTAssertEqual(entry.odometer, 500)
        XCTAssertEqual(entry.notes, "")
        XCTAssertTrue(entry.dateIsKnown)
        XCTAssertNil(entry.importSourceID)
        XCTAssertEqual(reading.bikeID, id)
        XCTAssertEqual(reading.distance, 600)
    }

    @MainActor
    private func writePreviousBikeStore(at url: URL, bikeID: UUID) throws {
        let container = try ModelContainer(for: PreviousBikeStore.Bike.self,
            PreviousBikeStore.ServiceEntry.self, PreviousBikeStore.OdometerReading.self,
            configurations: ModelConfiguration(url: url, cloudKitDatabase: .none))
        let context = ModelContext(container)
        context.insert(PreviousBikeStore.Bike(id: bikeID))
        context.insert(PreviousBikeStore.ServiceEntry(bikeID: bikeID))
        context.insert(PreviousBikeStore.OdometerReading(bikeID: bikeID))
        try context.save()
    }

    @MainActor
    private func writeLegacyStore(at url: URL) throws {
        let container = try ModelContainer(for: OriginalStore.ServiceEntry.self,
            configurations: ModelConfiguration(url: url, cloudKitDatabase: .none))
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

// Schema from the multiple-bike release, before CloudKit defaults and notes.
private enum PreviousBikeStore {
    @Model final class Bike {
        var id: UUID = UUID()
        var name: String
        var distanceUnit: String
        var odometer: Double
        init(id: UUID) {
            self.id = id
            name = "Existing bike"
            distanceUnit = "mi"
            odometer = 600
        }
    }
    @Model final class ServiceEntry {
        var date: Date
        var odometer: Double
        var distanceUnit: String
        var component: String
        var action: String
        var bikeID: UUID? = nil
        init(bikeID: UUID) {
            self.bikeID = bikeID
            date = .now
            odometer = 500
            distanceUnit = "mi"
            component = "rearBrakePads"
            action = "replaced"
        }
    }
    @Model final class OdometerReading {
        var bikeID: UUID
        var date: Date
        var distance: Double
        var distanceUnit: String
        init(bikeID: UUID) {
            self.bikeID = bikeID
            date = .now
            distance = 600
            distanceUnit = "mi"
        }
    }
}
