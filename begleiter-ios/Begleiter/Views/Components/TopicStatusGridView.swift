import SwiftUI

/// Displays all topics in a `StudentProfile` grouped by their current `TopicStatus`.
///
/// Sections are ordered from most-actionable (Struggling) to least (Not started)
/// so teachers and students can immediately see what needs attention.
/// Each row shows the topic's display name on the left and a `BadgeView` on the right.
struct TopicStatusGridView: View {
    let profile: StudentProfile
    var taxonomy: TaxonomyService = .shared

    // MARK: - Section ordering

    /// Most-actionable statuses appear first.
    private let statusOrder: [TopicStatus] = [
        .struggling, .active, .introduced, .mastered, .notCovered
    ]

    // MARK: - Section model

    private struct StatusSection: Identifiable {
        let status: TopicStatus
        let topics: [TaxonomyTopic]
        var id: String { status.rawValue }
    }

    private var sections: [StatusSection] {
        let all = taxonomy.allTopics()
        return statusOrder.compactMap { status in
            let matching = all.filter { profile.topics[$0.id]?.status == status }
            guard !matching.isEmpty else { return nil }
            return StatusSection(status: status, topics: matching)
        }
    }

    // MARK: - Helpers

    private func sectionTitle(_ status: TopicStatus, count: Int) -> String {
        let label: String
        switch status {
        case .notCovered: label = "Not started"
        case .introduced: label = "Introduced"
        case .active:     label = "Practicing"
        case .struggling: label = "Struggling"
        case .mastered:   label = "Mastered"
        }
        return "\(label) (\(count))"
    }

    // MARK: - Body

    var body: some View {
        List {
            ForEach(sections) { section in
                Section {
                    ForEach(section.topics) { topic in
                        HStack {
                            Text(taxonomy.displayName(for: topic.id))
                                .font(.subheadline)
                            Spacer()
                            BadgeView(status: section.status)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text(sectionTitle(section.status, count: section.topics.count))
                        .font(.footnote.weight(.semibold))
                        .textCase(nil)
                }
            }

            if sections.isEmpty {
                ContentUnavailableView(
                    "No Topics Yet",
                    systemImage: "book.closed",
                    description: Text("Complete the onboarding to start tracking your progress.")
                )
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Preview

#Preview("Topic status grid") {
    var profile = StudentProfile(level: .a2, studyContext: .selfStudy)
    profile.topics["a1_greetings"]     = TopicState(status: .mastered)
    profile.topics["a1_present_tense"] = TopicState(status: .active)
    profile.topics["a1_articles"]      = TopicState(status: .struggling)
    profile.topics["a2_modal_verbs"]   = TopicState(status: .introduced)
    profile.topics["a2_perfect_tense"] = TopicState(status: .notCovered)

    return TopicStatusGridView(profile: profile)
}

#Preview("Empty profile") {
    let profile = StudentProfile(level: .a1, studyContext: .appOnly)
    return TopicStatusGridView(profile: profile)
}
