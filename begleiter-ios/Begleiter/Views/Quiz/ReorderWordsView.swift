import SwiftUI

struct ReorderWordsView: View {
    let exercise: ReorderWordsExercise
    let onAnswer: (String, Bool) -> Void

    @State private var answerWords: [String] = []
    @State private var poolWords: [String] = []
    @State private var submitted: Bool = false
    @State private var isCorrect: Bool = false

    // MARK: - Helpers

    private var answerSentence: String {
        answerWords.joined(separator: " ")
    }

    private var canSubmit: Bool {
        !answerWords.isEmpty && !submitted
    }

    private func normalize(_ text: String) -> String {
        text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // 1. Instruction
            Text("Put the words in the correct order")
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)

            // 2. Hint
            if let hint = exercise.hint {
                Text(hint)
                    .font(.footnote.italic())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // 3. Answer area
            answerArea

            // 4. Word pool
            wordPool

            // Inline result label after submit
            if submitted {
                HStack(spacing: 6) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(isCorrect ? "Correct!" : "Correct answer: \(exercise.correct)")
                        .font(.subheadline.weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(isCorrect ? Color(hex: "#34D399") : Color(hex: "#F87171"))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // 5. Check button
            Button(action: submitAnswer) {
                Text("Check")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        canSubmit
                            ? Color(hex: "#34D399")
                            : Color(.systemGray4),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .foregroundStyle(canSubmit ? .white : Color(.systemGray))
            }
            .disabled(!canSubmit)
            .animation(.easeInOut(duration: 0.15), value: canSubmit)
        }
        .onAppear {
            poolWords = exercise.words.shuffled()
        }
        .animation(.easeInOut(duration: 0.2), value: submitted)
        .animation(.easeInOut(duration: 0.15), value: answerWords)
        .animation(.easeInOut(duration: 0.15), value: poolWords)
    }

    // MARK: - Answer area

    private var answerArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your answer")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(answerAreaBorderColor, lineWidth: submitted ? 2 : 1)
                    .background(
                        Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )

                if answerWords.isEmpty {
                    Text("Tap words below to build your answer…")
                        .font(.body)
                        .foregroundStyle(Color(.placeholderText))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                } else {
                    // Flowing token row — tap a token to return it to the pool
                    FlowLayout(spacing: 8) {
                        ForEach(Array(answerWords.enumerated()), id: \.offset) { index, word in
                            WordToken(
                                word: word,
                                style: submitted
                                    ? (isCorrect ? .correct : .wrong)
                                    : .answer,
                                disabled: submitted
                            ) {
                                returnWordToPool(at: index)
                            }
                        }
                    }
                    .padding(10)
                }
            }
            .frame(minHeight: 64)
        }
    }

    private var answerAreaBorderColor: Color {
        guard submitted else { return Color(.separator) }
        return isCorrect ? Color(hex: "#34D399") : Color(hex: "#F87171")
    }

    // MARK: - Word pool

    private var wordPool: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Word bank")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if poolWords.isEmpty && !submitted {
                Text("All words placed")
                    .font(.footnote)
                    .foregroundStyle(Color(.placeholderText))
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .center)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(Array(poolWords.enumerated()), id: \.offset) { index, word in
                        WordToken(
                            word: word,
                            style: .pool,
                            disabled: submitted
                        ) {
                            moveWordToAnswer(at: index)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func moveWordToAnswer(at poolIndex: Int) {
        guard !submitted else { return }
        HapticsService.shared.tap()
        let word = poolWords.remove(at: poolIndex)
        answerWords.append(word)
    }

    private func returnWordToPool(at answerIndex: Int) {
        guard !submitted else { return }
        HapticsService.shared.tap()
        let word = answerWords.remove(at: answerIndex)
        poolWords.append(word)
    }

    private func submitAnswer() {
        guard canSubmit else { return }
        HapticsService.shared.tap()
        let correct = normalize(answerSentence) == normalize(exercise.correct)
        isCorrect = correct
        submitted = true
        if correct {
            HapticsService.shared.correctAnswer()
        } else {
            HapticsService.shared.wrongAnswer()
        }
        onAnswer(answerSentence, correct)
    }
}

// MARK: - Token style

private enum TokenStyle {
    case pool, answer, correct, wrong
}

// MARK: - Word token button

private struct WordToken: View {
    let word: String
    let style: TokenStyle
    let disabled: Bool
    let action: () -> Void

    private var backgroundColor: Color {
        switch style {
        case .pool:    return Color(.secondarySystemGroupedBackground)
        case .answer:  return Color(hex: "#3B82F6").opacity(0.12)
        case .correct: return Color(hex: "#34D399").opacity(0.18)
        case .wrong:   return Color(hex: "#F87171").opacity(0.15)
        }
    }

    private var borderColor: Color {
        switch style {
        case .pool:    return Color(.separator)
        case .answer:  return Color(hex: "#3B82F6")
        case .correct: return Color(hex: "#34D399")
        case .wrong:   return Color(hex: "#F87171")
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .pool, .answer: return .primary
        case .correct:       return Color(hex: "#059669")
        case .wrong:         return Color(hex: "#DC2626")
        }
    }

    var body: some View {
        Button(action: action) {
            Text(word)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(foregroundColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(backgroundColor, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .animation(.easeInOut(duration: 0.12), value: style)
    }
}

// MARK: - Flow layout (wrapping HStack)

/// A layout that wraps its children onto new rows like CSS flexbox `flex-wrap`.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += rowHeight + spacing
                totalHeight = y
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
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

#Preview("Reorder Words") {
    ScrollView {
        ReorderWordsView(
            exercise: ReorderWordsExercise(
                id: "rw-1",
                topic: "Word Order",
                words: ["ich", "morgen", "gehe", "früh", "nach", "Hause"],
                correct: "Morgen gehe ich früh nach Hause",
                hint: "Remember: time expressions often come before the subject in German.",
                explanation: "In German, adverbs of time like \"morgen\" often trigger verb-second word order, pushing the subject after the verb."
            ),
            onAnswer: { answer, correct in
                print("Answer: \(answer), Correct: \(correct)")
            }
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
