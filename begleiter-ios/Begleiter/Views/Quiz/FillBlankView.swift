import SwiftUI

struct FillBlankView: View {
    let exercise: FillBlankExercise
    let onAnswer: (String, Bool) -> Void

    @State private var userInput: String = ""
    @State private var submitted: Bool = false
    @State private var isCorrect: Bool = false
    @FocusState private var fieldFocused: Bool

    // MARK: - Helpers

    /// Replace the first "___" with an underline placeholder for display.
    private var displaySentence: AttributedString {
        let placeholder = "________"
        let raw = exercise.sentence.replacingOccurrences(of: "___", with: placeholder)
        var attributed = AttributedString(raw)
        if let range = attributed.range(of: placeholder) {
            attributed[range].underlineStyle = .single
            attributed[range].foregroundColor = UIColor.label  // matches system text
        }
        return attributed
    }

    private var borderColor: Color {
        guard submitted else { return Color(.separator) }
        return isCorrect ? Color(hex: "#34D399") : Color(hex: "#F87171")
    }

    private var trimmedInput: String {
        userInput.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 1. Sentence with blank placeholder
            Text(displaySentence)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)

            // 2. Hint
            if let hint = exercise.hint {
                Text(hint)
                    .font(.footnote.italic())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // 3. Text field
            TextField("Type your answer…", text: $userInput)
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: submitted ? 2 : 1)
                )
                .focused($fieldFocused)
                .disabled(submitted)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .submitLabel(.done)
                .onSubmit { checkIfReady() }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            fieldFocused = false
                        }
                        .fontWeight(.semibold)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: submitted)

            // Inline result label after submit
            if submitted {
                HStack(spacing: 6) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(isCorrect ? "Correct!" : "Correct answer: \(exercise.blank)")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(isCorrect ? Color(hex: "#34D399") : Color(hex: "#F87171"))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // 4. Check button
            Button(action: submitAnswer) {
                Text("Check")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        trimmedInput.isEmpty || submitted
                            ? Color(.systemGray4)
                            : Color(hex: "#34D399"),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .foregroundStyle(trimmedInput.isEmpty || submitted ? Color(.systemGray) : .white)
            }
            .disabled(trimmedInput.isEmpty || submitted)
            .animation(.easeInOut(duration: 0.15), value: trimmedInput.isEmpty)
        }
        .onAppear {
            // Auto-focus on appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                fieldFocused = true
            }
        }
        .animation(.easeInOut(duration: 0.2), value: submitted)
    }

    // MARK: - Actions

    private func checkIfReady() {
        guard !trimmedInput.isEmpty, !submitted else { return }
        submitAnswer()
    }

    private func submitAnswer() {
        guard !trimmedInput.isEmpty, !submitted else { return }
        fieldFocused = false
        HapticsService.shared.tap()
        let correct = normalize(trimmedInput) == normalize(exercise.blank)
        isCorrect = correct
        submitted = true
        if correct {
            HapticsService.shared.correctAnswer()
        } else {
            HapticsService.shared.wrongAnswer()
        }
        onAnswer(trimmedInput, correct)
    }

    /// Lowercase, trim whitespace, strip punctuation.
    private func normalize(_ text: String) -> String {
        let stripped = text.unicodeScalars.filter { scalar in
            let char = Character(scalar)
            guard let ascii = scalar.value as UInt32? else { return true }
            let punctuation: [UInt32] = [
                46, 44, 33, 63, 59, 58, 39, 34, 40, 41  // . , ! ? ; : ' " ( )
            ]
            return !punctuation.contains(ascii)
        }
        return String(stripped).lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
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

#Preview("Fill in the Blank") {
    ScrollView {
        FillBlankView(
            exercise: FillBlankExercise(
                id: "fb-1",
                topic: "Prepositions",
                sentence: "Ich gehe ___ Hause.",
                blank: "nach",
                hint: "This preposition is used for going home.",
                explanation: "\"nach Hause\" is the correct idiomatic expression."
            ),
            onAnswer: { answer, correct in
                print("Answer: \(answer), Correct: \(correct)")
            }
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
