import SwiftUI

struct MatchPairsView: View {
    let exercise: MatchPairsExercise
    let onAnswer: (String, Bool) -> Void

    @State private var selectedLeft: String? = nil   // pair ID
    @State private var matched: Set<String> = []     // pair IDs correctly matched
    @State private var wrongPair: String? = nil      // pair ID briefly shown as wrong
    @State private var shakeLeft: String? = nil      // pair ID for left shake
    @State private var shakeRight: String? = nil     // pair ID for right shake (wrong right tap)

    // Shuffled right-side items (IDs in display order, decoupled from left)
    @State private var rightOrder: [String] = []

    private var allMatched: Bool { matched.count == exercise.pairs.count }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Hint
            if let hint = exercise.hint {
                Text(hint)
                    .font(.footnote.italic())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Columns
            HStack(alignment: .top, spacing: 12) {
                // Left column (German)
                VStack(spacing: 10) {
                    ForEach(exercise.pairs) { pair in
                        if !matched.contains(pair.id) {
                            PairCard(
                                text: pair.left,
                                cardState: leftState(for: pair.id),
                                shakeOffset: shakeOffset(id: pair.id, side: .left)
                            ) {
                                handleLeftTap(pair: pair)
                            }
                            .transition(.asymmetric(
                                insertion: .identity,
                                removal: .opacity.combined(with: .scale(scale: 0.85))
                            ))
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                // Right column (English, shuffled)
                VStack(spacing: 10) {
                    ForEach(rightOrder, id: \.self) { pairID in
                        if let pair = exercise.pairs.first(where: { $0.id == pairID }),
                           !matched.contains(pairID) {
                            PairCard(
                                text: pair.right,
                                cardState: rightState(for: pairID),
                                shakeOffset: shakeOffset(id: pairID, side: .right)
                            ) {
                                handleRightTap(pair: pair)
                            }
                            .transition(.asymmetric(
                                insertion: .identity,
                                removal: .opacity.combined(with: .scale(scale: 0.85))
                            ))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: matched)

            // Completion state
            if allMatched {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: "#34D399"))
                    Text("All matched!")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(hex: "#34D399"))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear {
            rightOrder = exercise.pairs.map(\.id).shuffled()
        }
    }

    // MARK: - State helpers

    private func leftState(for id: String) -> CardState {
        if wrongPair == id { return .wrong }
        if selectedLeft == id { return .selected }
        return .idle
    }

    private func rightState(for id: String) -> CardState {
        if wrongPair == id || shakeRight == id { return .wrong }
        return .idle
    }

    private enum ShakeSide { case left, right }

    private func shakeOffset(id: String, side: ShakeSide) -> CGFloat {
        switch side {
        case .left:  return wrongPair == id ? 1 : 0
        case .right: return (wrongPair == id || shakeRight == id) ? 1 : 0
        }
    }

    // MARK: - Interaction

    private func handleLeftTap(pair: MatchPair) {
        guard wrongPair == nil else { return }
        HapticsService.shared.tap()
        selectedLeft = selectedLeft == pair.id ? nil : pair.id
    }

    private func handleRightTap(pair: MatchPair) {
        guard wrongPair == nil else { return }
        HapticsService.shared.tap()

        guard let leftID = selectedLeft else {
            // No left selected — flash the right card as a reminder
            shakeRight = pair.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                shakeRight = nil
            }
            return
        }

        if leftID == pair.id {
            // Correct match
            HapticsService.shared.correctAnswer()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                _ = matched.insert(pair.id)
            }
            selectedLeft = nil

            if matched.count == exercise.pairs.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    onAnswer("matched", true)
                }
            }
        } else {
            // Wrong match — shake both, reset after 500 ms
            HapticsService.shared.wrongAnswer()
            wrongPair = leftID   // highlight the chosen left as wrong too

            // Also highlight the tapped right
            shakeRight = pair.id

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                wrongPair = nil
                shakeRight = nil
                selectedLeft = nil
            }
        }
    }
}

// MARK: - Card state

private enum CardState {
    case idle, selected, correct, wrong
}

// MARK: - Pair card

private struct PairCard: View {
    let text: String
    let cardState: CardState
    let shakeOffset: CGFloat
    let action: () -> Void

    @State private var shaking: Bool = false

    private var backgroundColor: Color {
        switch cardState {
        case .idle:     return Color(.secondarySystemGroupedBackground)
        case .selected: return Color(hex: "#3B82F6").opacity(0.15)
        case .correct:  return Color(hex: "#34D399").opacity(0.2)
        case .wrong:    return Color(hex: "#F87171").opacity(0.15)
        }
    }

    private var borderColor: Color {
        switch cardState {
        case .idle:     return Color(.separator)
        case .selected: return Color(hex: "#3B82F6")
        case .correct:  return Color(hex: "#34D399")
        case .wrong:    return Color(hex: "#F87171")
        }
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(backgroundColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: cardState == .idle ? 1 : 1.5)
                )
        }
        .buttonStyle(.plain)
        .offset(x: shaking ? 6 : 0)
        .onChange(of: shakeOffset) { _, newValue in
            guard newValue != 0 else {
                shaking = false
                return
            }
            withAnimation(.easeInOut(duration: 0.06).repeatCount(4, autoreverses: true)) {
                shaking = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                shaking = false
            }
        }
        .animation(.easeInOut(duration: 0.15), value: cardState)
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

#Preview("Match Pairs") {
    ScrollView {
        MatchPairsView(
            exercise: MatchPairsExercise(
                id: "mp-1",
                topic: "Common Verbs",
                pairs: [
                    MatchPair(id: "1", left: "gehen", right: "to go"),
                    MatchPair(id: "2", left: "essen", right: "to eat"),
                    MatchPair(id: "3", left: "schlafen", right: "to sleep"),
                    MatchPair(id: "4", left: "trinken", right: "to drink"),
                ],
                hint: "Match each German verb with its English translation.",
                explanation: "These are common everyday verbs in German."
            ),
            onAnswer: { answer, correct in
                print("Answer: \(answer), Correct: \(correct)")
            }
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
