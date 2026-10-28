import Foundation
import SwiftData

@Model
final class Bike {
    var id: UUID = UUID()
    var name: String = ""
    var distanceUnit: String = "km"
    var odometer: Double = 0
    // Additive scalar fields keep older stores and private CloudKit compatible.
    var driveType: String = "unspecified"
    var suspensionType: String = "unspecified"
    var brakeType: String = "unspecified"

    var configuration: BikeConfiguration {
        get {
            BikeConfiguration(drive: .init(rawValue: driveType) ?? .unspecified,
                suspension: .init(rawValue: suspensionType) ?? .unspecified,
                brakes: .init(rawValue: brakeType) ?? .unspecified)
        }
        set {
            driveType = newValue.drive.rawValue
            suspensionType = newValue.suspension.rawValue
            brakeType = newValue.brakes.rawValue
        }
    }

    init(name: String, distanceUnit: String = "km", odometer: Double = 0,
         configuration: BikeConfiguration = BikeConfiguration()) {
        self.name = name
        self.distanceUnit = distanceUnit
        self.odometer = odometer
        self.configuration = configuration
    }
}

@Model
final class OdometerReading {
    var bikeID: UUID = UUID()
    var date: Date = Date()
    var distance: Double = 0
    var distanceUnit: String = "km"

    init(bike: Bike, date: Date = .now) {
        bikeID = bike.id
        self.date = date
        distance = bike.odometer
        distanceUnit = bike.distanceUnit
    }
}

@MainActor
enum BikeStore {
    // The optional bikeID permits lightweight migration of the original store.
    // Adoption and bike creation save atomically, making this safe to retry.
    static func adoptLegacyEntries(in context: ModelContext, preferredUnit: String) throws {
        let entries = try context.fetch(FetchDescriptor<ServiceEntry>()).filter { $0.bikeID == nil }
        guard !entries.isEmpty else { return }
        let unit = entries.max(by: { $0.date < $1.date })?.distanceUnit ?? preferredUnit
        let current = entries.map { convert($0.odometer, from: $0.distanceUnit, to: unit) }.max() ?? 0
        let bike = Bike(name: "My bike", distanceUnit: unit, odometer: current)
        context.insert(bike)
        for entry in entries { entry.bikeID = bike.id }
        do { try context.save() } catch { context.rollback(); throw error }
    }

    static func currentOdometer(for bike: Bike, entries: [ServiceEntry], readings: [OdometerReading]) -> Double {
        // Immutable readings protect against an older device overwriting Bike.odometer
        // with a stale value when iCloud merges offline changes.
        let serviceDistances = entries.filter { $0.bikeID == bike.id }.compactMap {
            DistanceUnit.convert($0.odometer, from: $0.distanceUnit, to: bike.distanceUnit)
        }
        let readingDistances = readings.filter { $0.bikeID == bike.id }.compactMap {
            DistanceUnit.convert($0.distance, from: $0.distanceUnit, to: bike.distanceUnit)
        }
        return ([bike.odometer] + serviceDistances + readingDistances)
            .filter { $0.isFinite && $0 >= 0 }.max() ?? 0
    }

    static func convert(_ distance: Double, from: String, to: String) -> Double {
        DistanceUnit.convert(distance, from: from, to: to) ?? distance
    }
}
