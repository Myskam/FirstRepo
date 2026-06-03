import SwiftUI

/// Centred error-state card shown when an operation fails.
///
/// Displays a `wifi.exclamationmark` icon, a human-readable title
/// derived from `BegleiterError` (or a generic fallback), the error's
/// `localizedDescription`, and a "Try Again" button that fires `retry`.
struct ErrorView: View {
    let error: Error
    let retry: () -> Void

    // MARK: - Title resolution

    private var title: String {
        guard let begleiter = error as? BegleiterError else {
            return "Something Went Wrong"
        }
        switch begleiter {
        case .apiKeyMissing:   return "API Key Missing"
        case .networkError:    return "Network Error"
        case .parsingError:    return "Parsing Error"
        case .rateLimited:     return "Rate Limited"
        case .serverError:     return "Server Error"
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(Color(.systemRed))
                .symbolEffect(.pulse)

            // Text block
            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Retry button
            Button {
                HapticsService.shared.tap()
                retry()
            } label: {
                Text("Try Again")
                    .font(.subheadline.weight(.semibold))
                    .frame(minWidth: 120)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("BrandGreen"))
        }
        .padding(24)
        .frame(maxWidth: 340)
        .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("Network error") {
    ErrorView(
        error: BegleiterError.networkError(URLError(.notConnectedToInternet))
    ) { }
}

#Preview("API key missing") {
    ErrorView(error: BegleiterError.apiKeyMissing) { }
}

#Preview("Rate limited") {
    ErrorView(error: BegleiterError.rateLimited) { }
}

#Preview("Server error") {
    ErrorView(error: BegleiterError.serverError(503)) { }
}
