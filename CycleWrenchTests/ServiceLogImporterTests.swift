import XCTest
import SwiftData
@testable import CycleWrench

final class ServiceLogImporterTests: XCTestCase {
    @MainActor
    func testUndatedImportIsIdempotentAndConvertsMilesWithoutInventingDates() throws {
        let container = try ModelContainer(for: Bike.self, ServiceEntry.self, OdometerReading.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let context = container.mainContext
        let unrelated = Bike(name: "Commuter", odometer: 50)
        context.insert(unrelated)
        let archive = ServiceLogArchive(id: UUID(), bikeName: "Imported bike", distanceUnit: "mi", records: [
            .init(id: "chain-1", component: .chain, action: .replaced, odometer: 100),
            .init(id: "chain-2", component: .chain, action: .replaced, odometer: 300),
            .init(id: "bearings", component: .bearings, action: .unspecified, odometer: 350,
                  notes: "All frame bearings")
        ])
        let first = try ServiceLogImporter.importArchive(archive, into: context)
        let second = try ServiceLogImporter.importArchive(archive, into: context)
        XCTAssertEqual(first.addedCount, 3)
        XCTAssertEqual(second.addedCount, 0)
        XCTAssertEqual(first.bike.id, second.bike.id)
        XCTAssertEqual(first.bike.odometer, 563.2704, accuracy: 0.00001)
        XCTAssertEqual(unrelated.odometer, 50)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Bike>()).count, 2)
        let entries = try context.fetch(FetchDescriptor<ServiceEntry>())
        XCTAssertEqual(entries.count, 3)
        XCTAssertTrue(entries.allSatisfy { !$0.dateIsKnown && $0.date == .distantPast })
        XCTAssertEqual(entries.first { $0.component == "bearings" }?.notes, "All frame bearings")
        let estimate = try XCTUnwrap(ComponentEstimate.calculate(bikeID: first.bike.id,
            odometer: 350, unit: "mi", events: entries.map(MaintenanceEvent.init)).first)
        XCTAssertEqual(estimate.component, .chain)
        XCTAssertEqual(try XCTUnwrap(estimate.averageInterval), 200, accuracy: 0.00001)
        XCTAssertEqual(try XCTUnwrap(estimate.remainingDistance), 150, accuracy: 0.00001)
        // Unknown actions remain in the journal but do not fabricate life samples.
        let allEstimates = ComponentEstimate.calculate(bikeID: first.bike.id, odometer: 350,
            unit: "mi", events: entries.map(MaintenanceEvent.init))
        XCTAssertEqual(allEstimates.count, 2)
        let bearings = try XCTUnwrap(allEstimates.first { $0.component == .bearings })
        XCTAssertEqual(bearings.action, .unspecified)
        XCTAssertNil(bearings.averageInterval)
        XCTAssertNil(bearings.remainingDistance)
    }

    @MainActor
    func testInvalidArchiveDoesNotCreateBikeOrPartialHistory() throws {
        let container = try ModelContainer(for: Bike.self, ServiceEntry.self, OdometerReading.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let context = container.mainContext
        let archive = ServiceLogArchive(id: UUID(), bikeName: "Invalid", distanceUnit: "mi", records: [
            .init(id: "same", component: .chain, action: .replaced, odometer: 100),
            .init(id: "same", component: .chain, action: .replaced, odometer: 200)
        ])
        XCTAssertThrowsError(try ServiceLogImporter.importArchive(archive, into: context))
        XCTAssertTrue(try context.fetch(FetchDescriptor<Bike>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<ServiceEntry>()).isEmpty)
    }

    func testArchiveDecoderPreservesKnownDatesAndRejectsUnknownComponents() throws {
        let data = Data("""
        {"version":1,"id":"7E541C9F-BCBF-4DAD-BD86-4195E470E726",
         "bikeName":"Test","distanceUnit":"mi","records":[
            {"id":"a","component":"fork","action":"serviced","odometer":100,
             "date":"2026-01-02T12:00:00Z","notes":"Lower leg service"}]}
        """.utf8)
        let archive = try ServiceLogArchive.decode(data)
        XCTAssertNotNil(archive.records[0].date)
        XCTAssertEqual(archive.records[0].notes, "Lower leg service")
        let invalid = Data(String(decoding: data, as: UTF8.self).replacingOccurrences(of: "fork", with: "motorcycleEngine").utf8)
        XCTAssertThrowsError(try ServiceLogArchive.decode(invalid))
    }
}
