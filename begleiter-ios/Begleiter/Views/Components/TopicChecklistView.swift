import SwiftUI

/// Scrollable checklist of all topics up to `level`, grouped by CEFR level section.
///
/// - Topics whose prerequisites aren't met (per `profile`) are shown dimmed with a
///   lock icon and cannot be toggled.
/// - Pass `profile: nil` during onboarding — nothing is locked.
/// - Each section header has a "Select all / Deselect all" button covering only
///   the unlocked topics in that section.
struct TopicChecklistView: View {
    let level: CefrLevel
    @Binding var selected: Set<String>
    var profile: StudentProfile?

    // MARK: - Taxonomy

    private var taxonomy: TaxonomyService { .shared }

    private var groupedTopics: [(CefrLevel, [TaxonomyTopic])] {
        taxonomy.groupedByLevel(taxonomy.topicsUpTo(level: level))
    }

    // MARK: - Lock logic

    private func isLocked(_ topic: TaxonomyTopic) -> Bool {
        guard let profile else { return false }
        return !taxonomy.prerequisitesMet(for: topic, in: profile)
    }

    // MARK: - Select-all helpers

    private func selectableIDs(in topics: [TaxonomyTopic]) -> [String] {
        topics.filter { !isLocked($0) }.map(\.id)
    }

    private func allSelected(in topics: [TaxonomyTopic]) -> Bool {
        let ids = selectableIDs(in: topics)
        return !ids.isEmpty && ids.allSatisfy { selected.contains($0) }
    }

    private func toggleAll(in topics: [TaxonomyTopic]) {
        HapticsService.shared.selection()
        let ids = selectableIDs(in: topics)
        if allSelected(in: topics) {
            ids.forEach { selected.remove($0) }
        } else {
            ids.forEach { selected.insert($0) }
        }
    }

    // MARK: - Body

    var body: some View {
        List {
            ForEach(groupedTopics, id: \.0) { cefrLevel, topics in
                Section {
                    ForEach(topics) { topic in
                        topicRow(topic)
                    }
                } header: {
                    sectionHeader(cefrLevel: cefrLevel, topics: topics)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func topicRow(_ topic: TaxonomyTopic) -> some View {
        let locked = isLocked(topic)
        let isOn   = selected.contains(topic.id)

        Button {
            guard !locked else { return }
            HapticsService.shared.selection()
            if isOn {
                selected.remove(topic.id)
            } else {
                selected.insert(topic.id)
            }
        } label: {
            HStack(spacing: 12) {
                // Checkmark / lock icon
                Image(systemName: locked
                      ? "lock.fill"
                      : (isOn ? "checkmark.circle.fill" : "circle"))
                    .font(.title3)
                    .foregroundStyle(
                        locked
                            ? Color(.systemGray3)
                            : (isOn ? Color("BrandGreen") : Color(.systemGray3))
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isOn)

                // Display name
                Text(topic.displayName)
                    .font(.subheadline)
                    .foregroundStyle(locked ? .secondary : .primary)

                Spacer()

                if locked {
                    Text("Prerequisites needed")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(locked)
        .opacity(locked ? 0.55 : 1.0)
    }

    @ViewBuilder
    private func sectionHeader(cefrLevel: CefrLevel, topics: [TaxonomyTopic]) -> some View {
        let selectable = selectableIDs(in: topics)
        HStack {
            Text(cefrLevel.rawValue)
                .font(.footnote.weight(.semibold))
                .textCase(nil)

            Spacer()

            if !selectable.isEmpty {
                Button(allSelected(in: topics) ? "Deselect all" : "Select all") {
                    toggleAll(in: topics)
                }
                .font(.caption)
                .foregroundStyle(Color("BrandGreen"))
            }
        }
    }
}

// MARK: - Preview

#Preview("Onboarding — no profile (nothing locked)") {
    @Previewable @State var selected: Set<String> = []

    TopicChecklistView(
        level: .a2,
        selected: $selected,
        profile: nil
    )
}

#Preview("With profile — some locked") {
    @Previewable @State var selected: Set<String> = ["a1_greetings"]

    var profile = StudentProfile(level: .a2, studyContext: .selfStudy)
    profile.topics["a1_greetings"] = TopicState(status: .mastered)

    return TopicChecklistView(
        level: .a2,
        selected: $selected,
        profile: profile
    )
}
