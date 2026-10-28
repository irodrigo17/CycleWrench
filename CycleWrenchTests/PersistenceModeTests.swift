import XCTest
@testable import CycleWrench

final class PersistenceModeTests: XCTestCase {
    func testNormalSignedBuildEnablesCloudWithoutExcludingSimulator() {
        XCTAssertEqual(PersistenceMode.resolve(isTesting: false, cloudEnabledInBuild: true,
                                               localOnlyRequested: false), .privateCloud)
    }

    func testUnsignedBuildUsesLocalStorage() {
        XCTAssertEqual(PersistenceMode.resolve(isTesting: false, cloudEnabledInBuild: false,
                                               localOnlyRequested: false), .localOnly)
    }

    func testExplicitLocalCaptureDoesNotContactICloud() {
        XCTAssertEqual(PersistenceMode.resolve(isTesting: false, cloudEnabledInBuild: true,
                                               localOnlyRequested: true), .localOnly)
    }

    func testAutomatedTestsAlwaysWinOverCloudBuildSettings() {
        for cloud in [true, false] {
            for local in [true, false] {
                XCTAssertEqual(PersistenceMode.resolve(isTesting: true, cloudEnabledInBuild: cloud,
                                                       localOnlyRequested: local), .inMemoryTests)
            }
        }
    }

    @MainActor
    func testExpandedBuildSettingHandlesStringAndPlistBooleanValues() {
        for value in ["YES", "yes", "TRUE", "1"] {
            XCTAssertTrue(AppPersistence.cloudEnabled(infoValue: value))
        }
        for value in ["NO", "false", "0", "$(CODE_SIGNING_ALLOWED)", ""] {
            XCTAssertFalse(AppPersistence.cloudEnabled(infoValue: value))
        }
        XCTAssertTrue(AppPersistence.cloudEnabled(infoValue: NSNumber(value: true)))
        XCTAssertFalse(AppPersistence.cloudEnabled(infoValue: NSNumber(value: false)))
        XCTAssertFalse(AppPersistence.cloudEnabled(infoValue: nil))
    }
}
