import SwiftUI

// MARK: - RotatingWheelView

/// A rotating dial puzzle. Options sit evenly around a ring; the learner spins
/// the ring so the right answer lands under the fixed pointer at the top, then
/// taps Check.
///
/// Implementation notes:
/// - Labels are positioned directly from `baseAngle + rotation` (rather than
///   rotating a container), so text always stays upright.
/// - The selected item is the one whose effective angle is closest to the top.
/// - Dragging anywhere on the dial rotates it by the *angular* delta around the
///   centre, which feels like turning a real wheel. On release it snaps to the
///   nearest option with a spring.
/// - `exercise.options.first` is the correct answer; the displayed order is
///   shuffled and the dial starts on a wrong option so it's never pre-solved.
struct RotatingWheelView: View {
    let exercise: RotatingWheelExercise
    let onAnswer: (String, Bool) -> Void

    @State private var wheel: [String] = []
    @State private var rotation: Double = 0          // degrees, clockwise
    @State private var lastDragAngle: Double? = nil
    @State private var lastSelectedIndex: Int = 0
    @State private var submitted = false
    @State private var isCorrect = false

    // MARK: - Geometry

    private let wheelSize: CGFloat = 280
    private var dialRadius: CGFloat { wheelSize / 2 - 40 }
    private var center: CGPoint { CGPoint(x: wheelSize / 2, y: wheelSize / 2) }

    // MARK: - Derived

    private var items: [String] { wheel.isEmpty ? exercise.options : wheel }
    private var itemAngle: Double { 360.0 / Double(max(items.count, 1)) }
    private var correctWord: String { exercise.options.first ?? "" }

    /// Index of the option currently under the top pointer.
    private var selectedIndex: Int {
        let n = items.count
        guard n > 0 else { return 0 }
        let raw = Int((-rotation / itemAngle).rounded())
        return ((raw % n) + n) % n
    }

    private var selectedWord: String {
        guard items.indices.contains(selectedIndex) else { return "" }
        return items[selectedIndex]
    }

    private var resultColor: Color {
        isCorrect ? Color("BrandGreen") : Color(.systemRed)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            Text("Spin the dial to the correct answer")
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Prompt
            Text(exercise.center)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )

            dial

            if let hint = exercise.hint, !submitted {
                HStack(spacing: 5) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            checkButton
        }
        .padding(.top, 8)
        .onAppear(perform: configure)
    }

    // MARK: - Dial

    private var dial: some View {
        ZStack {
            // Concentric rings for a puzzle-like look
            Circle().stroke(Color(.separator), lineWidth: 1.5)
            Circle()
                .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
                .padding(26)

            // Highlighted slot under the pointer
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill((submitted ? resultColor : Color.accentColor).opacity(0.14))
                .frame(width: 88, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(submitted ? resultColor : Color.accentColor, lineWidth: 1.5)
                )
                .position(x: center.x, y: center.y - dialRadius)

            // Option labels around the ring
            ForEach(Array(items.enumerated()), id: \.offset) { index, option in
                label(option, index: index)
            }

            // Centre hub
            Circle()
                .fill(Color.accentColor)
                .frame(width: 10, height: 10)
                .position(center)

            // Fixed pointer at the very top
            Image(systemName: "arrowtriangle.down.fill")
                .font(.title3)
                .foregroundStyle(submitted ? resultColor : Color.accentColor)
                .position(x: center.x, y: center.y - dialRadius - 30)
        }
        .frame(width: wheelSize, height: wheelSize)
        .contentShape(Circle())
        .gesture(spinGesture)
        .disabled(submitted)
    }

    private func label(_ option: String, index: Int) -> some View {
        let effective = (Double(index) * itemAngle + rotation) * .pi / 180
        let x = center.x + dialRadius * CGFloat(sin(effective))
        let y = center.y - dialRadius * CGFloat(cos(effective))
        let isSelected = index == selectedIndex

        let color: Color = {
            if submitted && isSelected { return resultColor }
            return isSelected ? Color("BrandGreen") : .primary
        }()

        return Text(option)
            .font(.subheadline.weight(isSelected ? .bold : .medium))
            .foregroundStyle(color)
            .scaleEffect(isSelected ? 1.18 : 0.92)
            .opacity(isSelected ? 1 : 0.6)
            .frame(width: 84)
            .multilineTextAlignment(.center)
            .position(x: x, y: y)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }

    private var checkButton: some View {
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

    // MARK: - Gesture

    private var spinGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !submitted else { return }
                let current = angle(of: value.location)
                if let last = lastDragAngle {
                    rotation += normalizedDelta(current - last)
                    tickIfSelectionChanged()
                }
                lastDragAngle = current
            }
            .onEnded { _ in
                lastDragAngle = nil
                let snapped = (rotation / itemAngle).rounded() * itemAngle
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    rotation = snapped
                }
            }
    }

    /// Angle (degrees) of a point relative to the dial centre.
    private func angle(of point: CGPoint) -> Double {
        atan2(Double(point.y - center.y), Double(point.x - center.x)) * 180 / .pi
    }

    /// Reduce an angular difference to (-180, 180] to handle wrap-around.
    private func normalizedDelta(_ d: Double) -> Double {
        var x = d.truncatingRemainder(dividingBy: 360)
        if x > 180 { x -= 360 }
        if x <= -180 { x += 360 }
        return x
    }

    private func tickIfSelectionChanged() {
        let idx = selectedIndex
        if idx != lastSelectedIndex {
            lastSelectedIndex = idx
            HapticsService.shared.selection()
        }
    }

    // MARK: - Lifecycle

    private func configure() {
        guard wheel.isEmpty else { return }
        var shuffled = exercise.options.shuffled()
        // Defensive: ensure the correct word is present.
        if !shuffled.contains(correctWord), !correctWord.isEmpty {
            shuffled.append(correctWord)
        }
        wheel = shuffled

        // Start the dial on a wrong option so it's never pre-solved.
        if let wrongIndex = shuffled.firstIndex(where: { $0 != correctWord }) {
            rotation = -Double(wrongIndex) * (360.0 / Double(shuffled.count))
        }
        lastSelectedIndex = selectedIndex
    }

    // MARK: - Submit

    private func submit() {
        guard !submitted else { return }
        HapticsService.shared.tap()
        isCorrect = normalize(selectedWord) == normalize(correctWord)
        submitted = true
        if isCorrect {
            HapticsService.shared.correctAnswer()
        } else {
            HapticsService.shared.wrongAnswer()
        }
        onAnswer(selectedWord, isCorrect)
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
                center: "Der Tisch ist sehr ___",
                options: ["groß", "klein", "neu", "alt", "schön", "teuer"],
                context: nil,
                hint: "Which adjective means \u{201C}big\u{201D}?",
                explanation: "\u{201E}gro\u{00DF}\u{201C} means \u{201C}big\u{201D} \u{2014} a common adjective for size."
            ),
            onAnswer: { answer, correct in print("Answer: \(answer), correct: \(correct)") }
        )
        .padding(20)
    }
    .background(Color(.systemGroupedBackground))
}
