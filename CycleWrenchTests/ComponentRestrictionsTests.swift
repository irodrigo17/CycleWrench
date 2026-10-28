import XCTest
import SwiftData
@testable import CycleWrench

final class ComponentRestrictionsTests: XCTestCase {
    func testUnrestrictedComponentsMatchEverySetup() {
        for drive in BikeConfiguration.Drive.allCases {
            for suspension in BikeConfiguration.Suspension.allCases {
                for brakes in BikeConfiguration.Brakes.allCases {
                    XCTAssertTrue(ComponentRestrictions().matches(
                        BikeConfiguration(drive: drive, suspension: suspension, brakes: brakes)))
                }
            }
        }
    }

    func testElectricAndFullSuspensionRequirementsAreCombined() {
        let requirement = ComponentRestrictions(drive: .electric, suspension: .fullSuspension)
        XCTAssertTrue(requirement.matches(BikeConfiguration(drive: .electric, suspension: .fullSuspension)))
        XCTAssertFalse(requirement.matches(BikeConfiguration(drive: .regular, suspension: .fullSuspension)))
        XCTAssertFalse(requirement.matches(BikeConfiguration(drive: .electric, suspension: .hardtail)))
        XCTAssertFalse(requirement.matches(BikeConfiguration(drive: .electric, suspension: .rigid)))
    }

    func testBrakeRestrictionAndUnsetBikeFields() {
        let requirement = ComponentRestrictions(brakes: .hydraulicDisc)
        XCTAssertTrue(requirement.matches(BikeConfiguration(brakes: .hydraulicDisc)))
        XCTAssertFalse(requirement.matches(BikeConfiguration(brakes: .mechanicalDisc)))
        XCTAssertFalse(requirement.matches(BikeConfiguration(brakes: .rim)))
        // Same progressive setup rule as built-in components: unknown isn't absent.
        XCTAssertTrue(requirement.matches(BikeConfiguration()))
    }

    @MainActor
    func testRestrictionsPersistWithoutChangingRecordedHistory() throws {
        let container = try ModelContainer(for: Bike.self, ServiceEntry.self, OdometerReading.self, CustomComponent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let context = container.mainContext
        let requirement = ComponentRestrictions(drive: .electric, suspension: .fullSuspension, brakes: .hydraulicDisc)
        let custom = try CustomComponentStore.add(name: "Motor mount", defaultAction: .serviced,
            hasPosition: false, restrictions: requirement, in: context)
        let bike = Bike(name: "Test bike", configuration: BikeConfiguration(drive: .electric))
        context.insert(bike)
        context.insert(ServiceEntry(date: .now, odometer: 100, distanceUnit: "mi",
            componentID: custom.descriptor.id, componentName: custom.name, action: .serviced, bikeID: bike.id))
        try context.save()
        let fresh = ModelContext(container)
        let saved = try XCTUnwrap(fresh.fetch(FetchDescriptor<CustomComponent>()).first)
        XCTAssertEqual(saved.restrictions, requirement)
        XCTAssertFalse(saved.restrictions.matches(BikeConfiguration(drive: .regular)))
        XCTAssertEqual(try fresh.fetch(FetchDescriptor<ServiceEntry>()).first?.componentTitle, "Motor mount")
    }

    @MainActor
    func testExistingCustomDefinitionsMigrateAsUnrestricted() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("previous-custom.store")
        try writeOldStore(url)
        let container = try ModelContainer(for: CustomComponent.self,
            configurations: ModelConfiguration(url: url, cloudKitDatabase: .none))
        let saved = try XCTUnwrap(container.mainContext.fetch(FetchDescriptor<CustomComponent>()).first)
        XCTAssertEqual(saved.name, "Grip tape")
        XCTAssertTrue(saved.restrictions.isUnrestricted)
        XCTAssertEqual(saved.descriptor.defaultAction, .replaced)
    }

    @MainActor
    private func writeOldStore(_ url: URL) throws {
        let container = try ModelContainer(for: PriorCatalog.CustomComponent.self,
            configurations: ModelConfiguration(url: url, cloudKitDatabase: .none))
        let context = ModelContext(container)
        context.insert(PriorCatalog.CustomComponent())
        try context.save()
    }
}

private enum PriorCatalog {
    @Model final class CustomComponent {
        var id: UUID = UUID()
        var name: String = ""
        var defaultActionRaw: String = "serviced"
        var hasPosition: Bool = false
        init() { name = "Grip tape"; defaultActionRaw = "replaced" }
    }
}
