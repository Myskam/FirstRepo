import SwiftUI

// MARK: - OnboardingWelcomeView

/// Hero splash shown as the first screen of the onboarding flow.
/// Animates the flag emoji on appear, lists app value-props, then
/// requests notification permission before calling `onNext`.
struct OnboardingWelcomeView: View {
    let onNext: () -> Void

    // MARK: - State

    @State private var flagScale: CGFloat = 0.4
    @State private var flagVisible: Bool = false
    @State private var contentVisible: Bool = false
    @State private var isRequestingPermission: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Brandenburg Gate behind the waving flag hero
            ZStack(alignment: .bottom) {
                BrandenburgGate(width: 220, tint: Color(.systemGray3))
                    .opacity(flagVisible ? 0.5 : 0)
                    .offset(y: 24)

                WavingGermanFlag(width: 150, height: 110)
                    .scaleEffect(flagScale)
                    .opacity(flagVisible ? 1 : 0)
            }
            .padding(.bottom, 24)

            // Title
            Text("Willkommen bei Begleiter")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 12)

            // Tricolour accent under the title
            GermanFlagStripe(height: 5)
                .frame(width: 96)
                .padding(.top, 10)
                .opacity(contentVisible ? 1 : 0)

            // Subtitle
            Text("Your personal AI German tutor")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .padding(.horizontal, 32)
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 12)

            // Bullet points
            VStack(alignment: .leading, spacing: 14) {
                BulletRow(text: "AI-generated exercises tailored to you")
                BulletRow(text: "Tracks your progress across 60 topics")
                BulletRow(text: "Works offline with fallback exercises")
            }
            .padding(.top, 32)
            .padding(.horizontal, 40)
            .opacity(contentVisible ? 1 : 0)
            .offset(y: contentVisible ? 0 : 16)

            // Culture badge row
            HStack(spacing: 14) {
                CultureBadge(emoji: "🥨", label: "Pretzel")
                CultureBadge(emoji: "🍺", label: "Beer")
                CultureBadge(emoji: "🏰", label: "Castle")
                CultureBadge(emoji: "🥖", label: "Bread")
            }
            .padding(.top, 28)
            .opacity(contentVisible ? 1 : 0)
            .offset(y: contentVisible ? 0 : 16)

            Spacer()
            Spacer()

            // CTA button
            Button {
                guard !isRequestingPermission else { return }
                isRequestingPermission = true
                HapticsService.shared.tap()
                Task {
                    await NotificationService.shared.requestAuthorization()
                    onNext()
                }
            } label: {
                HStack(spacing: 6) {
                    Text("Jetzt loslegen")
                        .font(.body.weight(.semibold))
                    Text("→")
                        .font(.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("BrandGreen"), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(isRequestingPermission)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(contentVisible ? 1 : 0)
            .offset(y: contentVisible ? 0 : 20)
        }
        .onAppear {
            // Flag bounces in first
            withAnimation(.spring(response: 0.55, dampingFraction: 0.6, blendDuration: 0)) {
                flagScale = 1.0
                flagVisible = true
            }
            // Content fades/slides in shortly after
            withAnimation(.easeOut(duration: 0.45).delay(0.25)) {
                contentVisible = true
            }
        }
    }
}

// MARK: - BulletRow

private struct BulletRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(German.red)
                .padding(.top, 2)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

#Preview("Welcome") {
    OnboardingWelcomeView(onNext: {})
}
