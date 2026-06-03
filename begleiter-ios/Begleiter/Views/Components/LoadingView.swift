import SwiftUI

/// Full-frame centered loading state with a BrandGreen spinner and a customisable message.
///
/// Drop this into any screen while async work is in-flight:
/// ```swift
/// if viewModel.isLoading {
///     LoadingView(message: "Generating exercises…")
/// }
/// ```
struct LoadingView: View {
    var message: String = "Loading…"

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(Color("BrandGreen"))

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("Default message") {
    LoadingView()
}

#Preview("Custom message") {
    LoadingView(message: "Generating your exercises…")
}
