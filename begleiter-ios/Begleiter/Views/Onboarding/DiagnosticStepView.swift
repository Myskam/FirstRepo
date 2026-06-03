import SwiftUI

// MARK: - File-private helpers

private enum LoadState {
    case loading
    case loaded
    case error(String)
}

private enum OptionState: Equatable {
    case neutral
    case correct
    case wrong
    case dimmed
}

// MARK: - DiagnosticStepView

/// Onboarding step 4 of 4.
///
/// Fetches a short AI-generated diagnostic quiz (5 questions) for the
/// student's self-reported level and covered topics. Questions are
/// shown one at a time:
///
/// - `multiple_choice` — four tappable buttons, auto-submits on tap
/// - `fill_blank`      — text field + "Check" button
///
/// After each answer a brief colour-coded feedback overlay appears
/// (1.5 s) before the next question loads. Once all questions are
/// answered the view shows a short "Analysing results…" beat then
/// calls `onComplete` with the full question list (the parent builds
/// the `StudentProfile` from them and the recorded `answers` array).
///
/// The user can bail out at any point via the "Skip diagnostic" button.
struct DiagnosticStepView: View {

    // MARK: - Parameters

    let level: CefrLevel
    let coveredTopicIds: [String]
    /// Called when the quiz finishes (or is skipped).
    /// Receives all questions so the parent can inspect which topics were hit.
    let onComplete: ([DiagnosticQuestion]) -> Void

    // MARK: - State (as required by spec)

    @State private var questions: [DiagnosticQuestion] = []
    @State private var currentIndex: Int = 0
    @State private var answers: [Bool] = []
    @State private var loadState: LoadState = .loading
    @State private var selectedAnswer: String?
    @State private var showFeedback: Bool = false

    // MARK: - Additional state

    @State private var fillBlankText: String = ""
    @State private var isAnalysing: Bool = false
    @FocusState private var textFieldFocused: Bool

    // MARK: - Body

