import SwiftData
import Foundation

@MainActor
enum AppPersistence {
    static let cloudContainerID = "iCloud.com.cyclewrench"

    static var usesCloud: Bool {
        // Unsigned simulator builds cannot authenticate against a team's container.
        // Keep the same on-disk store, but do not pretend simulator data is uploaded.
        #if targetEnvironment(simulator)
        false
        #else
        true
        #endif
    }

    static func makeContainer() throws -> ModelContainer {
        #if DEBUG
        let isTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil
        #else
        let isTesting = false
        #endif
        let configuration = ModelConfiguration(isStoredInMemoryOnly: isTesting,
            cloudKitDatabase: isTesting ? .none : (usesCloud ? .private(cloudContainerID) : .none))
        return try ModelContainer(for: Bike.self, ServiceEntry.self, OdometerReading.self, CustomComponent.self,
                                  configurations: configuration)
    }
}
