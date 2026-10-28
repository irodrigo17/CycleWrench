import SwiftData
import Foundation

enum PersistenceMode: Equatable {
    case inMemoryTests, localOnly, privateCloud

    static func resolve(isTesting: Bool, cloudEnabledInBuild: Bool, localOnlyRequested: Bool) -> Self {
        if isTesting { return .inMemoryTests }
        return cloudEnabledInBuild && !localOnlyRequested ? .privateCloud : .localOnly
    }
}

@MainActor
enum AppPersistence {
    static let cloudContainerID = "iCloud.com.cyclewrench"

    static var mode: PersistenceMode {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        let isTesting = environment["XCTestConfigurationFilePath"] != nil
            || environment["CYCLEWRENCH_TESTING"] == "1" || NSClassFromString("XCTestCase") != nil
        let localOnlyRequested = environment["CYCLEWRENCH_LOCAL_ONLY"] == "1"
        #else
        let isTesting = false
        let localOnlyRequested = false
        #endif
        return PersistenceMode.resolve(isTesting: isTesting,
            cloudEnabledInBuild: cloudEnabled(infoValue: Bundle.main.object(forInfoDictionaryKey: "CycleWrenchCloudSyncEnabled")),
            localOnlyRequested: localOnlyRequested)
    }

    static var usesCloud: Bool { mode == .privateCloud }

    static func cloudEnabled(infoValue: Any?) -> Bool {
        if let value = infoValue as? String { return ["YES", "TRUE", "1"].contains(value.uppercased()) }
        return (infoValue as? NSNumber)?.boolValue ?? false
    }

    static func makeContainer() throws -> ModelContainer {
        let selectedMode = mode
        let configuration = ModelConfiguration(isStoredInMemoryOnly: selectedMode == .inMemoryTests,
            cloudKitDatabase: selectedMode == .privateCloud ? .private(cloudContainerID) : .none)
        return try ModelContainer(for: Bike.self, ServiceEntry.self, OdometerReading.self, CustomComponent.self,
                                  configurations: configuration)
    }
}
