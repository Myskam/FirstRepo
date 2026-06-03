import SwiftUI

// MARK: - SessionStartView

struct SessionStartView: View {
    @Environment(ProfileViewModel.self) var profileVM
    var sessionVM: SessionViewModel

    // MARK: - State

    @State private var practiceTopics: [(String, TopicState)] = []
    @State private var isLoadingTopics: Bool = true
    @State private var navigateToSession: Bool = false

    // MARK: - Constants

    private let exerciseCount = 12

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if isLoadingTopics {
                LoadingView(message: "Loading topics…")
            } else {
                topicList
                bottomBar
            }
        }
        .navigationTitle("Practice Session")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .task {
            await loadTopics()
        }
        .navigationDestination(isPresented: $navigateToSession) {
            ActiveSessionView(sessionVM: sessionVM)
        }
    }

    // MARK: - Topic list

    private var topicList: some View {
        List {
            Section {
                if practiceTopics.isEmpty {
                    ContentUnavailableView(
                        "No Topics Ready",
                        systemImage: "tray",
                        description: Text("Complete more onboarding steps to unlock practice topics.")
                    )
                } else {
                    ForEach(practiceTopics, id: \.0) { topicId, state in
                        TopicRow(topicId: topicId, state: state)
                    }
                }
            } header: {
                Text("Topics in this session")
                    .font(.footnote.weight(.semibold))
                    .textCase(nil)
            } footer: {
                if !practiceTopics.isEmpty {
                    Text("Struggling topics are prioritised. Up to 5 topics per session.")
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()

            Button {
                HapticsService.shared.tap()
                navigateToSession = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.body.weight(.semibold))
                    Text("Generate \(exerciseCount) Exercises")
                        .font(.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    practiceTopics.isEmpty ? Color(.systemGray4) : Color("BrandGreen"),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .foregroundStyle(practiceTopics.isEmpty ? Color(.systemGray) : .white)
            }
            .buttonStyle(.plain)
            .disabled(practiceTopics.isEmpty)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
        }
    }

    // MARK: - Data loading

    private func loadTopics() async {
        isLoadingTopics = true
        practiceTopics = await profileVM.activePracticeTopics()
        isLoadingTopics = false
    }
}

// MARK: - TopicRow

private struct TopicRow: View {
    let topicId: String
    let state: TopicState

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(TaxonomyService.shared.displayName(for: topicId))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                if let lastPracticed = state.lastPracticed,
                   let date = ISO8601DateFormatter().date(from: lastPracticed) {
                    Text("Last practiced \(date.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            BadgeView(status: state.status)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview("Session Start — with topics") {
    let profileVM = ProfileViewModel.preview
    NavigationStack {
        SessionStartView(sessionVM: SessionViewModel(profileVM: profileVM))
            .environment(profileVM)
    }
}

#Preview("Session Start — no topics") {
    let profileVM = ProfileViewModel()
    NavigationStack {
        SessionStartView(sessionVM: SessionViewModel(profileVM: profileVM))
            .environment(profileVM)
    }
}
