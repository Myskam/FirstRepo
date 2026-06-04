import SwiftUI

// MARK: - RotatingWheelView

/// Interactive rotating wheel exercise.
///
/// The user rotates a wheel of options to select the correct answer.
/// The selected option is shown at the top and highlighted.
struct RotatingWheelView: View {
    let exercise: RotatingWheelExercise
    let onAnswer: (String, Bool) -> Void

    @State private var rotationAngle: Double = 0
    @State private var submitted = false
    @State private var isCorrect = false

    // MARK: - Derived

    private var options: [String] { exercise.options }
    private let itemsPerCircle = 360.0

    private var itemAngle: Double { itemsPerCircle / Double(options.count) }

    private var selectedIndex: Int {
        let normalized = ((rotationAngle.truncatingRemainder(dividingBy: itemsPerCircle)) + itemsPerCircle)
            .truncatingRemainder(dividingBy: itemsPerCircle)
        let index = Int(round(normalized / itemAngle))
        return index % options.count
    }

    private var selectedWord: String { options[selectedIndex] }

    private var centerColor: Color {
        if !submitted { return .primary }
        return isCorrect ? Color("BrandGreen") : Color(.systemRed)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                // Header
                Text("Select the correct option")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                // Center prompt
                Text(exercise.center)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)
                    .background(
                        Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(centerColor.opacity(submitted ? 0.55 : 0.2), lineWidth: 1.5)
                    )

                // Rotating wheel
                wheelSection

                // Context/hint
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

    // MARK: - Wheel section

    private var wheelSection: some View {
        VStack(spacing: 12) {
            // Selection indicator
            HStack {
                Image(systemName: "arrowshape.down.fill")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text(selectedWord)
                    .font(.body.weight(.bold))
                    .foregroundStyle(centerColor)
                Spacer()
            }
            .frame(height: 30)

            // Wheel with gesture
            ZStack {
                Circle()
                    .stroke(Color(.separator), lineWidth: 1)

                // Draw options around the wheel
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    wheelItem(option, index: index)
                }

                // Center dot
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 8, height: 8)
            }
            .frame(height: 240)
            .rotationEffect(.degrees(rotationAngle))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard !submitted else { return }
                        let delta = value.translation.width / 100
                        rotationAngle = (rotationAngle + delta).truncatingRemainder(dividingBy: 360)
                    }
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedIndex)
            .disabled(submitted)
        }
    }

    // MARK: - Wheel item

    private func wheelItem(_ option: String, index: Int) -> some View {
        let angle = Double(index) * itemAngle
        let isSelected = index == selectedIndex
        let radius: CGFloat = 100

        return Text(option)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSelected ? Color("BrandGreen") : Color.primary)
            .scaleEffect(isSelected ? 1.15 : 0.9)
            .opacity(isSelected ? 1.0 : 0.7)
            .position(
                x: 120 + radius * CGFloat(cos((angle - 90) * .pi / 180)),
                y: 120 + radius * CGFloat(sin((angle - 90) * .pi / 180))
            )
    }

    // MARK: - Submit

    private func submit() {
        guard !submitted else { return }
        HapticsService.shared.tap()
        submitted = true
        let correct = normalize(selectedWord) == normalize(exercise.options.first ?? "")
        isCorrect = correct
        if correct {
            HapticsService.shared.correctAnswer()
        } else {
            HapticsService.shared.wrongAnswer()
        }
        onAnswer(selectedWord, correct)
    }

    private func normalize(_ s: String) -> String {
        s.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Preview

#Preview("Rotating Wheel") {
    ScrollView {
        RotatingWheelView(
            exercise: RotatingWheelExercise(
                id: "rw-1",
                topic: "a1_adjectives",
                center: "Der Tisch ist...",
                options: ["groß", "klein", "neu", "alt", "schön"],
                context: nil,
                hint: "Select the adjective meaning 'big'",
                explanation: "\"Groß\" means 'big' or 'large'. It's a common adjective for describing the size of objects."
            ),
            onAnswer: { answer, correct in print("Answer: \(answer), correct: \(correct)") }
        )
        .padding(20)
    }
    .background(Color(.systemGroupedBackground))
}
