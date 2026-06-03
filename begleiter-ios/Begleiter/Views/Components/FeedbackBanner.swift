import SwiftUI

/// Full-width answer-feedback banner that slides up from the bottom of the screen.
///
/// Usage — wrap in a `ZStack` at the bottom of the exercise view:
/// ```swift
/// if showFeedback {
///     FeedbackBanner(
///         isCorrect: result.isCorrect,
///         correctAnswer: result.correctAnswer,
///         explanation: exercise.explanation,
///         onContinue: { showFeedback = false; advance() }
///     )
///     .transition(.move(edge: .bottom).combined(with: .opacity))
/// }
/// ```
/// Apply `.animation(.spring(response: 0.38, dampingFraction: 0.78), value: showFeedback)`
/// on the parent to get the spring entrance.
struct FeedbackBanner: View {
    let isCorrect: Bool
    let correctAnswer: String
    let explanation: String
    let onContinue: () -> Void

    // MARK: - Appearance

    /// Correct → #34D399 (Tailwind emerald-400), Wrong → #F87171 (Tailwind red-400)
    private var backgroundColor: Color {
        isCorrect ? Color(hex: "#34D399") : Color(hex: "#F87171")
    }

    private let foreground = Color.white

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // ── Top row: result label + optional wrong-answer line + speaker ──
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isCorrect ? "✓ Correct!" : "✗ Incorrect")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(foreground)

                    if !isCorrect {
                        Text("Correct answer: \(correctAnswer)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(foreground.opacity(0.92))
                    }
                }

                Spacer()

                // Speaker button — plays the correct answer in German TTS
                Button {
                    HapticsService.shared.tap()
                    TTSService.shared.speak(correctAnswer)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundStyle(foreground)
                        .padding(8)
                        .background(foreground.opacity(0.20), in: Circle())
                }
                .accessibilityLabel("Speak correct answer")
            }

            // ── Explanation ──
            if !explanation.isEmpty {
                Text(explanation)
                    .font(.subheadline)
                    .foregroundStyle(foreground.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }

            // ── Continue button ──
            Button {
                HapticsService.shared.tap()
                onContinue()
            } label: {
                HStack(spacing: 4) {
                    Text("Continue")
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    foreground.opacity(0.22),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
                .foregroundStyle(foreground)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        // Extend under the home indicator on modern iPhones
        .padding(.bottom, 4)
        .background(backgroundColor)
        .onAppear {
            if isCorrect {
                HapticsService.shared.correctAnswer()
            } else {
                HapticsService.shared.wrongAnswer()
            }
        }
    }
}

// MARK: - Hex colour initialiser (file-private)

private extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&value)
        let r, g, b: UInt64
        switch clean.count {
        case 6:
            (r, g, b) = ((value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255
        )
    }
}

// MARK: - Preview

#Preview("Correct answer") {
    VStack {
        Spacer()
        FeedbackBanner(
            isCorrect: true,
            correctAnswer: "Ich gehe nach Hause.",
            explanation: "Great work! \"nach\" is used with cities and home (Hause).",
            onContinue: {}
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    .ignoresSafeArea(edges: .bottom)
}

#Preview("Wrong answer") {
    VStack {
        Spacer()
        FeedbackBanner(
            isCorrect: false,
            correctAnswer: "Ich gehe nach Hause.",
            explanation: "Use \"nach\" not \"zu\" when going home — \"nach Hause\" is an idiomatic fixed expression.",
            onContinue: {}
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    .ignoresSafeArea(edges: .bottom)
}
