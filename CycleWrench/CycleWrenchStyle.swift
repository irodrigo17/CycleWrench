import SwiftUI

enum CycleWrenchStyle {
    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)

    static func statusColor(_ attention: ComponentEstimate.Attention) -> Color {
        switch attention {
        case .pastAverage: Color(uiColor: .systemRed)
        case .approachingAverage: Color(uiColor: .systemOrange)
        case .tracking: Color(uiColor: .systemGreen)
        case .learning: .secondary
        }
    }
}

struct ComponentStatusBadge: View {
    let attention: ComponentEstimate.Attention
    private var text: String {
        switch attention {
        case .pastAverage: "Past average"
        case .approachingAverage: "Near average"
        case .tracking: "Tracking"
        case .learning: "Learning"
        }
    }
    private var symbol: String {
        switch attention {
        case .pastAverage: "exclamationmark.circle.fill"
        case .approachingAverage: "clock.fill"
        case .tracking: "checkmark.circle"
        case .learning: "questionmark.circle"
        }
    }
    var body: some View {
        let color = CycleWrenchStyle.statusColor(attention)
        Label(text, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 9).padding(.vertical, 6)
            .background(color.opacity(0.12), in: Capsule())
    }
}
