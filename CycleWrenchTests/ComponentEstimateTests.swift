import XCTest
@testable import CycleWrench

final class ComponentEstimateTests: XCTestCase {
    private let bikeID = UUID()
    private let start = Date(timeIntervalSince1970: 1_000_000)

    private func event(_ odometer: Double, day: Double,
                       component: BicycleComponent = .chain,
                       action: ServiceAction = .replaced, unit: String = "mi",
                       bikeID: UUID? = nil) -> MaintenanceEvent {
        MaintenanceEvent(bikeID: bikeID ?? self.bikeID, component: component.rawValue,
            action: action.rawValue, date: start.addingTimeInterval(day * 86400),
            odometer: odometer, unit: unit)
    }

    private func calculate(_ events: [MaintenanceEvent], odometer: Double = 3000,
                           unit: String = "mi") -> [ComponentEstimate] {
        ComponentEstimate.calculate(bikeID: bikeID, odometer: odometer, unit: unit,
            events: events, now: start.addingTimeInterval(100 * 86400))
    }

    func testAverageUsesOnlyCompletedIntervalsAndRemainingUsesCurrentOdometer() throws {
        let result = try XCTUnwrap(calculate([
            event(500, day: 1), event(1500, day: 2), event(2700, day: 3)
        ]).first)
        XCTAssertEqual(result.averageInterval, 1100)
        XCTAssertEqual(result.intervalCount, 2)
        XCTAssertEqual(result.distanceSinceLast, 300)
        XCTAssertEqual(result.remainingDistance, 800)
        XCTAssertEqual(result.attention, .tracking)
    }

    func testSingleRecordHasNoInventedLifespan() throws {
        let result = try XCTUnwrap(calculate([event(2000, day: 1)]).first)
        XCTAssertNil(result.averageInterval)
        XCTAssertNil(result.remainingDistance)
        XCTAssertEqual(result.intervalCount, 0)
        XCTAssertEqual(result.distanceSinceLast, 1000)
        XCTAssertEqual(result.attention, .learning)
    }

    func testDifferentBikesAndFrontRearAreIsolated() throws {
        let results = calculate([
            event(1000, day: 1), event(2000, day: 2),
            event(9000, day: 3, bikeID: UUID()),
            event(100, day: 1, component: .frontBrakePads),
            event(500, day: 2, component: .frontBrakePads),
            event(900, day: 3, component: .rearBrakePads)
        ])
        XCTAssertEqual(results.first { $0.component == .chain }?.averageInterval, 1000)
        XCTAssertEqual(results.first { $0.component == .frontBrakePads }?.averageInterval, 400)
        XCTAssertNil(results.first { $0.component == .rearBrakePads }?.averageInterval)
    }

    func testServicingDoesNotResetReplacementLife() throws {
        let result = try XCTUnwrap(calculate([
            event(1000, day: 1), event(2000, day: 2),
            event(2900, day: 3, action: .serviced)
        ]).first { $0.action == .replaced })
        XCTAssertEqual(result.averageInterval, 1000)
        XCTAssertEqual(result.distanceSinceLast, 1000)
        XCTAssertEqual(result.remainingDistance, 0)
        XCTAssertEqual(result.attention, .pastAverage)
    }

    func testReplacementBreaksServiceIntervalAndResetsServiceDistance() throws {
        let results = calculate([
            event(100, day: 1, component: .fork, action: .serviced),
            event(300, day: 2, component: .fork, action: .serviced),
            event(600, day: 3, component: .fork),
            event(800, day: 4, component: .fork, action: .serviced),
            event(1100, day: 5, component: .fork, action: .serviced),
            event(1200, day: 6, component: .fork)
        ], odometer: 1250)
        let service = try XCTUnwrap(results.first { $0.action == .serviced })
        XCTAssertEqual(service.intervalCount, 2)
        XCTAssertEqual(service.averageInterval, 250)
        XCTAssertEqual(service.distanceSinceLast, 50)
        XCTAssertEqual(service.lastAction, .replaced)
    }

    func testExplicitConversionKeepsMixedUnitHistoryAndGlobalDisplayConsistent() throws {
        let events = [event(100, day: 1), event(321.8688, day: 2, unit: "km")]
        let miles = try XCTUnwrap(calculate(events, odometer: 220).first)
        let kilometers = try XCTUnwrap(calculate(events, odometer: 354.05568, unit: "km").first)
        XCTAssertEqual(try XCTUnwrap(miles.averageInterval), 100, accuracy: 0.00001)
        XCTAssertEqual(try XCTUnwrap(miles.remainingDistance), 80, accuracy: 0.00001)
        XCTAssertEqual(try XCTUnwrap(kilometers.averageInterval), 160.9344, accuracy: 0.00001)
        XCTAssertEqual(try XCTUnwrap(kilometers.remainingDistance), 128.74752, accuracy: 0.00001)
        XCTAssertEqual(miles.attention, kilometers.attention)
    }

    func testInvalidDuplicateAndFutureReadingsDoNotInventIntervals() throws {
        let result = try XCTUnwrap(calculate([
            event(.nan, day: 0), event(-1, day: 0),
            event(1000, day: 1), event(1000, day: 2),
            event(900, day: 3), event(1400, day: 4),
            event(9999, day: 101), event(9999, day: 4, unit: "unknown")
        ], odometer: 1500).first)
        XCTAssertEqual(result.intervalCount, 1)
        XCTAssertEqual(result.averageInterval, 500)
        XCTAssertEqual(result.remainingDistance, 400)
    }

    func testAttentionSortsPastAverageThenApproachingThenTrackingThenUnknown() {
        let results = calculate([
            event(100, day: 1), event(200, day: 2),
            event(0, day: 1, component: .frontBrakePads),
            event(200, day: 2, component: .frontBrakePads),
            event(0, day: 1, component: .rearBrakePads),
            event(300, day: 2, component: .rearBrakePads),
            event(10, day: 1, component: .frontTire)
        ], odometer: 370)
        XCTAssertEqual(results.map(\.component), [.chain, .frontBrakePads, .rearBrakePads, .frontTire])
        XCTAssertEqual(results.map(\.attention), [.pastAverage, .approachingAverage, .tracking, .learning])
    }

    func testOdometerBehindLatestRecordDoesNotShowNegativeUsage() throws {
        let result = try XCTUnwrap(calculate([event(100, day: 1), event(400, day: 2)],
                                            odometer: 370).first)
        XCTAssertNil(result.distanceSinceLast)
        XCTAssertNil(result.remainingDistance)
        XCTAssertEqual(result.attention, .learning)
    }

    func testNoHistoryReturnsEmpty() {
        XCTAssertTrue(calculate([]).isEmpty)
    }
}
