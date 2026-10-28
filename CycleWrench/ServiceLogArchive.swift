import Foundation
import SwiftData

struct ServiceLogArchive: Codable {
    var version: Int = 1
    // Stable archive ID is also the imported bike's ID. Re-importing merges it.
    var id: UUID
    var bikeName: String
    var distanceUnit: String
    var records: [Record]
    var configuration: BikeConfiguration? = nil

    struct Record: Codable {
        var id: String
        var component: BicycleComponent
        var action: ServiceAction
        var odometer: Double
        var date: Date?
        var notes: String?
    }

    static func decode(_ data: Data) throws -> ServiceLogArchive {
        guard data.count <= 5_000_000 else { throw ImportError.invalid("The file is too large.") }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let archive = try decoder.decode(ServiceLogArchive.self, from: data)
        try archive.validate()
        return archive
    }

    func validate() throws {
        guard version == 1 else { throw ImportError.invalid("This archive version isn’t supported.") }
        guard !bikeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              DistanceUnit(rawValue: distanceUnit) != nil,
              !records.isEmpty, records.count <= 10_000 else {
            throw ImportError.invalid("The file needs a bike name, valid distance unit, and service records.")
        }
        guard Set(records.map(\.id)).count == records.count,
              records.allSatisfy({ !$0.id.isEmpty && $0.odometer.isFinite && $0.odometer >= 0 }) else {
            throw ImportError.invalid("Records need unique identifiers and valid, nonnegative odometers.")
        }
    }

    enum ImportError: LocalizedError {
        case invalid(String)
        var errorDescription: String? {
            switch self { case .invalid(let message): message }
        }
    }
}

@MainActor
enum ServiceLogImporter {
    struct Result {
        let bike: Bike
        let addedCount: Int
    }

    static func importArchive(_ archive: ServiceLogArchive, into context: ModelContext) throws -> Result {
        try archive.validate()
        let bikes = try context.fetch(FetchDescriptor<Bike>())
        let existing = try context.fetch(FetchDescriptor<ServiceEntry>())
        let sourceIDs = Set(existing.compactMap(\.importSourceID))
        let bike = bikes.first { $0.id == archive.id } ?? Bike(name: archive.bikeName)
        if !bikes.contains(where: { $0.id == archive.id }) {
            bike.id = archive.id
            context.insert(bike)
        }
        if let configuration = archive.configuration {
            bike.configuration = bike.configuration.fillingUnspecified(from: configuration)
        }
        var count = 0
        for record in archive.records {
            let sourceID = "\(archive.id.uuidString)/\(record.id)"
            guard !sourceIDs.contains(sourceID) else { continue }
            let distance = BikeStore.convert(record.odometer, from: archive.distanceUnit, to: bike.distanceUnit)
            context.insert(ServiceEntry(date: record.date ?? .distantPast, odometer: distance,
                distanceUnit: bike.distanceUnit, component: record.component, action: record.action,
                bikeID: bike.id, notes: record.notes ?? "", dateIsKnown: record.date != nil,
                importSourceID: sourceID))
            bike.odometer = max(bike.odometer, distance)
            count += 1
        }
        do {
            try context.save()
            return Result(bike: bike, addedCount: count)
        } catch {
            context.rollback()
            throw error
        }
    }
}
