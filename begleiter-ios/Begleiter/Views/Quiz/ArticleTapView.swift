import SwiftUI

// MARK: - ArticleTapView

/// Game-style exercise: tap the correct German article (der/die/das) for a noun.
/// Shows a brief colour flash before handing off to the FeedbackBanner.
struct ArticleTapView: View {
    let exercise: ArticleTapExercise
    let onAnswer: (String, Bool) -> Void

    @State private var selected: String? = nil
    @State private var wrongTap: String? = nil

    private let articles = ["der", "die", "das"]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Text("Which article is correct?")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                // Noun display card
                VStack(spacing: 8) {
                    if let context = exercise.context {
                        Text(context)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Text(exercise.noun)
                        .font(.system(size: 52, weight: .bold, design: .serif))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
            }
            .padding(.top, 8)
            .padding(.bottom, 36)

            // Article buttons
            HStack(spacing: 14) {
                ForEach(articles, id: \.self) { article in
                    ArticleButton(
                        article: article,
                        state: buttonState(for: article)
                    ) {
                        tap(article)
                    }
                }
            }

            if let hint = exercise.hint {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)
            }

            Spacer()
        }
    }

    // MARK: - State

    private func buttonState(for article: String) -> ArticleButtonState {
        if let sel = selected, sel == article { return .correct }
        if let bad = wrongTap, bad == article { return .wrong }
        if selected != nil || wrongTap != nil { return .disabled }
        return .idle
    }

    private func tap(_ article: String) {
        guard selected == nil && wrongTap == nil else { return }
        HapticsService.shared.tap()
        let isCorrect = article == exercise.correct

        if isCorrect {
            selected = article
            HapticsService.shared.correctAnswer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onAnswer(article, true)
            }
        } else {
            wrongTap = article
            HapticsService.shared.wrongAnswer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                onAnswer(article, false)
            }
        }
    }
}

// MARK: - Article button state

private enum ArticleButtonState: Equatable {
    case idle, correct, wrong, disabled
}

// MARK: - ArticleButton

private struct ArticleButton: View {
    let article: String
    let state: ArticleButtonState
    let action: () -> Void

    @State private var shaking = false

    private var background: Color {
        switch state {
        case .idle:     return Color(.secondarySystemGroupedBackground)
        case .correct:  return Color("BrandGreen")
        case .wrong:    return Color(.systemRed)
        case .disabled: return Color(.systemGray5)
        }
    }

    private var foreground: Color {
        switch state {
        case .correct, .wrong: return .white
        default:               return .primary
        }
    }

    private var scale: CGFloat {
        state == .correct ? 1.06 : 1.0
    }

    var body: some View {
        Button {
            if state == .wrong {
                triggerShake()
            }
            action()
        } label: {
            Text(article)
                .font(.title.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .foregroundStyle(foreground)
                .scaleEffect(scale)
        }
        .buttonStyle(.plain)
        .disabled(state != .idle)
        .offset(x: shaking ? -5 : 0)
        .animation(.easeInOut(duration: 0.06).repeatCount(4, autoreverses: true), value: shaking)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: state)
    }

    private func triggerShake() {
        shaking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { shaking = false }
    }
}

// MARK: - Preview

#Preview("Article Tap — noun") {
    ScrollView {
        ArticleTapView(
            exercise: ArticleTapExercise(
                id: "at-1",
                topic: "a1_nouns",
                noun: "Tisch",
                context: "Ich kaufe ___ Tisch.",
                correct: "der",
                hint: "Masculine nouns use \"der\"",
                explanation: "\"Tisch\" (table) is masculine — der Tisch."
            ),
            onAnswer: { answer, correct in print("Answer: \(answer), correct: \(correct)") }
        )
        .padding(20)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Article Tap — no context") {
    ScrollView {
        ArticleTapView(
            exercise: ArticleTapExercise(
                id: "at-2",
                topic: "a1_nouns",
                noun: "Sonne",
                context: nil,
                correct: "die",
                hint: nil,
                explanation: "\"Sonne\" (sun) is feminine — die Sonne."
            ),
            onAnswer: { _, _ in }
        )
        .padding(20)
    }
    .background(Color(.systemGroupedBackground))
}
