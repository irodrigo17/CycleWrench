import SwiftUI

struct ComponentHealthView: View {
    let bikeName: String
    let estimates: [ComponentEstimate]

    private var estimated: [ComponentEstimate] { estimates.filter { $0.averageInterval != nil } }
    private var learning: [ComponentEstimate] { estimates.filter { $0.averageInterval == nil } }

    var body: some View {
        List {
            if estimates.isEmpty {
                ContentUnavailableView("Learn how your parts last", systemImage: "chart.bar.xaxis",
                    description: Text("Log replacements and services to start tracking component intervals."))
            }
            if !estimated.isEmpty {
                Section {
                    ForEach(estimated) { estimate in
                        ComponentEstimateRow(estimate: estimate)
                    }
                } header: {
                    Text("Soonest attention first")
                } footer: {
                    Text("Based on your own completed intervals. Approaching average means 20% or less of the average distance remains. These are estimates, not measurements of wear.")
                }
            }
            if !learning.isEmpty {
                Section {
                    ForEach(learning) { estimate in
                        ComponentEstimateRow(estimate: estimate)
                    }
                } header: {
                    Text("Learning your intervals")
                } footer: {
                    Text("Two replacements give the first lifespan estimate. Service intervals use consecutive services without a replacement between them. The first record never assumes a part was new at zero miles.")
                }
            }
            Section {
                Text("Suspension also has service intervals in hours and calendar time. Distance history does not track those limits.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Components")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Text(bikeName).font(.caption).foregroundStyle(.secondary)
                .padding(8).frame(maxWidth: .infinity).background(.bar)
        }
    }
}

struct ComponentEstimateRow: View {
    let estimate: ComponentEstimate

    private var tint: Color {
        switch estimate.attention {
        case .pastAverage: .red
        case .approachingAverage: .orange
        case .tracking: .blue
        case .learning: .secondary
        }
    }
    private func distance(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(0)))) \(estimate.unit)"
    }
    private var remainingText: String {
        guard let remaining = estimate.remainingDistance else { return "Learning" }
        if remaining <= 0 { return "~\(distance(abs(remaining))) past average" }
        return "~\(distance(remaining)) left"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(estimate.component.title).font(.headline)
                Spacer()
                Text(remainingText).font(.subheadline).foregroundStyle(tint)
                    .multilineTextAlignment(.trailing)
            }
            Text(estimate.intervalTitle).font(.caption).foregroundStyle(.secondary)
            if let fraction = estimate.fractionUsed {
                ProgressView(value: fraction).tint(tint)
                    .accessibilityLabel("Distance toward historical average")
            }
            if let average = estimate.averageInterval {
                LabeledContent("Average", value: distance(average))
                Text("Based on \(estimate.intervalCount) completed \(estimate.intervalCount == 1 ? "interval" : "intervals")")
                    .font(.caption).foregroundStyle(.secondary)
            } else if estimate.action == .unspecified {
                Text("Future replacements or services will start a known interval.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Log another \(estimate.action == .replaced ? "replacement" : "service") to learn an interval.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let since = estimate.distanceSinceLast {
                LabeledContent(estimate.sinceTitle, value: distance(since))
            }
        }
        .font(.subheadline)
        .padding(.vertical, 6)
    }
}
