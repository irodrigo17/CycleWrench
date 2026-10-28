import SwiftUI
import SwiftData

@main
struct CycleWrenchApp: App {
    var body: some Scene {
        WindowGroup {
            MaintenanceLogView()
        }
        .modelContainer(for: [Bike.self, ServiceEntry.self, OdometerReading.self])
    }
}
