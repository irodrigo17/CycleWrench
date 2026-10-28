import SwiftData

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
        let configuration = ModelConfiguration(cloudKitDatabase:
            usesCloud ? .private(cloudContainerID) : .none)
        return try ModelContainer(for: Bike.self, ServiceEntry.self, OdometerReading.self,
                                  configurations: configuration)
    }
}
