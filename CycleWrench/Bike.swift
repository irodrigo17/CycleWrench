import Foundation
import SwiftData

@Model
final class Bike {
    var id: UUID = UUID()
    var name: String
    var distanceUnit: String
    var odometer: Double

    init(name: String, distanceUnit: String = "km", odometer: Double = 0) {
        self.name = name
        self.distanceUnit = distanceUnit
        self.odometer = odometer
    }
}

@Model
final class OdometerReading {
    var bikeID: UUID
    var date: Date
    var distance: Double
    var distanceUnit: String

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

    static func convert(_ distance: Double, from: String, to: String) -> Double {
        guard from != to else { return distance }
        return from == "mi" ? distance * 1.609344 : distance / 1.609344
    }
}
