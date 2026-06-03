import SwiftUI

/// Compact coloured pill label showing a `TopicStatus`.
/// Uses a matching SF Symbol and background tint so it reads at a glance.
struct BadgeView: View {
    let status: TopicStatus

    // MARK: - Computed label text

    private var label: String {
        switch status {
        case .notCovered: return "Not started"
        case .introduced: return "Introduced"
        case .active:     return "Practicing"
        case .struggling: return "Struggling"
        case .mastered:   return "Mastered"
        }
    }

    // MARK: - SF Symbol per status

    private var icon: String {
        switch status {
        case .notCovered: return "circle"
        case .introduced: return "book.circle"
        case .active:     return "flame.circle"
        case .struggling: return "exclamationmark.circle"
        case .mastered:   return "checkmark.circle.fill"
        }
    }

    // MARK: - Foreground colour

    private var foreground: Color {
        switch status {
        case .notCovered: return Color(.secondaryLabel)
        case .introduced: return Color(.systemBlue)
        case .active:     return Color(.systemOrange)
        case .struggling: return Color(.systemRed)
        case .mastered:   return Color("BrandGreen")
        }
    }

    // MARK: - Background tint (low-opacity fill inside capsule)

    private var background: Color {
        switch status {
        case .notCovered: return Color(.systemGray5)
        case .introduced: return Color(.systemBlue).opacity(0.12)
        case .active:     return Color(.systemOrange).opacity(0.12)
        case .struggling: return Color(.systemRed).opacity(0.12)
        case .mastered:   return Color("BrandGreen").opacity(0.12)
        }
    }

    // MARK: - Body

    var body: some View {
        Label(label, systemImage: icon)
            .font(.caption.weight(.medium))
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(background, in: Capsule())
    }
}

// MARK: - Preview

#Preview("All statuses") {
    VStack(alignment: .leading, spacing: 10) {
        ForEach(
            [TopicStatus.notCovered, .introduced, .active, .struggling, .mastered],
            id: \.rawValue
        ) { status in
            BadgeView(status: status)
        }
    }
    .padding()
}
