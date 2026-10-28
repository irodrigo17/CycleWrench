import XCTest
import SwiftData
@testable import CycleWrench

final class CustomComponentTests: XCTestCase {
    func testDefaultActionsMatchCommonWork() {
        XCTAssertEqual(ComponentKind.chain.defaultAction, .replaced)
        XCTAssertEqual(ComponentKind.brakePads.defaultAction, .replaced)
        XCTAssertEqual(ComponentKind.tires.defaultAction, .replaced)
        XCTAssertEqual(ComponentKind.battery.defaultAction, .replaced)
        XCTAssertEqual(ComponentKind.fork.defaultAction, .serviced)
        XCTAssertEqual(ComponentKind.rearShock.defaultAction, .serviced)
        XCTAssertEqual(ComponentKind.brakeBleed.defaultAction, .serviced)
    }

    @MainActor
    func testCustomDefinitionAndHistoryPersistWithStableIdentity() throws {
        let container = try ModelContainer(for: Bike.self, ServiceEntry.self, OdometerReading.self, CustomComponent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let context = container.mainContext
        let custom = try CustomComponentStore.add(name: "  Chain wax  ", defaultAction: .serviced,
                                                 hasPosition: false, in: context)
        let bike = Bike(name: "Test bike")
        context.insert(bike)
        let descriptor = custom.descriptor
        let component = try XCTUnwrap(descriptor.components(at: .front).first)
        context.insert(ServiceEntry(date: Date(timeIntervalSince1970: 1000), odometer: 100,
            distanceUnit: "mi", componentID: component.id, componentName: component.title,
            action: descriptor.defaultAction, bikeID: bike.id))
        context.insert(ServiceEntry(date: Date(timeIntervalSince1970: 2000), odometer: 250,
            distanceUnit: "mi", componentID: component.id, componentName: component.title,
            action: descriptor.defaultAction, bikeID: bike.id))
        try context.save()
        let fresh = ModelContext(container)
        let stored = try XCTUnwrap(fresh.fetch(FetchDescriptor<CustomComponent>()).first)
        XCTAssertEqual(stored.name, "Chain wax")
        XCTAssertEqual(stored.descriptor.id, descriptor.id)
        XCTAssertEqual(stored.descriptor.defaultAction, .serviced)
        let history = try fresh.fetch(FetchDescriptor<ServiceEntry>())
        let estimate = try XCTUnwrap(ComponentEstimate.calculate(bikeID: bike.id, odometer: 300,
            unit: "mi", events: history.map(MaintenanceEvent.init)).first)
        XCTAssertEqual(estimate.componentTitle, "Chain wax")
        XCTAssertEqual(estimate.averageInterval, 150)
        XCTAssertEqual(estimate.remainingDistance, 100)
        // Removing the catalog definition never erases or renames the recorded work.
        fresh.delete(stored)
        try fresh.save()
        XCTAssertTrue(try fresh.fetch(FetchDescriptor<ServiceEntry>()).allSatisfy { $0.componentTitle == "Chain wax" })
    }

    @MainActor
    func testPairedCustomComponentTracksFrontAndRearSeparately() throws {
        let custom = CustomComponent(name: "Wheel straps", defaultAction: .replaced, hasPosition: true)
        let parts = custom.descriptor.components(at: .both)
        XCTAssertEqual(parts.count, 2)
        XCTAssertNotEqual(parts[0].id, parts[1].id)
        XCTAssertEqual(parts[0].title, "Wheel straps (front)")
        XCTAssertEqual(parts[1].title, "Wheel straps (rear)")
    }

    @MainActor
    func testNamesCannotBeBlankOrDuplicateExistingComponents() throws {
        let container = try ModelContainer(for: CustomComponent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let context = container.mainContext
        XCTAssertThrowsError(try CustomComponentStore.add(name: "  ", defaultAction: .serviced, hasPosition: false, in: context))
        XCTAssertThrowsError(try CustomComponentStore.add(name: "chain", defaultAction: .serviced, hasPosition: false, in: context))
        _ = try CustomComponentStore.add(name: "Grip tape", defaultAction: .replaced, hasPosition: false, in: context)
        XCTAssertThrowsError(try CustomComponentStore.add(name: "GRIP TAPE", defaultAction: .replaced, hasPosition: false, in: context))
        XCTAssertEqual(try context.fetch(FetchDescriptor<CustomComponent>()).count, 1)
    }
}
