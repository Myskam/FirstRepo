import SwiftUI

// MARK: - SessionSummaryView

/// Results screen shown after a session finishes.
/// Displays the score, strong/weak topic lists, an AI recommendation,
/// the updated streak, and a "Done" button that pops back to the dashboard.
struct SessionSummaryView: View {
    let summary: SessionSummary
    let answers: [Answer]
    let profile: StudentProfile

    @Environment(\.dismiss) var dismiss

    // MARK: - Derived

    private var correctCount: Int { answers.filter(\.isCorrect).count }
    private var totalCount: Int   { answers.count }

    private var scoreColor: Color {
        guard totalCount > 0 else { return .secondary }
        let ratio = Double(correctCount) / Double(totalCount)
        if ratio >= 0.8 { return Color("BrandGreen") }
        if ratio >= 0.5 { return Color(.systemOrange) }
        return Color(.systemRed)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                scoreSection
                topicsSection
                recommendationCard
                streakSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Session Complete 🎉")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                doneButton
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomDoneBar
        }
    }

    // MARK: - Score section

    private var scoreSection: some View {
        VStack(spacing: 8) {
            Text("\(correctCount) / \(totalCount)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(scoreColor)
                .monospacedDigit()
                .contentTransition(.numericText())

            Text("correct")
                .font(.title3)
                .foregroundStyle(.secondary)

            // Compact accuracy bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 10)

                    Capsule()
                        .fill(scoreColor)
                        .frame(
                            width: totalCount > 0
                                ? geo.size.width * CGFloat(correctCount) / CGFloat(totalCount)
                                : 0,
                            height: 10
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.72), value: correctCount)
                }
            }
            .frame(height: 10)
            .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Topics section

    @ViewBuilder
    private var topicsSection: some View {
        if !summary.strongTopics.isEmpty || !summary.weakTopics.isEmpty {
            VStack(spacing: 12) {
                if !summary.strongTopics.isEmpty {
                    topicGroup(
                        title: "Strong",
                        topics: summary.strongTopics,
                        icon: "checkmark.circle.fill",
                        color: Color("BrandGreen")
                    )
                }

                if !summary.weakTopics.isEmpty {
                    topicGroup(
                        title: "Needs work",
                        topics: summary.weakTopics,
                        icon: "xmark.circle.fill",
                        color: Color(.systemRed)
                    )
                }
            }
        }
    }

    private func topicGroup(
        title: String,
        topics: [String],
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                ForEach(Array(topics.enumerated()), id: \.offset) { index, topicId in
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(color)
                            .frame(width: 22)

                        Text(TaxonomyService.shared.displayName(for: topicId))
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)

                    if index < topics.count - 1 {
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Recommendation card

    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("BrandGreen"))

                Text("Recommendation")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            Text(summary.recommendation)
                .font(.subheadline.italic())
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color("BrandGreen").opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Streak section

    private var streakSection: some View {
        HStack(spacing: 12) {
            StreakBadgeView(streak: profile.currentStreak)

            if profile.currentStreak > 0 {
                Text("🔥 Keep it up!")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            } else {
                Text("Complete a session daily to build your streak!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Done button (toolbar)

    private var doneButton: some View {
        Button {
            HapticsService.shared.tap()
            // Pop all the way back to the root (dashboard) by dismissing the
            // NavigationStack destination chain.
            dismiss()
        } label: {
            Text("Done")
                .fontWeight(.semibold)
                .foregroundStyle(Color("BrandGreen"))
        }
    }

    // MARK: - Bottom bar "Done" button

    private var bottomDoneBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                HapticsService.shared.tap()
                dismiss()
            } label: {
                Text("Done")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("BrandGreen"),
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Preview

#Preview("Session Summary — strong result") {
    let summary = SessionSummary(
        strongTopics: ["a1_greetings", "a1_sein"],
        weakTopics: ["a1_nominativ"],
        recommendation: "Great work on greetings and sein! Spend a bit more time on Nominativ case — try some noun phrase exercises next session."
    )
    let answers: [Answer] = [
        Answer(exerciseId: "1", topic: "a1_greetings",  isCorrect: true,  userAnswer: "Guten Tag",    correctAnswer: "Guten Tag",    timeSeconds: 3.2),
        Answer(exerciseId: "2", topic: "a1_sein",       isCorrect: true,  userAnswer: "bin",           correctAnswer: "bin",           timeSeconds: 2.8),
        Answer(exerciseId: "3", topic: "a1_sein",       isCorrect: true,  userAnswer: "bist",          correctAnswer: "bist",          timeSeconds: 4.1),
        Answer(exerciseId: "4", topic: "a1_nominativ",  isCorrect: false, userAnswer: "den Tisch",     correctAnswer: "der Tisch",     timeSeconds: 6.0),
        Answer(exerciseId: "5", topic: "a1_greetings",  isCorrect: true,  userAnswer: "Auf Wiedersehen",correctAnswer: "Auf Wiedersehen",timeSeconds: 2.5)
    ]
    var profile = StudentProfile(level: .a1, studyContext: .selfStudy)
    profile.currentStreak = 5

    return NavigationStack {
        SessionSummaryView(summary: summary, answers: answers, profile: profile)
    }
}

#Preview("Session Summary — weak result") {
    let summary = SessionSummary(
        strongTopics: [],
        weakTopics: ["a1_sein", "a1_nominativ", "a1_greetings"],
        recommendation: "Don't be discouraged! Review the basics of sein conjugation and Nominativ case — these are the foundation of German grammar."
    )
    let answers: [Answer] = [
        Answer(exerciseId: "1", topic: "a1_sein",      isCorrect: false, userAnswer: "ist",  correctAnswer: "bin",  timeSeconds: 5.0),
        Answer(exerciseId: "2", topic: "a1_nominativ", isCorrect: false, userAnswer: "den",  correctAnswer: "der",  timeSeconds: 7.2),
        Answer(exerciseId: "3", topic: "a1_greetings", isCorrect: true,  userAnswer: "Hallo",correctAnswer: "Hallo",timeSeconds: 1.8)
    ]
    var profile = StudentProfile(level: .a1, studyContext: .appOnly)
    profile.currentStreak = 0

    return NavigationStack {
        SessionSummaryView(summary: summary, answers: answers, profile: profile)
    }
}
