import SwiftUI

struct MultipleChoiceView: View {
    let exercise: MultipleChoiceExercise
    let onAnswer: (String, Bool) -> Void

    @State private var selectedOption: String? = nil

    // MARK: - Derived state

    private var isAnswered: Bool { selectedOption != nil }

    private func optionState(for option: String) -> OptionState {
        guard let selected = selectedOption else { return .idle }
        if option == exercise.correct { return .correct }
        if option == selected { return .wrong }
        return .dimmed
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 1. Question
            Text(exercise.question)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)

            // 2. Hint
            if let hint = exercise.hint {
                Text(hint)
                    .font(.footnote.italic())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // 3. Options
            VStack(spacing: 12) {
                ForEach(exercise.options, id: \.self) { option in
                    OptionButton(
                        text: option,
                        state: optionState(for: option),
                        isAnswered: isAnswered
                    ) {
                        guard !isAnswered else { return }
                        HapticsService.shared.tap()
                        submit(option)
                    }
                }
            }

            // 4. TTS button — appears after answering
            if isAnswered {
                HStack {
                    Spacer()
                    Button {
                        HapticsService.shared.tap()
                        TTSService.shared.speak(exercise.correct)
                    } label: {
                        Label("Speak answer", systemImage: "speaker.wave.2.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedOption)
    }

    // MARK: - Actions

    private func submit(_ option: String) {
        selectedOption = option
        let correct = option == exercise.correct
        if correct {
            HapticsService.shared.correctAnswer()
        } else {
            HapticsService.shared.wrongAnswer()
        }
        onAnswer(option, correct)
    }
}

// MARK: - Option state

private enum OptionState {
    case idle, correct, wrong, dimmed
}

// MARK: - Option button

private struct OptionButton: View {
    let text: String
    let state: OptionState
    let isAnswered: Bool
    let action: () -> Void

    private var backgroundColor: Color {
        switch state {
        case .idle:    return Color(.secondarySystemGroupedBackground)
        case .correct: return Color(hex: "#34D399")
        case .wrong:   return Color(hex: "#F87171")
        case .dimmed:  return Color(.secondarySystemGroupedBackground)
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .correct, .wrong: return .white
        default: return .primary
        }
    }

    private var opacity: Double {
        state == .dimmed ? 0.5 : 1.0
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.body.weight(.medium))
                    .foregroundStyle(foregroundColor)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                if state == .correct {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(foregroundColor)
                } else if state == .wrong {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(foregroundColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(state == .idle ? Color(.separator) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isAnswered)
        .opacity(opacity)
        .animation(.easeInOut(duration: 0.15), value: state)
    }
}

// MARK: - Hex color helper

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = (int >> 16) & 0xFF
        let g = (int >> 8) & 0xFF
        let b = int & 0xFF
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

// MARK: - Preview

#Preview("Multiple Choice") {
    ScrollView {
        MultipleChoiceView(
            exercise: MultipleChoiceExercise(
                id: "mc-1",
                topic: "Prepositions",
                question: "Which preposition completes the sentence: \"Ich gehe ___ Hause.\"",
                options: ["zu", "nach", "von", "bei"],
                correct: "nach",
                hint: "Think about the fixed expression for going home.",
                explanation: "\"nach Hause\" is the correct idiomatic expression for going home in German."
            ),
            onAnswer: { answer, correct in
                print("Answer: \(answer), Correct: \(correct)")
            }
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
