import SwiftUI
import Charts

struct PostBlockAssessmentView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PostBlockAssessmentViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    e1rmSection
                    questionnaireSection
                    decisionSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Post-Block Assessment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            viewModel.refresh(appState: appState)
        }
    }

    private var e1rmSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Step 1: e1RM Trend")
                .font(.headline)
            Text("Review how your top lift has moved this block.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let snapshot = viewModel.snapshot {
                E1RMChart(history: snapshot.e1RMHistory, blockPhases: snapshot.blockPhaseSegments)
                    .frame(minHeight: 260)
                if let label = viewModel.trendLabel {
                    Text(label)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Log at least one Tier 1 lift to view trends.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var questionnaireSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Step 2: Recovery Check")
                .font(.headline)
            Text("Rate the last week. Lower sleep, higher stress, and more aches will bias the recommendation toward a deload.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            questionSlider(
                title: "Sleep Quality",
                caption: "Average hours + restfulness",
                value: $viewModel.responses.sleepQuality,
                range: 0...10,
                tint: .blue
            )

            questionSlider(
                title: "Stress",
                caption: "Lifestyle and training stress",
                value: $viewModel.responses.stressLevel,
                range: 0...10,
                tint: .orange
            )

            questionSlider(
                title: "Aches & Pains",
                caption: "Nagging joints or soreness",
                value: $viewModel.responses.acheLevel,
                range: 0...10,
                tint: .red
            )

            HStack {
                Label(viewModel.responses.readinessLabel, systemImage: "waveform.path.ecg")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(viewModel.readinessHint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var decisionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Step 3: Choose the Plan")
                .font(.headline)
            Text(viewModel.recommendationCopy)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 12) {
                decisionButton(for: .deload, isPrimary: false)
                decisionButton(for: .nextBlock, isPrimary: true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func questionSlider(
        title: String,
        caption: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    Text(caption)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(String(format: "%.0f", value.wrappedValue))
                    .font(.title3.weight(.semibold))
            }

            Slider(value: value, in: range, step: 1)
                .tint(tint)
        }
    }

    private func decisionButton(for decision: PostBlockDecision, isPrimary: Bool) -> some View {
        Button {
            appState.completePostBlockAssessment(decision: decision, responses: viewModel.responses)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(decision.title)
                    .font(.headline)
                Text(decision.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(isPrimary ? .borderedProminent : .bordered)
        .tint(decision == .deload ? .orange : .blue)
    }
}

@MainActor
final class PostBlockAssessmentViewModel: ObservableObject {
    @Published var responses = PostBlockResponses()
    @Published var snapshot: AnalyticsSnapshot?

    func refresh(appState: AppState) {
        snapshot = appState.analyticsSnapshots.first
    }

    var trendLabel: String? {
        guard let delta = trendDelta else { return nil }
        let prefix = delta >= 0 ? "Progressing" : "Stalled"
        return "\(prefix): \(String(format: "%.1f", delta)) lb change across the block"
    }

    var readinessHint: String {
        switch responses.recoveryRiskScore {
        case 0:
            return "Green light"
        case 1:
            return "Tread carefully"
        default:
            return "Prefer conservative work"
        }
    }

    var recommendationCopy: String {
        let recommendation = recommendedDecision
        switch recommendation {
        case .deload:
            return "Fatigue markers or flat strength trends suggest a deload. Reduce volume for a week to restore readiness."
        case .nextBlock:
            return "Momentum looks good. Roll into the next block with slightly higher targets."
        }
    }

    private var trendDelta: Double? {
        guard let history = snapshot?.e1RMHistory, history.count >= 2 else { return nil }
        guard let start = history.first?.e1rm, let end = history.last?.e1rm else { return nil }
        return end - start
    }

    private var recommendedDecision: PostBlockDecision {
        if responses.recoveryRiskScore >= 2 { return .deload }
        if let delta = trendDelta, delta < 2 { return .deload }
        return .nextBlock
    }
}
