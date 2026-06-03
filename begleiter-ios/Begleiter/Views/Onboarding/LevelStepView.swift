import SwiftUI

// MARK: - LevelStepView

/// Onboarding step 2 of 4.
/// The user picks their self-assessed CEFR level.
struct LevelStepView: View {
    @Binding var selection: CefrLevel?
    let onNext: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("What's your German level?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("We'll use this as a starting point — the diagnostic will fine-tune it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 16)
            .padding(.horizontal, 24)

            // Level cards
            VStack(spacing: 12) {
                ForEach(CefrLevel.allCases, id: \.self) { level in
                    LevelCard(
                        level: level,
                        isSelected: selection == level
                    ) {
                        HapticsService.shared.tap()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selection = level
                        }
                    }
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 20)

            Spacer()

            // Continue button
            Button(action: {
                HapticsService.shared.tap()
                onNext()
            }) {
                Text("Continue")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        selection != nil
                            ? Color("BrandGreen")
                            : Color(.systemGray4),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .foregroundStyle(selection != nil ? .white : Color(.systemGray))
            }
            .buttonStyle(.plain)
            .disabled(selection == nil)
            .animation(.easeInOut(duration: 0.2), value: selection)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}

// MARK: - LevelCard

private struct LevelCard: View {
    let level: CefrLevel
    let isSelected: Bool
    let onTap: () -> Void

    // MARK: - Derived

    private var badge: String { level.rawValue }

    private var description: String {
        switch level {
        case .a1:     return "Complete Beginner — I know almost nothing"
        case .a2:     return "Elementary — I know basic phrases and grammar"
        case .b1:     return "Intermediate — I can handle everyday situations"
        case .b2plus: return "Upper Intermediate — I can discuss complex topics"
        }
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // CEFR badge pill
                Text(badge)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isSelected ? .white : Color("BrandGreen"))
                    .frame(width: 44, height: 44)
                    .background(
                        isSelected ? Color("BrandGreen") : Color("BrandGreen").opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .animation(.easeInOut(duration: 0.15), value: isSelected)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color("BrandGreen") : Color(.systemGray3))
                    .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color(isSelected ? .secondarySystemBackground : .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color("BrandGreen") : Color(.separator),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Preview

#Preview("Level Step — nothing selected") {
    @Previewable @State var selection: CefrLevel? = nil
    LevelStepView(selection: $selection, onNext: {})
}

#Preview("Level Step — B1 selected") {
    @Previewable @State var selection: CefrLevel? = .b1
    LevelStepView(selection: $selection, onNext: {})
}
