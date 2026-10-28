import Foundation
import SwiftData

@Model
final class CustomComponent {
    var id: UUID = UUID()
    var name: String = ""
    var defaultActionRaw: String = "serviced"
    var hasPosition: Bool = false

    init(name: String, defaultAction: ServiceAction, hasPosition: Bool = false) {
        self.name = name
        defaultActionRaw = defaultAction.rawValue
        self.hasPosition = hasPosition
    }

    var descriptor: ComponentDescriptor {
        ComponentDescriptor(id: "custom:\(id.uuidString)", title: name, hasPosition: hasPosition,
            defaultAction: ServiceAction(rawValue: defaultActionRaw) ?? .serviced, builtIn: nil)
    }
}

struct LoggedComponent: Hashable {
    let id: String
    let title: String
}

struct ComponentDescriptor: Hashable, Identifiable {
    let id: String
    let title: String
    let hasPosition: Bool
    let defaultAction: ServiceAction
    let builtIn: ComponentKind?

    init(_ kind: ComponentKind) {
        id = "builtin:\(kind.rawValue)"
        title = kind.title
        hasPosition = kind.hasPosition
        defaultAction = kind.defaultAction
        builtIn = kind
    }

    init(id: String, title: String, hasPosition: Bool, defaultAction: ServiceAction, builtIn: ComponentKind?) {
        self.id = id
        self.title = title
        self.hasPosition = hasPosition
        self.defaultAction = defaultAction
        self.builtIn = builtIn
    }

    func components(at position: ComponentPosition) -> [LoggedComponent] {
        if let builtIn {
            return builtIn.components(at: position).map { LoggedComponent(id: $0.rawValue, title: $0.title) }
        }
        guard hasPosition else { return [LoggedComponent(id: id, title: title)] }
        switch position {
        case .front: return [LoggedComponent(id: "\(id):front", title: "\(title) (front)")]
        case .rear: return [LoggedComponent(id: "\(id):rear", title: "\(title) (rear)")]
        case .both: return components(at: .front) + components(at: .rear)
        }
    }
}

@MainActor
enum CustomComponentStore {
    static func add(name: String, defaultAction: ServiceAction, hasPosition: Bool,
                    in context: ModelContext) throws -> CustomComponent {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let existing = try context.fetch(FetchDescriptor<CustomComponent>())
        let names = existing.map(\.name) + ComponentKind.allCases.map(\.title) + BicycleComponent.allCases.map(\.title)
        guard !name.isEmpty else { throw ComponentError.invalid("Enter a component name.") }
        guard ServiceAction.loggableCases.contains(defaultAction) else {
            throw ComponentError.invalid("Choose replaced or serviced as the default action.")
        }
        guard !names.contains(where: { $0.localizedCaseInsensitiveCompare(name) == .orderedSame }) else {
            throw ComponentError.invalid("A component with that name already exists.")
        }
        let component = CustomComponent(name: name, defaultAction: defaultAction, hasPosition: hasPosition)
        context.insert(component)
        do { try context.save() } catch { context.rollback(); throw error }
        return component
    }

    enum ComponentError: LocalizedError {
        case invalid(String)
        var errorDescription: String? { switch self { case .invalid(let message): message } }
    }
}