    var body: some View {
        ZStack {
            switch loadState {
            case .loading:
                loadingBody

            case .error(let message):
                errorBody(message: message)

            case .loaded:
                if isAnalysing {
                    analysingBody
                } else {
                    quizBody
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isAnalysing)
        .task { await fetchQuestions() }
    }

    // MARK: - Loading

    private var loadingBody: some View {
        VStack(spacing: 0) {
            LoadingView(message: "Generating your diagnostic questions…")

            skipButton
                .padding(.bottom, 48)
        }
    }

    // MARK: - Error

    @ViewBuilder
    private func errorBody(message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Couldn't load questions")
                .font(.title3.bold())

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                HapticsService.shared.tap()
                loadState = .loading
                Task { await fetchQuestions() }
            } label: {
                Text("Try again")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("BrandGreen"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)

            Spacer()

            skipButton
                .padding(.bottom, 48)
        }
    }

    // MARK: - Analysing

    private var analysingBody: some View {
        VStack(spacing: 16) {
            Spacer()
            LoadingView(message: "Analysing results…")
            Spacer()
        }
    }

    // MARK: - Quiz

    private var quizBody: some View {
        VStack(spacing: 0) {
            // Progress header
            progressHeader
                .padding(.top, 16)
                .padding(.horizontal, 24)

            Spacer()

            if currentIndex < questions.count {
                let question = questions[currentIndex]

                VStack(spacing: 0) {
                    // Question text
                    Text(question.question)
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        .id("question_\(currentIndex)")
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))

                    // Answer UI
                    if question.type == "fill_blank" {
                        fillBlankAnswerArea(question: question)
                    } else {
                        multipleChoiceAnswerArea(question: question)
                    }

                    // Feedback
                    if showFeedback, let chosen = selectedAnswer {
                        let isCorrect = normalise(chosen) == normalise(question.correct)
                        feedbackView(isCorrect: isCorrect, explanation: question.explanation)
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }

            Spacer()

            skipButton
                .padding(.bottom, 48)
        }
        .animation(.easeInOut(duration: 0.2), value: showFeedback)
    }

    // MARK: - Progress header

    private var progressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Question \(min(currentIndex + 1, questions.count)) of \(questions.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color("BrandGreen"))
                        .frame(
                            width: questions.isEmpty
                                ? 0
                                : proxy.size.width * CGFloat(currentIndex) / CGFloat(questions.count),
                            height: 6
                        )
                        .animation(.easeInOut(duration: 0.3), value: currentIndex)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Multiple choice

    private func multipleChoiceAnswerArea(question: DiagnosticQuestion) -> some View {
        VStack(spacing: 12) {
            ForEach(question.options ?? [], id: \.self) { option in
                MultipleChoiceOptionButton(
                    text: option,
                    state: optionState(option: option, question: question),
                    isDisabled: showFeedback
                ) {
                    submitMultipleChoice(option: option, question: question)
                }
            }
        }
        .padding(.horizontal, 24)
        .id("options_\(currentIndex)")
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    private func optionState(option: String, question: DiagnosticQuestion) -> OptionState {
        guard showFeedback, let chosen = selectedAnswer else { return .neutral }
        if option == question.correct { return .correct }
        if option == chosen { return .wrong }
        return .dimmed
    }

    private func submitMultipleChoice(option: String, question: DiagnosticQuestion) {
        guard !showFeedback else { return }
        HapticsService.shared.tap()
        selectedAnswer = option
        let correct = normalise(option) == normalise(question.correct)
        answers.append(correct)
        if correct {
            HapticsService.shared.correctAnswer()
        } else {
            HapticsService.shared.wrongAnswer()
        }
        revealFeedbackThenAdvance()
    }

    // MARK: - Fill blank

    private func fillBlankAnswerArea(question: DiagnosticQuestion) -> some View {
        VStack(spacing: 16) {
            TextField("Type your answer…", text: $fillBlankText)
                .textFieldStyle(.plain)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color(.separator), lineWidth: 1)
                )
                .focused($textFieldFocused)
                .disabled(showFeedback)
                .padding(.horizontal, 24)
                .onSubmit { submitFillBlank(question: question) }

            let trimmed = fillBlankText.trimmingCharacters(in: .whitespacesAndNewlines)
            let checkDisabled = trimmed.isEmpty || showFeedback

            Button {
                submitFillBlank(question: question)
            } label: {
                Text("Check")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        checkDisabled ? Color(.systemGray4) : Color("BrandGreen"),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .foregroundStyle(checkDisabled ? Color(.systemGray) : .white)
            }
            .buttonStyle(.plain)
            .disabled(checkDisabled)
            .padding(.horizontal, 24)
        }
        .id("fillblank_\(currentIndex)")
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    private func submitFillBlank(question: DiagnosticQuestion) {
        let trimmed = fillBlankText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !showFeedback else { return }
        textFieldFocused = false
        HapticsService.shared.tap()
        selectedAnswer = trimmed
        let correct = normalise(trimmed) == normalise(question.correct)
        answers.append(correct)
        if correct {
            HapticsService.shared.correctAnswer()
        } else {
            HapticsService.shared.wrongAnswer()
        }
        revealFeedbackThenAdvance()
    }

    // MARK: - Feedback banner

    private func feedbackView(isCorrect: Bool, explanation: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isCorrect ? Color.green : Color.red)

                Text(isCorrect ? "Correct!" : "Not quite")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isCorrect ? Color.green : Color.red)
            }

            Text(explanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            (isCorrect ? Color.green : Color.red).opacity(0.08),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    (isCorrect ? Color.green : Color.red).opacity(0.25),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Skip button

    private var skipButton: some View {
        Button {
            HapticsService.shared.tap()
            onComplete(questions)
        } label: {
            Text("Skip diagnostic")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .underline()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Async logic

    private func fetchQuestions() async {
        do {
            let fetched = try await APIService.shared.generateDiagnosticQuestions(
                coveredTopics: coveredTopicIds,
                level: level.rawValue,
                count: 5
            )
            await MainActor.run {
                questions = fetched
                currentIndex = 0
                answers = []
                selectedAnswer = nil
                fillBlankText = ""
                loadState = fetched.isEmpty
                    ? .error("No questions were returned. Please try again.")
                    : .loaded
            }
        } catch {
            await MainActor.run {
                loadState = .error(error.localizedDescription)
            }
        }
    }

    private func revealFeedbackThenAdvance() {
        withAnimation { showFeedback = true }
        Task {
            try? await Task.sleep(for: .milliseconds(1_500))
            await advance()
        }
    }

    @MainActor
    private func advance() {
        withAnimation(.easeInOut(duration: 0.25)) {
            showFeedback = false
            selectedAnswer = nil
            fillBlankText = ""
        }

        let nextIndex = currentIndex + 1

        if nextIndex >= questions.count {
            // All done — show brief "Analysing…" state then call completion
            withAnimation { isAnalysing = true }
            Task {
                try? await Task.sleep(for: .milliseconds(1_200))
                onComplete(questions)
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex = nextIndex
            }
        }
    }

    /// Case-insensitive, whitespace-trimmed comparison helper.
    private func normalise(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

// MARK: - MultipleChoiceOptionButton

private struct MultipleChoiceOptionButton: View {
    let text: String
    let state: OptionState
    let isDisabled: Bool
    let onTap: () -> Void

    private var borderColor: Color {
        switch state {
        case .correct: return .green
        case .wrong:   return .red
        case .neutral, .dimmed: return Color(.separator)
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .correct: return Color.green.opacity(0.10)
        case .wrong:   return Color.red.opacity(0.10)
        case .neutral, .dimmed: return Color(.secondarySystemGroupedBackground)
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .correct: return .green
        case .wrong:   return .red
        case .neutral: return .primary
        case .dimmed:  return Color(.systemGray2)
        }
    }

    private var trailingIcon: String? {
        switch state {
        case .correct: return "checkmark.circle.fill"
        case .wrong:   return "xmark.circle.fill"
        default:       return nil
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(foregroundColor)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                if let icon = trailingIcon {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(state == .correct ? Color.green : Color.red)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: state == .neutral ? 1 : 1.5)
            )
            .opacity(state == .dimmed ? 0.45 : 1.0)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .animation(.easeInOut(duration: 0.18), value: state)
    }
}

// MARK: - Previews

#Preview("Diagnostic Step — loading state") {
    DiagnosticStepView(
        level: .a2,
        coveredTopicIds: ["a1_greetings", "a1_sein"]
    ) { _ in }
}

#Preview("Diagnostic Step — question UI") {
    _DiagnosticQuizPreview()
}

/// Previews the quiz question UI directly without triggering a live API call.
private struct _DiagnosticQuizPreview: View {

    private let stubQuestions: [DiagnosticQuestion] = [
        DiagnosticQuestion(
            id: "p1",
            topic: "a1_sein",
            type: "multiple_choice",
            question: "Which form of \"sein\" goes with \"ich\"?",
            options: ["bin", "bist", "ist", "sind"],
            correct: "bin",
            explanation: "\"Ich bin\" is the first-person singular of \"sein\" (to be)."
        )
    ]

    @State private var selectedOption: String? = nil
    @State private var showFeedback: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Simulated progress header
            VStack(spacing: 10) {
                HStack {
                    Text("Question 1 of 5")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color("BrandGreen"))
                        .frame(width: 0, height: 6)
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 24)

            Spacer()

            Text(stubQuestions[0].question)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

            VStack(spacing: 12) {
                ForEach(stubQuestions[0].options ?? [], id: \.self) { option in
                    let state: OptionState = {
                        guard showFeedback, let chosen = selectedOption else { return .neutral }
                        if option == stubQuestions[0].correct { return .correct }
                        if option == chosen { return .wrong }
                        return .dimmed
                    }()
                    MultipleChoiceOptionButton(
                        text: option,
                        state: state,
                        isDisabled: showFeedback
                    ) {
                        selectedOption = option
                        withAnimation { showFeedback = true }
                    }
                }
            }
            .padding(.horizontal, 24)

            if showFeedback {
                let isCorrect = selectedOption == stubQuestions[0].correct
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(isCorrect ? Color.green : Color.red)
                        Text(isCorrect ? "Correct!" : "Not quite")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(isCorrect ? Color.green : Color.red)
                    }
                    Text(stubQuestions[0].explanation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    (isCorrect ? Color.green : Color.red).opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder((isCorrect ? Color.green : Color.red).opacity(0.25), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer()

            Button {} label: {
                Text("Skip diagnostic")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .underline()
            }
            .buttonStyle(.plain)
            .padding(.bottom, 48)
        }
        .animation(.easeInOut(duration: 0.2), value: showFeedback)
    }
}
