import SwiftUI

/// Inline badge showing "🔥 N" for the learner's current streak.
/// Renders nothing (`EmptyView`) when `streak == 0`.
/// Adds a subtle repeating pulse on the flame emoji when `streak >= 7`.
struct StreakBadgeView: View {
    let streak: Int

    @State private var pulsing = false

    private var shouldPulse: Bool { streak >= 7 }

    var body: some View {
        if streak == 0 {
            EmptyView()
        } else {
            HStack(spacing: 2) {
                Text("🔥")
                    .font(.subheadline)
                    .scaleEffect(pulsing ? 1.18 : 1.0)
                    .animation(
                        shouldPulse
                            ? .easeInOut(duration: 0.85).repeatForever(autoreverses: true)
                            : .default,
                        value: pulsing
                    )

                Text("\(streak)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemOrange).opacity(0.12), in: Capsule())
            .onAppear {
                if shouldPulse { pulsing = true }
            }
            .onChange(of: streak) { _, newValue in
                pulsing = newValue >= 7
            }
        }
    }
}

// MARK: - Preview

#Preview("Streak variants") {
    VStack(spacing: 12) {
        StreakBadgeView(streak: 0)   // renders nothing
        StreakBadgeView(streak: 1)
        StreakBadgeView(streak: 6)
        StreakBadgeView(streak: 7)   // pulses
        StreakBadgeView(streak: 30)  // pulses
    }
    .padding()
}
