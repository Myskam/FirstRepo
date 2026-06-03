import SwiftUI

/// Labelled horizontal progress bar used during exercise sessions.
///
/// Renders "Exercise N of M" above a BrandGreen-filled capsule track.
/// The fill width animates with a spring whenever `current` changes.
struct ProgressBarView: View {
    let current: Int
    let total: Int

    // MARK: - Helpers

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return min(Double(current) / Double(total), 1.0)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            // Label
            Text("Exercise \(current) of \(total)")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Track + fill
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Empty track
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    // Filled portion
                    Capsule()
                        .fill(Color("BrandGreen"))
                        .frame(
                            width: max(geo.size.width * fraction, fraction > 0 ? 8 : 0),
                            height: 8
                        )
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.72),
                            value: fraction
                        )
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Preview

#Preview("Progress bar states") {
    VStack(spacing: 24) {
        ProgressBarView(current: 0,  total: 10)
        ProgressBarView(current: 3,  total: 10)
        ProgressBarView(current: 7,  total: 10)
        ProgressBarView(current: 10, total: 10)
    }
    .padding()
}
