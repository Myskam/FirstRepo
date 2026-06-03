import SwiftUI

// MARK: - SentenceCorrectionView

/// Game-style exercise: a sentence with one grammatical error is displayed
/// as tappable word chips. The student taps the incorrect word to answer.
struct SentenceCorrectionView: View {
    let exercise: SentenceCorrectionExercise
    let onAnswer: (String, Bool) -> Void

    @State private var correctTap: Int? = nil
    @State private var wrongFlash: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("Find the mistake")
                    .font(.title2.bold())
                Text("Tap the incorrect word in the sentence")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Word chips — wrapping flow layout
            SentenceFlowLayout(spacing: 10) {
                ForEach(Array(exercise.words.enumerated()), id: \.offset) { index, word in
                    CorrectionChip(
                        word: word,
                        state: chipState(for: index)
                    ) {
                        tap(index: index)
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
            }

            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - State

    private func chipState(for index: Int) -> CorrectionChipState {
        if let t = correctTap, t == index { return .correct }
        if let w = wrongFlash, w == index { return .wrong }
        if correctTap != nil { return .dimmed }
        return .idle
    }

    private func tap(index: Int) {
        guard correctTap == nil && wrongFlash == nil else { return }
        HapticsService.shared.tap()
        let isCorrect = index == exercise.wrongIndex

        if isCorrect {
            correctTap = index
            HapticsService.shared.correctAnswer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onAnswer(exercise.words[index], true)
            }
        } else {
            wrongFlash = index
            HapticsService.shared.wrongAnswer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                wrongFlash = nil
                onAnswer(exercise.words[index], false)
            }
        }
    }
}

// MARK: - Chip state + view

private enum CorrectionChipState: Equatable {
    case idle, correct, wrong, dimmed
}

private struct CorrectionChip: View {
    let word: String
    let state: CorrectionChipState
    let action: () -> Void

    private var background: Color {
        switch state {
        case .idle:   return Color(.secondarySystemGroupedBackground)
        case .correct: return Color("BrandGreen")
        case .wrong:  return Color(.systemRed)
        case .dimmed: return Color(.systemGray5)
        }
    }

    private var foreground: Color {
        switch state {
        case .correct, .wrong: return .white
        default:               return .primary
        }
    }

    private var borderColor: Color {
        switch state {
        case .idle:   return Color(.separator)
        case .correct: return Color("BrandGreen")
        case .wrong:  return Color(.systemRed)
        case .dimmed: return Color.clear
        }
    }

    var body: some View {
        Button(action: action) {
            Text(word)
                .font(.body.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 1.5)
                )
                .foregroundStyle(foreground)
        }
        .buttonStyle(.plain)
        .disabled(state != .idle)
        .animation(.easeInOut(duration: 0.2), value: state)
    }
}

// MARK: - Flow layout

/// Wraps word chips onto new rows, matching CSS `flex-wrap` behaviour.
private struct SentenceFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowH: CGFloat = 0
        var totalH: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += rowH + spacing
                totalH = y
                x = 0
                rowH = 0
            }
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
        return CGSize(width: maxWidth, height: totalH + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowH: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowH + spacing
                x = bounds.minX
                rowH = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
    }
}

// MARK: - Preview

#Preview("Sentence Correction") {
    ScrollView {
        SentenceCorrectionView(
            exercise: SentenceCorrectionExercise(
                id: "sc-1",
                topic: "a1_articles",
                words: ["Ich", "kaufe", "einen", "Buch", "für", "die", "Schule."],
                wrongIndex: 2,
                correction: "ein",
                hint: "Think about the gender of \"Buch\"",
                explanation: "\"Buch\" is neuter (das Buch), so the accusative article is \"ein\", not \"einen\"."
            ),
            onAnswer: { word, correct in print("Tapped: \(word), correct: \(correct)") }
        )
        .padding(20)
    }
    .background(Color(.systemGroupedBackground))
}
