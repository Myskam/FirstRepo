import SwiftUI

// MARK: - CoverageStepView

/// Onboarding step 3 of 4.
/// The user marks which topics they've already studied.
/// Uses `TopicChecklistView` (the existing shared component) and adds a
/// step-level header + always-enabled Continue button.
struct CoverageStepView: View {
    let level: CefrLevel
    @Binding var covered: Set<String>
    let onNext: () -> Void

    // MARK: - Derived

    private var allTopics: [TaxonomyTopic] {
        TaxonomyService.shared.topicsUpTo(level: level)
    }

    private var selectableTopicIDs: [String] {
        allTopics.map(\.id)
    }

    private var allSelected: Bool {
        !selectableTopicIDs.isEmpty && selectableTopicIDs.allSatisfy { covered.contains($0) }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("What have you already studied?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Tick everything you've covered — we'll skip what you know.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 16)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)

            // Topic checklist — pass profile: nil so nothing is locked during onboarding
            TopicChecklistView(
                level: level,
                selected: $covered,
                profile: nil
            )

            // Continue button (always enabled — user can skip by not checking anything)
            Button(action: {
                HapticsService.shared.tap()
                onNext()
            }) {
                Text("Continue")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("BrandGreen"), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .padding(.top, 8)
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Preview

#Preview("Coverage Step — A2 level, nothing selected") {
    @Previewable @State var covered: Set<String> = []
    CoverageStepView(level: .a2, covered: $covered, onNext: {})
}

#Preview("Coverage Step — B1 level, some selected") {
    @Previewable @State var covered: Set<String> = ["a1_greetings", "a1_sein", "a1_nominativ"]
    CoverageStepView(level: .b1, covered: $covered, onNext: {})
}
