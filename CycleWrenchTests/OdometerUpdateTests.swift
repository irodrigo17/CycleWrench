import XCTest
import SwiftData
@testable import CycleWrench

final class OdometerUpdateTests: XCTestCase {
    @MainActor
    func testUpdateFromRowConvertsUnitsAndCreatesNoService() throws {
        let container = try ModelContainer(for: Bike.self, ServiceEntry.self, OdometerReading.self, CustomComponent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let context = container.mainContext
        let bike = Bike(name: "Test bike", odometer: 100)
        let other = Bike(name: "Other test bike", odometer: 500)
        context.insert(bike)
        context.insert(other)
        try context.save()
        try BikeStore.updateOdometer(bike, distance: 100, unit: "mi", in: context)
        XCTAssertEqual(bike.odometer, 160.9344, accuracy: 0.00001)
        XCTAssertEqual(other.odometer, 500)
        XCTAssertTrue(try context.fetch(FetchDescriptor<ServiceEntry>()).isEmpty)
        let readings = try context.fetch(FetchDescriptor<OdometerReading>())
        XCTAssertEqual(readings.count, 1)
        XCTAssertEqual(readings.first?.bikeID, bike.id)
        XCTAssertEqual(readings.first?.distanceUnit, "km")
    }

    @MainActor
    func testLowerInvalidOrStaleReadingDoesNotChangeData() throws {
        let container = try ModelContainer(for: Bike.self, ServiceEntry.self, OdometerReading.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let context = container.mainContext
        let bike = Bike(name: "Test bike", odometer: 200)
        context.insert(bike)
        context.insert(OdometerReading(bike: bike))
        try context.save()
        bike.odometer = 100 // Stale Bike metadata; the existing reading is authoritative.
        try context.save()
        for value in [150, -1, Double.nan, Double.infinity] {
            XCTAssertThrowsError(try BikeStore.updateOdometer(bike, distance: value, unit: "km", in: context))
        }
        XCTAssertEqual(try context.fetch(FetchDescriptor<OdometerReading>()).count, 1)
        XCTAssertEqual(bike.odometer, 100)
        try BikeStore.updateOdometer(bike, distance: 250, unit: "km", in: context)
        XCTAssertEqual(bike.odometer, 250)
        XCTAssertEqual(try context.fetch(FetchDescriptor<OdometerReading>()).count, 2)
    }
}
