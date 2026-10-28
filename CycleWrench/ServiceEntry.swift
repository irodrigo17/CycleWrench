import Foundation
import SwiftData

// Stable raw values form part of the persisted data format.
enum BicycleComponent: String, CaseIterable, Identifiable, Codable {
    case chain, cassette, chainrings
    case frontBrakePads, rearBrakePads, frontRotor, rearRotor
    case frontTire, rearTire, bottomBracket, headset
    case frontHub, rearHub, fork, rearShock, dropperPost
    case bearings, frontBrakeFluid, rearBrakeFluid

    var id: String { rawValue }
    var title: String {
        switch self {
        case .chain: "Chain"
        case .cassette: "Cassette"
        case .chainrings: "Chainrings"
        case .frontBrakePads: "Front brake pads"
        case .rearBrakePads: "Rear brake pads"
        case .frontRotor: "Front brake rotor"
        case .rearRotor: "Rear brake rotor"
        case .frontTire: "Front tire"
        case .rearTire: "Rear tire"
        case .bottomBracket: "Bottom bracket"
        case .headset: "Headset"
        case .frontHub: "Front hub"
        case .rearHub: "Rear hub"
        case .fork: "Suspension fork"
        case .rearShock: "Rear shock"
        case .dropperPost: "Dropper post"
        case .bearings: "Bearings"
        case .frontBrakeFluid: "Front brake bleed"
        case .rearBrakeFluid: "Rear brake bleed"
        }
    }
}

// Presentation categories map to the existing persisted component identifiers.
// Order favors frequently logged work; it is not a prescribed service schedule.
enum ComponentKind: String, CaseIterable, Identifiable {
    case brakePads, chain, fork, rearShock, tires, dropperPost
    case cassette, chainrings, rotors, brakeBleed, bearings, hubs, bottomBracket, headset

    var id: String { rawValue }
    var title: String {
        switch self {
        case .brakePads: "Brake pads"
        case .chain: "Chain"
        case .fork: "Suspension fork"
        case .rearShock: "Rear shock"
        case .tires: "Tires"
        case .dropperPost: "Dropper post"
        case .cassette: "Cassette"
        case .chainrings: "Chainrings"
        case .rotors: "Brake rotors"
        case .brakeBleed: "Brake bleed"
        case .bearings: "Bearings"
        case .hubs: "Wheel hubs"
        case .bottomBracket: "Bottom bracket"
        case .headset: "Headset"
        }
    }

    var hasPosition: Bool {
        switch self {
        case .brakePads, .tires, .rotors, .brakeBleed, .hubs: true
        default: false
        }
    }

    func components(at position: ComponentPosition) -> [BicycleComponent] {
        let pair: (BicycleComponent, BicycleComponent)
        switch self {
        case .brakePads: pair = (.frontBrakePads, .rearBrakePads)
        case .tires: pair = (.frontTire, .rearTire)
        case .rotors: pair = (.frontRotor, .rearRotor)
        case .hubs: pair = (.frontHub, .rearHub)
        case .brakeBleed: pair = (.frontBrakeFluid, .rearBrakeFluid)
        case .bearings: return [.bearings]
        case .chain: return [.chain]
        case .fork: return [.fork]
        case .rearShock: return [.rearShock]
        case .dropperPost: return [.dropperPost]
        case .cassette: return [.cassette]
        case .chainrings: return [.chainrings]
        case .bottomBracket: return [.bottomBracket]
        case .headset: return [.headset]
        }
        switch position {
        case .front: return [pair.0]
        case .rear: return [pair.1]
        case .both: return [pair.0, pair.1]
        }
    }
}

enum ComponentPosition: String, CaseIterable, Identifiable {
    case front, rear, both
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum ServiceAction: String, CaseIterable, Identifiable, Codable {
    case replaced, serviced, unspecified
    static var loggableCases: [ServiceAction] { [.replaced, .serviced] }
    var id: String { rawValue }
    var title: String { self == .unspecified ? "Work recorded" : rawValue.capitalized }
}

@Model
final class ServiceEntry {
    var date: Date = Date()
    var odometer: Double = 0
    var distanceUnit: String = "km"
    var component: String = ""
    var action: String = ""
    var bikeID: UUID? = nil
    var notes: String = ""
    var dateIsKnown: Bool = true
    var importSourceID: String? = nil

    init(date: Date, odometer: Double, distanceUnit: String,
         component: BicycleComponent, action: ServiceAction, bikeID: UUID? = nil,
         notes: String = "", dateIsKnown: Bool = true, importSourceID: String? = nil) {
        self.notes = notes
        self.dateIsKnown = dateIsKnown
        self.importSourceID = importSourceID
        self.bikeID = bikeID
        self.date = date
        self.odometer = odometer
        self.distanceUnit = distanceUnit
        self.component = component.rawValue
        self.action = action.rawValue
    }

    var componentTitle: String {
        BicycleComponent(rawValue: component)?.title ?? component
    }
}
