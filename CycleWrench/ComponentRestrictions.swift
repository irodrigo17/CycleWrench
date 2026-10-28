import Foundation

struct ComponentRestrictions: Equatable {
    var drive: BikeConfiguration.Drive = .unspecified
    var suspension: BikeConfiguration.Suspension = .unspecified
    var brakes: BikeConfiguration.Brakes = .unspecified

    var isUnrestricted: Bool {
        drive == .unspecified && suspension == .unspecified && brakes == .unspecified
    }

    func matches(_ bike: BikeConfiguration) -> Bool {
        (drive == .unspecified || bike.drive == .unspecified || drive == bike.drive)
            && (suspension == .unspecified || bike.suspension == .unspecified || suspension == bike.suspension)
            && (brakes == .unspecified || bike.brakes == .unspecified || brakes == bike.brakes)
    }
}
