import XCTest
import SwiftData
@testable import CycleWrench

final class BikeConfigurationTests: XCTestCase {
    func testRegularRigidRimBikeOnlyOffersApplicableComponents() {
        let setup = BikeConfiguration(drive: .regular, suspension: .rigid, brakes: .rim)
        let available = ComponentKind.allCases.filter(setup.supports)
        XCTAssertFalse(available.contains(.motor))
        XCTAssertFalse(available.contains(.battery))
        XCTAssertFalse(available.contains(.fork))
        XCTAssertFalse(available.contains(.rearShock))
        XCTAssertFalse(available.contains(.rotors))
        XCTAssertFalse(available.contains(.brakeBleed))
        for common in [ComponentKind.chain, .brakePads, .tires, .bearings, .headset, .dropperPost] {
            XCTAssertTrue(available.contains(common))
        }
    }

    func testElectricHardtailWithMechanicalDiscsHidesShockAndBleed() {
        let setup = BikeConfiguration(drive: .electric, suspension: .hardtail, brakes: .mechanicalDisc)
        XCTAssertTrue(setup.supports(.motor))
        XCTAssertTrue(setup.supports(.battery))
        XCTAssertTrue(setup.supports(.fork))
        XCTAssertTrue(setup.supports(.rotors))
        XCTAssertFalse(setup.supports(.rearShock))
        XCTAssertFalse(setup.supports(.brakeBleed))
    }

    func testElectricFullSuspensionHydraulicDiscBikeOffersEveryComponent() {
        let setup = BikeConfiguration(drive: .electric, suspension: .fullSuspension, brakes: .hydraulicDisc)
        XCTAssertTrue(ComponentKind.allCases.allSatisfy(setup.supports))
        XCTAssertEqual(ComponentKind.motor.components(at: .both), [.motor])
        XCTAssertEqual(ComponentKind.battery.components(at: .front), [.battery])
    }

    func testHydraulicRimBrakesAllowBleedingButNeverRotors() {
        let setup = BikeConfiguration(brakes: .hydraulicRim)
        XCTAssertTrue(setup.supports(.brakePads))
        XCTAssertTrue(setup.supports(.brakeBleed))
        XCTAssertFalse(setup.supports(.rotors))
    }

    func testUnknownConfigurationDoesNotHideLegacyOptions() {
        XCTAssertTrue(ComponentKind.allCases.allSatisfy(BikeConfiguration().supports))
    }

    @MainActor
    func testSetupPersistsAndChangingItKeepsOldComponentHistory() throws {
        let container = try ModelContainer(for: Bike.self, ServiceEntry.self, OdometerReading.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let context = container.mainContext
        let bike = Bike(name: "Configured bike", configuration:
            BikeConfiguration(drive: .electric, suspension: .fullSuspension, brakes: .hydraulicDisc))
        context.insert(bike)
        let battery = ServiceEntry(date: .now, odometer: 100, distanceUnit: "km",
            component: .battery, action: .replaced, bikeID: bike.id, notes: "Warranty replacement")
        context.insert(battery)
        try context.save()
        let fresh = ModelContext(container)
        let storedBike = try XCTUnwrap(fresh.fetch(FetchDescriptor<Bike>()).first)
        XCTAssertEqual(storedBike.configuration, bike.configuration)
        storedBike.configuration = BikeConfiguration(drive: .regular, suspension: .rigid, brakes: .rim)
        try fresh.save()
        XCTAssertFalse(storedBike.configuration.supports(.battery))
        let storedEvent = try XCTUnwrap(fresh.fetch(FetchDescriptor<ServiceEntry>()).first)
        XCTAssertEqual(storedEvent.component, "battery")
        XCTAssertEqual(storedEvent.notes, "Warranty replacement")
        XCTAssertEqual(storedEvent.bikeID, storedBike.id)
    }

    @MainActor
    func testFutureConfigurationValuesFallBackToUnspecified() {
        let bike = Bike(name: "Future bike")
        bike.driveType = "futureDrive"
        bike.suspensionType = "futureSuspension"
        bike.brakeType = "futureBrakes"
        XCTAssertEqual(bike.configuration, BikeConfiguration())
    }

    @MainActor
    func testImportFillsUnsetSetupWithoutOverwritingRiderChoices() throws {
        let container = try ModelContainer(for: Bike.self, ServiceEntry.self, OdometerReading.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let context = container.mainContext
        let bike = Bike(name: "Existing", configuration: BikeConfiguration(drive: .regular))
        context.insert(bike)
        let archive = ServiceLogArchive(id: bike.id, bikeName: "Existing", distanceUnit: "km", records: [
            .init(id: "service", component: .chain, action: .replaced, odometer: 100)
        ], configuration: BikeConfiguration(drive: .electric, suspension: .hardtail, brakes: .mechanicalDisc))
        let result = try ServiceLogImporter.importArchive(archive, into: context)
        XCTAssertEqual(result.bike.configuration,
            BikeConfiguration(drive: .regular, suspension: .hardtail, brakes: .mechanicalDisc))
    }
}
