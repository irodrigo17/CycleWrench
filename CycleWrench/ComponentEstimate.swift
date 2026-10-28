import Foundation

struct MaintenanceEvent: Sendable {
    var bikeID: UUID?
    var component: String
    var action: String
    var date: Date
    var odometer: Double
    var unit: String

    init(bikeID: UUID?, component: String, action: String, date: Date, odometer: Double, unit: String) {
        self.bikeID = bikeID
        self.component = component
        self.action = action
        self.date = date
        self.odometer = odometer
        self.unit = unit
    }

    init(_ entry: ServiceEntry) {
        self.init(bikeID: entry.bikeID, component: entry.component, action: entry.action,
                  date: entry.date, odometer: entry.odometer, unit: entry.distanceUnit)
    }
}

struct ComponentEstimate: Identifiable {
    enum Attention: Int {
        case pastAverage, approachingAverage, tracking, learning
    }

    let component: BicycleComponent
    let action: ServiceAction
    let unit: String
    let averageInterval: Double?
    let intervalCount: Int
    let distanceSinceLast: Double?
    let lastAction: ServiceAction

    var id: String { "\(component.rawValue)-\(action.rawValue)" }
    var remainingDistance: Double? {
        guard let averageInterval, let distanceSinceLast else { return nil }
        return averageInterval - distanceSinceLast
    }
    var fractionUsed: Double? {
        guard let averageInterval, let distanceSinceLast else { return nil }
        return min(1, max(0, distanceSinceLast / averageInterval))
    }
    var attention: Attention {
        guard let remainingDistance, let averageInterval else { return .learning }
        if remainingDistance <= 0 { return .pastAverage }
        if remainingDistance <= averageInterval * 0.2 { return .approachingAverage }
        return .tracking
    }
    var intervalTitle: String {
        switch action {
        case .replaced: "Replacement life"
        case .serviced: "Service interval"
        case .unspecified: "Action not recorded"
        }
    }
    var sinceTitle: String {
        switch lastAction {
        case .replaced: "Since replacement"
        case .serviced: "Since service"
        case .unspecified: "Since logged work"
        }
    }

    static func calculate(bikeID: UUID, odometer: Double, unit: String,
                          events: [MaintenanceEvent], now: Date = .now) -> [ComponentEstimate] {
        // Normalize explicitly before comparing readings. Stored units remain intact.
        let bikeEvents = events.compactMap { event -> MaintenanceEvent? in
            guard event.bikeID == bikeID, event.date <= now,
                  event.odometer.isFinite, event.odometer >= 0,
                  let distance = DistanceUnit.convert(event.odometer, from: event.unit, to: unit)
            else { return nil }
            var normalized = event
            normalized.odometer = distance
            normalized.unit = unit
            return normalized
        }
        var estimates: [ComponentEstimate] = []
        for component in BicycleComponent.allCases {
            let history = bikeEvents.filter { $0.component == component.rawValue }.sorted {
                if $0.date != $1.date { return $0.date < $1.date }
                if $0.odometer != $1.odometer { return $0.odometer < $1.odometer }
                return $0.action < $1.action
            }
            if let last = history.last,
               !history.contains(where: { $0.action == ServiceAction.replaced.rawValue ||
                                          $0.action == ServiceAction.serviced.rawValue }) {
                estimates.append(ComponentEstimate(component: component, action: .unspecified, unit: unit,
                    averageInterval: nil, intervalCount: 0,
                    distanceSinceLast: odometer.isFinite && odometer >= last.odometer
                        ? odometer - last.odometer : nil, lastAction: .unspecified))
            }
            for action in ServiceAction.loggableCases {
                guard history.contains(where: { $0.action == action.rawValue }) else { continue }
                var previous: MaintenanceEvent?
                var lastReset: MaintenanceEvent?
                var intervals: [Double] = []
                for event in history {
                    // A replacement starts a fresh service cycle; never infer a service
                    // interval across two different installed components.
                    if action == .serviced && event.action == ServiceAction.replaced.rawValue {
                        previous = nil
                        lastReset = event
                    }
                    guard event.action == action.rawValue else { continue }
                    if let previous {
                        let delta = event.odometer - previous.odometer
                        if delta > 0 && delta.isFinite { intervals.append(delta) }
                    }
                    previous = event
                    lastReset = event
                }
                guard let lastReset else { continue }
                let mean = intervals.isEmpty ? nil : intervals.reduce(0) { $0 + $1 / Double(intervals.count) }
                let since = odometer.isFinite && odometer >= lastReset.odometer
                    ? odometer - lastReset.odometer : nil
                estimates.append(ComponentEstimate(component: component, action: action, unit: unit,
                    averageInterval: mean, intervalCount: intervals.count, distanceSinceLast: since,
                    lastAction: ServiceAction(rawValue: lastReset.action) ?? action))
            }
        }
        // Soonest estimated attention first; unknown lifetimes stay at the bottom.
        return estimates.sorted {
            let left = $0.remainingDistance ?? .infinity
            let right = $1.remainingDistance ?? .infinity
            if left != right { return left < right }
            return $0.id < $1.id
        }
    }
}
