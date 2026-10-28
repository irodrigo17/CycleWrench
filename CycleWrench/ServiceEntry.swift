import Foundation
import SwiftData

// Stable raw values form part of the persisted data format.
enum BicycleComponent: String, CaseIterable, Identifiable, Codable {
    case chain, cassette, chainrings
    case frontBrakePads, rearBrakePads, frontRotor, rearRotor
    case frontTire, rearTire, bottomBracket, headset
    case frontHub, rearHub, fork, rearShock, dropperPost

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
        }
    }
}

enum ServiceAction: String, CaseIterable, Identifiable {
    case replaced, serviced
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

@Model
final class ServiceEntry {
    var date: Date
    var odometer: Double
    var distanceUnit: String
    var component: String
    var action: String

    init(date: Date, odometer: Double, distanceUnit: String,
         component: BicycleComponent, action: ServiceAction) {
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
