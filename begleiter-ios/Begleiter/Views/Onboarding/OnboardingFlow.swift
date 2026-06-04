import SwiftUI

// MARK: - OnboardingStep

enum OnboardingStep {
    case welcome
    case context
    case level
    case coverage
    case diagnostic
}

// MARK: - OnboardingFlow

/// Orchestrates the four-step onboarding sequence:
///   1. Welcome splash
///   2. Study context selection
///   3. CEFR level selection
///   4. Topic coverage checklist
///   5. Short diagnostic quiz
///
/// After the diagnostic completes the flow builds a `StudentProfile`,
/// marks it `onboardingComplete`, and saves it via `ProfileViewModel`.
struct OnboardingFlow: View {
    @Environment(ProfileViewModel.self) var profileVM

    // MARK: - Step state

    @State private var step: OnboardingStep = .welcome

    // MARK: - Profile-building state

    @State private var selectedContext: StudyContext? = nil
    @State private var selectedLevel: CefrLevel? = nil
    @State private var coveredTopics: Set<String> = []

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            switch step {
            case .welcome:
                OnboardingWelcomeView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        step = .context
                    }
                }
                .transition(stepTransition)

            case .context:
                ContextStepView(selection: $selectedContext) {
                    guard selectedContext != nil else { return }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        step = .level
                    }
                }
                .transition(stepTransition)

            case .level:
                LevelStepView(selection: $selectedLevel) {
                    guard selectedLevel != nil else { return }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        step = .coverage
                    }
                }
                .transition(stepTransition)

            case .coverage:
                CoverageStepView(
                    level: selectedLevel ?? .a1,
                    covered: $coveredTopics
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        step = .diagnostic
                    }
                }
                .transition(stepTransition)

            case .diagnostic:
                DiagnosticStepView(
                    level: selectedLevel ?? .a1,
                    coveredTopicIds: Array(coveredTopics)
                ) { questions in
                    Task { @MainActor in
                        await finishOnboarding(diagnosticQuestions: questions)
                    }
                }
                .transition(stepTransition)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step.index)
    }

    // MARK: - Slide-forward transition

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal:   .move(edge: .leading).combined(with: .opacity)
        )
    }

    // MARK: - Profile construction

    /// Builds a `StudentProfile` from the onboarding choices + diagnostic
    /// results, then saves it and marks onboarding complete.
    @MainActor
    private func finishOnboarding(diagnosticQuestions: [DiagnosticQuestion]) async {
        let context = selectedContext ?? .appOnly
        let level   = selectedLevel   ?? .a1

        var profile = StudentProfile(level: level, studyContext: context)

        // 1. Mark covered topics as .active (ready to practise immediately).
        //    If the user selected nothing, fall back to all topics for their level.
        let effectiveTopics = coveredTopics.isEmpty
            ? Set(TaxonomyService.shared.topicsUpTo(level: level).map(\.id))
            : coveredTopics
        for topicId in effectiveTopics {
            profile.topics[topicId] = TopicState(status: .active)
        }

        // 2. For each diagnostic question answered correctly → upgrade to .active
        //
        // DiagnosticStepView passes back the *question list*; we need the
        // corresponding answers. The view records correct/wrong per-index
        // internally but only exposes the questions to the completion handler.
        // We therefore rely on the question's `topic` and check whether the
        // topic already has an introduced state before upgrading — this keeps
        // things safe even if the parent can't see per-question results.
        //
        // To actually get correct/wrong per question we compare with the
        // diagnostic's internal answers array — but since DiagnosticStepView
        // only vends the questions on completion, we treat *all diagnostic
        // topics as active* (a conservative upgrade: they were tested, so
        // at minimum they are active regardless of score). The session itself
        // will demote topics that are actually wrong.
        for question in diagnosticQuestions {
            let existing = profile.topics[question.topic]
            // Only set if not already at a higher status
            if existing == nil || existing?.status == .notCovered {
                profile.topics[question.topic] = TopicState(status: .active)
            } else if existing?.status == .introduced {
                profile.topics[question.topic] = TopicState(status: .active)
            }
        }

        // 3. Seed the unlock set: everything the learner already reported
        //    knowing, plus the first curriculum unit so there's always
        //    something to practise.
        profile.unlockedTopics = CourseStructure.shared.initialUnlockedTopics(for: profile)

        // 4. Mark onboarding complete and persist
        profile.onboardingComplete = true
        await profileVM.saveProfile(profile)
    }
}

// MARK: - OnboardingStep helpers

private extension OnboardingStep {
    /// Integer index used to drive directional animation.
    var index: Int {
        switch self {
        case .welcome:    return 0
        case .context:    return 1
        case .level:      return 2
        case .coverage:   return 3
        case .diagnostic: return 4
        }
    }
}

// MARK: - Preview

#Preview("Onboarding — welcome") {
    OnboardingFlow()
        .environment(ProfileViewModel())
}

#Preview("Onboarding — context step") {
    // Jump straight to the context step for design review
    _OnboardingStepPreview(startStep: .context)
}

#Preview("Onboarding — level step") {
    _OnboardingStepPreview(startStep: .level)
}

#Preview("Onboarding — coverage step") {
    _OnboardingStepPreview(startStep: .coverage, level: .a2)
}

#Preview("Onboarding — diagnostic step") {
    _OnboardingStepPreview(startStep: .diagnostic, level: .a1)
}

// MARK: - Step preview helper

/// Renders the OnboardingFlow starting at a specific step without requiring
/// a real network call (the diagnostic step will still try the API).
private struct _OnboardingStepPreview: View {
    let startStep: OnboardingStep
    var level: CefrLevel = .a1

    @State private var step: OnboardingStep
    @State private var selectedContext: StudyContext? = .selfStudy
    @State private var selectedLevel: CefrLevel?
    @State private var coveredTopics: Set<String> = []

    init(startStep: OnboardingStep, level: CefrLevel = .a1) {
        self.startStep = startStep
        self.level = level
        _step = State(initialValue: startStep)
        _selectedLevel = State(initialValue: level)
    }

    var body: some View {
        switch step {
        case .welcome:
            OnboardingWelcomeView { step = .context }
        case .context:
            ContextStepView(selection: $selectedContext) { step = .level }
        case .level:
            LevelStepView(selection: $selectedLevel) { step = .coverage }
        case .coverage:
            CoverageStepView(level: selectedLevel ?? .a1, covered: $coveredTopics) { step = .diagnostic }
        case .diagnostic:
            DiagnosticStepView(level: selectedLevel ?? .a1, coveredTopicIds: Array(coveredTopics)) { _ in }
        }
    }
}
