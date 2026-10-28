import Foundation

enum DistanceUnit: String, CaseIterable, Identifiable {
    case kilometers = "km"
    case miles = "mi"

    var id: String { rawValue }
    var title: String { self == .kilometers ? "Kilometers" : "Miles" }

    static func convert(_ distance: Double, from: String, to: String) -> Double? {
        guard let source = DistanceUnit(rawValue: from), let target = DistanceUnit(rawValue: to) else { return nil }
        guard source != target else { return distance }
        return source == .miles ? distance * 1.609344 : distance / 1.609344
    }
}
