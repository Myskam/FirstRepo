import SwiftUI

// MARK: - FillBlankView

/// Wheel-picker fill-in-the-blank exercise.
///
/// The sentence is shown at the top with the blank replaced by the currently
/// selected wheel option — it updates live as the user spins the drum.
/// No typing required: ADHD/visual-learner friendly.
struct FillBlankView: View {
    let exercise: FillBlankExercise
    let onAnswer: (String, Bool) -> Void

    @State private var selectedIndex: Int = 0
    @State private var submitted = false

    // MARK: - Derived

    private var options: [String] {
        exercise.options.isEmpty ? [exercise.blank] : exercise.options
    }

    private var selectedWord: String { options[selectedIndex] }

    private var isCorrect: Bool {
        normalize(selectedWord) == normalize(exercise.blank)
    }

    private var blankColor: Color {
        if !submitted { return .accentColor }
        return isCorrect ? Color("BrandGreen") : Color(.systemRed)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                // Header
                Text("Fill in the blank")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                // Sentence card — blank updates as wheel turns
                sentenceCard
                    .animation(.easeInOut(duration: 0.12), value: selectedIndex)

                // Wheel picker
                wheelPicker

                // Hint
                if let hint = exercise.hint {
                    HStack(spacing: 5) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text(hint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Check button
                Button(action: submit) {
                    Text("Check")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            submitted ? Color(.systemGray4) : Color("BrandGreen"),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .foregroundStyle(submitted ? Color(.systemGray) : .white)
                }
                .buttonStyle(.plain)
                .disabled(submitted)
                .animation(.easeInOut(duration: 0.15), value: submitted)
            }
            .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - Sentence card

    private var sentenceCard: some View {
        // Split on the first blank only; ignore additional blanks (API guard)
        let rawParts = exercise.sentence.components(separatedBy: "___")
        let before   = rawParts.first ?? ""
        let after    = rawParts.count > 1
            ? rawParts[1].components(separatedBy: "___").first ?? ""
            : ""

        let display = Text(before).foregroundColor(.primary)
            + Text(selectedWord)
                  .foregroundColor(blankColor)
                  .bold()
            + Text(after).foregroundColor(.primary)

        return display
            .font(.title3.weight(.semibold))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .padding(.horizontal, 20)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(blankColor.opacity(submitted ? 0.55 : 0.2), lineWidth: 1.5)
            )
    }

    // MARK: - Wheel picker

    private var wheelPicker: some View {
        VStack(spacing: 0) {
            // Label row
            HStack {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("Spin to select")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("\(options.count) options")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            Picker("Answer", selection: $selectedIndex) {
                ForEach(Array(options.enumerated()), id: \.offset) { i, word in
                    Text(word)
                        .font(.body.weight(.medium))
                        .tag(i)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
            .disabled(submitted)
        }
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    // MARK: - Submit

    private func submit() {
        guard !submitted else { return }
        HapticsService.shared.tap()
        submitted = true
        if isCorrect {
            HapticsService.shared.correctAnswer()
        } else {
            HapticsService.shared.wrongAnswer()
        }
        onAnswer(selectedWord, isCorrect)
    }

    // MARK: - Normalise for comparison

    private func normalize(_ s: String) -> String {
        s.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Preview

#Preview("Fill Blank — wheel with options") {
    ScrollView {
        FillBlankView(
            exercise: FillBlankExercise(
                id: "fb-1",
                topic: "a1_sein",
                sentence: "Ich ___ Student.",
                blank: "bin",
                options: ["bin", "bist", "ist", "sind", "war", "waren"],
                hint: "First-person singular of sein",
                explanation: "\"Ich bin\" — first-person singular present tense of sein."
            ),
            onAnswer: { answer, correct in print("Answer: \(answer), correct: \(correct)") }
        )
        .padding(20)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Fill Blank — no options (fallback)") {
    ScrollView {
        FillBlankView(
            exercise: FillBlankExercise(
                id: "fb-2",
                topic: "a1_prepositions",
                sentence: "Ich gehe ___ Hause.",
                blank: "nach",
                hint: nil,
                explanation: "\"nach Hause\" is an idiomatic expression for going home."
            ),
            onAnswer: { _, _ in }
        )
        .padding(20)
    }
    .background(Color(.systemGroupedBackground))
}
