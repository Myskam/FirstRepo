import SwiftUI

// MARK: - ComboMeterView

/// Displays the current answer combo and total XP in a compact header row.
/// The combo badge is only visible once the player has 2+ consecutive correct answers.
struct ComboMeterView: View {
    let combo: Int
    let xp: Int
    let lastXP: Int   // XP from the last correct answer — drives the pop animation

    @State private var xpScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 0) {
            // Combo badge — slides in when combo reaches 2+
            if combo >= 2 {
                comboBadge
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.6).combined(with: .opacity),
                        removal: .scale(scale: 0.6).combined(with: .opacity)
                    ))
            }

            Spacer()

            // XP counter (always visible)
            xpCounter
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: combo)
        .onChange(of: lastXP) { _, newXP in
            guard newXP > 0 else { return }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { xpScale = 1.3 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { xpScale = 1.0 }
            }
        }
    }

    // MARK: - Sub-views

    private var comboBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.orange)
            Text("\(combo)×")
                .font(.caption.weight(.bold))
                .foregroundStyle(.orange)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.orange.opacity(0.14), in: Capsule())
        .overlay(Capsule().strokeBorder(Color.orange.opacity(0.3), lineWidth: 1))
    }

    private var xpCounter: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.yellow)
            Text("\(xp) XP")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .scaleEffect(xpScale)
        .animation(.spring(response: 0.2), value: xpScale)
    }
}

// MARK: - Preview

#Preview("Combo meter — active combo") {
    VStack(spacing: 20) {
        ComboMeterView(combo: 0, xp: 10,  lastXP: 10)
        ComboMeterView(combo: 2, xp: 40,  lastXP: 15)
        ComboMeterView(combo: 4, xp: 100, lastXP: 20)
    }
    .padding(20)
}
