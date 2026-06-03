import SwiftUI

// MARK: - ContextStepView

/// Onboarding step 1 of 4.
/// The user picks how they intend to use Begleiter (study context).
struct ContextStepView: View {
    @Binding var selection: StudyContext?
    let onNext: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("How will you use Begleiter?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("This helps us tailor your experience.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 16)
            .padding(.horizontal, 24)

            // Option cards
            VStack(spacing: 12) {
                ForEach(StudyContext.allCases, id: \.self) { context in
                    ContextCard(
                        context: context,
                        isSelected: selection == context
                    ) {
                        HapticsService.shared.tap()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selection = context
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

// MARK: - ContextCard

private struct ContextCard: View {
    let context: StudyContext
    let isSelected: Bool
    let onTap: () -> Void

    // MARK: - Derived

    private var icon: String {
        switch context {
        case .classStudy: return "🏫"
        case .selfStudy:  return "📚"
        case .appOnly:    return "📱"
        }
    }

    private var description: String {
        switch context {
        case .classStudy: return "I'm following a course or textbook"
        case .selfStudy:  return "I study on my own schedule"
        case .appOnly:    return "I use only this app to learn"
        }
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Text(icon)
                    .font(.system(size: 36))
                    .frame(width: 48)

                VStack(alignment: .leading, spacing: 3) {
                    Text(context.displayName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

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

#Preview("Context Step — nothing selected") {
    @Previewable @State var selection: StudyContext? = nil
    ContextStepView(selection: $selection, onNext: {})
}

#Preview("Context Step — selfStudy selected") {
    @Previewable @State var selection: StudyContext? = .selfStudy
    ContextStepView(selection: $selection, onNext: {})
}
