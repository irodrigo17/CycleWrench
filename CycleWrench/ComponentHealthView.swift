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
            } else {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(bikeName.uppercased()).font(.caption.weight(.semibold))
                            .tracking(1).foregroundStyle(.secondary)
                        Text("Know what’s next.").font(.system(.title2, design: .rounded).bold())
                        if let next = estimates.first, let remaining = next.remainingDistance {
                            Text(next.componentTitle).font(.headline)
                            Text("~\(abs(remaining).formatted(.number.precision(.fractionLength(0)))) \(next.unit) \(remaining <= 0 ? "past average" : "left")")
                                .font(.system(.title, design: .rounded).bold()).monospacedDigit()
                                .foregroundStyle(CycleWrenchStyle.statusColor(next.attention))
                            Text("Personal estimate · \(next.intervalCount) completed \(next.intervalCount == 1 ? "interval" : "intervals")")
                                .font(.caption).foregroundStyle(.secondary)
                        } else {
                            Text("Your first completed intervals will reveal how long each part usually lasts.")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(CycleWrenchStyle.card)
            }
            if !estimated.isEmpty {
                Section {
                    ForEach(estimated) { ComponentEstimateRow(estimate: $0) }
                } header: {
                    Text("Soonest attention first")
                } footer: {
                    Text("Based on your own completed intervals. Near average means 20% or less of the average distance remains. These are distance estimates, not measurements of wear.")
                }
                .listRowBackground(CycleWrenchStyle.card)
            }
            if !learning.isEmpty {
                Section {
                    ForEach(learning) { ComponentEstimateRow(estimate: $0) }
                } header: {
                    Text("Learning your intervals")
                } footer: {
                    Text("Two replacements give the first lifespan estimate. Service intervals use consecutive services without a replacement between them. The first record never assumes a part was new at zero miles.")
                }
                .listRowBackground(CycleWrenchStyle.card)
            }
            Section {
                Text("Suspension also has service intervals in hours and calendar time. Distance history does not track those limits.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .listRowBackground(CycleWrenchStyle.card)
        }
        .scrollContentBackground(.hidden)
        .background(CycleWrenchStyle.canvas)
        .navigationTitle("Components")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ComponentEstimateRow: View {
    let estimate: ComponentEstimate
    private var tint: Color { CycleWrenchStyle.statusColor(estimate.attention) }
    private func distance(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(0)))) \(estimate.unit)"
    }
    private var remainingText: String {
        guard let remaining = estimate.remainingDistance else { return "Learning your interval" }
        if remaining == 0 { return "At your average" }
        if remaining < 0 { return "~\(distance(abs(remaining))) past average" }
        return "~\(distance(remaining)) left"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(estimate.componentTitle).font(.headline)
                    Text(estimate.intervalTitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                ComponentStatusBadge(attention: estimate.attention)
            }
            Text(remainingText)
                .font(.system(estimate.remainingDistance == nil ? .headline : .title2, design: .rounded).bold())
                .monospacedDigit().foregroundStyle(tint)
            if let fraction = estimate.fractionUsed {
                ProgressView(value: fraction).tint(tint)
                    .accessibilityLabel("Distance toward historical average")
            }
            if let average = estimate.averageInterval {
                LabeledContent("Personal average", value: distance(average))
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
        .padding(.vertical, 12)
    }
}
