import SwiftUI

// MARK: - ActiveSessionView

/// The main exercise loop. Drives the user through each exercise in the
/// session, showing feedback after each answer and navigating to the
/// summary when finished.
struct ActiveSessionView: View {
    @Bindable var sessionVM: SessionViewModel
    @Environment(ProfileViewModel.self) var profileVM
    @State private var showSummary = false

    // MARK: - Derived helpers

    private var currentCorrectAnswer: String {
        guard let ex = sessionVM.currentExercise else { return "" }
        switch ex {
        case .multipleChoice(let e): return e.correct
        case .fillBlank(let e):      return e.blank
        case .matchPairs:            return ""
        case .reorderWords(let e):   return e.correct
        }
    }

    private var currentExplanation: String {
        sessionVM.currentExercise?.explanation ?? ""
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            phaseContent
        }
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isSessionActive)
        .task { await sessionVM.loadSession() }
        .onChange(of: sessionVM.phase) { _, newPhase in
            if case .summary = newPhase { showSummary = true }
        }
        .navigationDestination(isPresented: $showSummary) {
            if let summary = sessionVM.summary,
               let profile = profileVM.profile {
                SessionSummaryView(
                    summary: summary,
                    answers: sessionVM.answers,
                    profile: profile
                )
            }
        }
        .onDisappear {
            if case .summary = sessionVM.phase { sessionVM.reset() }
        }
    }

    // MARK: - Phase content

    @ViewBuilder
    private var phaseContent: some View {
        switch sessionVM.phase {
        case .loading:
            LoadingView(message: "Generating your exercises…")

        case .active:
            activeContent

        case .feedback(let isCorrect):
            ZStack(alignment: .bottom) {
                activeContent
                    .allowsHitTesting(false)

                FeedbackBanner(
                    isCorrect: isCorrect,
                    correctAnswer: currentCorrectAnswer,
                    explanation: currentExplanation,
                    onContinue: {
                        Task { await sessionVM.next() }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .ignoresSafeArea(edges: .bottom)
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.78), value: isCorrect)

        case .summary:
            // .navigationDestination above handles the push.
            // Render a brief placeholder while SwiftUI processes the transition.
            LoadingView(message: "Calculating results…")

        case .error(let error):
            ErrorView(error: error, retry: {
                Task { await sessionVM.loadSession() }
            })
        }
    }

    // MARK: - Active exercise content

    @ViewBuilder
    private var activeContent: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressBarView(
                current: sessionVM.currentIndex + 1,
                total: max(sessionVM.exercises.count, 1)
            )
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)

            // Exercise view
            ScrollView {
                if let exercise = sessionVM.currentExercise {
                    exerciseView(for: exercise)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                        // Force a full re-render when the exercise changes so
                        // each quiz view starts fresh.
                        .id(exercise.id)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: sessionVM.currentIndex)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Exercise type routing

    @ViewBuilder
    private func exerciseView(for exercise: Exercise) -> some View {
        switch exercise {
        case .multipleChoice(let e):
            MultipleChoiceView(exercise: e) { answer, correct in
                Task { await sessionVM.recordAnswer(userAnswer: answer, isCorrect: correct) }
            }

        case .fillBlank(let e):
            FillBlankView(exercise: e) { answer, correct in
                Task { await sessionVM.recordAnswer(userAnswer: answer, isCorrect: correct) }
            }

        case .matchPairs(let e):
            MatchPairsView(exercise: e) { answer, correct in
                Task { await sessionVM.recordAnswer(userAnswer: answer, isCorrect: correct) }
            }

        case .reorderWords(let e):
            ReorderWordsView(exercise: e) { answer, correct in
                Task { await sessionVM.recordAnswer(userAnswer: answer, isCorrect: correct) }
            }
        }
    }

    // MARK: - Helpers

    /// Suppresses the system back button while a session is in flight so the
    /// user can't accidentally abandon exercises mid-stream.
    private var isSessionActive: Bool {
        switch sessionVM.phase {
        case .loading, .active, .feedback: return true
        case .summary, .error:             return false
        }
    }
}

// MARK: - Preview

#Preview("Active Session — loading") {
    let profileVM = ProfileViewModel.preview
    NavigationStack {
        ActiveSessionView(sessionVM: SessionViewModel(profileVM: profileVM))
            .environment(profileVM)
    }
}

#Preview("Active Session — multiple choice exercise") {
    let profileVM = ProfileViewModel.preview
    let sessionVM = SessionViewModel(profileVM: profileVM)
    sessionVM.exercises = [
        .multipleChoice(MultipleChoiceExercise(
            id: "preview-mc-1",
            topic: "a1_sein",
            question: "Which form of \"sein\" goes with \"wir\"?",
            options: ["bin", "bist", "sind", "ist"],
            correct: "sind",
            hint: nil,
            explanation: "\"Wir sind\" — first-person plural present tense of sein."
        )),
        .fillBlank(FillBlankExercise(
            id: "preview-fb-1",
            topic: "a1_greetings",
            sentence: "Guten ___, wie geht es Ihnen?",
            blank: "Tag",
            hint: nil,
            explanation: "\"Guten Tag\" is the standard formal greeting used during the day."
        ))
    ]
    sessionVM.phase = .active
    return NavigationStack {
        ActiveSessionView(sessionVM: sessionVM)
            .environment(profileVM)
    }
}

#Preview("Active Session — feedback (correct)") {
    let profileVM = ProfileViewModel.preview
    let sessionVM = SessionViewModel(profileVM: profileVM)
    sessionVM.exercises = [
        .multipleChoice(MultipleChoiceExercise(
            id: "preview-mc-2",
            topic: "a1_sein",
            question: "\"___ du müde?\"",
            options: ["Bin", "Bist", "Ist", "Sind"],
            correct: "Bist",
            hint: nil,
            explanation: "\"Bist du\" — second-person singular of sein."
        ))
    ]
    sessionVM.phase = .feedback(isCorrect: true)
    return NavigationStack {
        ActiveSessionView(sessionVM: sessionVM)
            .environment(profileVM)
    }
}
