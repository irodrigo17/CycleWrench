import Foundation

struct BikeConfiguration: Codable, Equatable {
    enum Drive: String, Codable, CaseIterable, Identifiable {
        case unspecified, regular, electric
        var id: String { rawValue }
        var title: String {
            switch self {
            case .unspecified: "Not set"
            case .regular: "Regular"
            case .electric: "Electric"
            }
        }
    }

    enum Suspension: String, Codable, CaseIterable, Identifiable {
        case unspecified, fullSuspension, hardtail, rigid
        var id: String { rawValue }
        var title: String {
            switch self {
            case .unspecified: "Not set"
            case .fullSuspension: "Full suspension"
            case .hardtail: "Hardtail"
            case .rigid: "Rigid"
            }
        }
    }

    enum Brakes: String, Codable, CaseIterable, Identifiable {
        case unspecified, hydraulicDisc, mechanicalDisc, rim, hydraulicRim
        var id: String { rawValue }
        var title: String {
            switch self {
            case .unspecified: "Not set"
            case .hydraulicDisc: "Hydraulic disc"
            case .mechanicalDisc: "Mechanical disc"
            case .rim: "Rim"
            case .hydraulicRim: "Hydraulic rim"
            }
        }
    }

    var drive: Drive = .unspecified
    var suspension: Suspension = .unspecified
    var brakes: Brakes = .unspecified

    func supports(_ component: ComponentKind) -> Bool {
        switch component {
        case .motor, .battery:
            drive != .regular
        case .fork:
            suspension != .rigid
        case .rearShock:
            suspension == .unspecified || suspension == .fullSuspension
        case .rotors:
            brakes == .unspecified || brakes == .hydraulicDisc || brakes == .mechanicalDisc
        case .brakeBleed:
            brakes == .unspecified || brakes == .hydraulicDisc || brakes == .hydraulicRim
        default:
            true
        }
    }

    // Optional import configuration only fills fields the rider hasn't set.
    func fillingUnspecified(from imported: BikeConfiguration) -> BikeConfiguration {
        BikeConfiguration(drive: drive == .unspecified ? imported.drive : drive,
            suspension: suspension == .unspecified ? imported.suspension : suspension,
            brakes: brakes == .unspecified ? imported.brakes : brakes)
    }
}
