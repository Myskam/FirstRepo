import SwiftUI

// MARK: - View-model

@Observable
private final class SetupViewModel {
    var apiKeyInput: String = ""
    var isSaved: Bool = false
    var showSavedAlert: Bool = false

    init() {
        isSaved = KeychainHelper.loadAPIKey() != nil
    }

    func saveKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        KeychainHelper.saveAPIKey(trimmed)
        isSaved = true
        apiKeyInput = ""
        showSavedAlert = true
    }
}

// MARK: - View

/// Allows the user to enter and persist their Anthropic API key.
///
/// - The key is written to the iOS Keychain via `KeychainHelper`.
/// - A BrandGreen checkmark pill confirms an existing key.
/// - A secure text field accepts a new (or replacement) key.
/// - Privacy note reassures the user the key never leaves the device.
struct SetupView: View {
    @State private var viewModel = SetupViewModel()
    @FocusState private var fieldFocused: Bool

    private var saveDisabled: Bool {
        viewModel.apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // ── Header ──────────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 6) {
                    Text("Anthropic API Key")
                        .font(.title2.weight(.bold))

                    Text("Begleiter uses the Claude API to generate personalised German exercises.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // ── Saved-key status pill ────────────────────────────────────
                if viewModel.isSaved {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Color("BrandGreen"))
                        Text("API key saved")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color("BrandGreen"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color("BrandGreen").opacity(0.10), in: Capsule())
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                // ── Input section ────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.isSaved ? "Replace existing key" : "Enter your key")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)

                    // Secure field
                    SecureField("sk-ant-api03-…", text: $viewModel.apiKeyInput)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($fieldFocused)
                        .padding(12)
                        .background(
                            Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(
                                    fieldFocused ? Color("BrandGreen") : Color(.separator),
                                    lineWidth: fieldFocused ? 1.5 : 0.5
                                )
                        )
                        .animation(.easeInOut(duration: 0.2), value: fieldFocused)

                    // Save button
                    Button {
                        HapticsService.shared.tap()
                        fieldFocused = false
                        viewModel.saveKey()
                    } label: {
                        Text("Save Key")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("BrandGreen"))
                    .disabled(saveDisabled)
                }

                // ── Privacy note ─────────────────────────────────────────────
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lock.shield")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Your key is stored securely in the Keychain, never sent to our servers.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(
                    Color(.tertiarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )

                // ── External link ────────────────────────────────────────────
                Link(destination: URL(string: "https://console.anthropic.com/account/keys")!) {
                    HStack(spacing: 4) {
                        Text("Get your API key at console.anthropic.com")
                            .font(.footnote)
                        Image(systemName: "arrow.up.right")
                            .font(.footnote)
                    }
                    .foregroundStyle(Color("BrandGreen"))
                }
            }
            .padding(20)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: viewModel.isSaved)
        }
        .navigationTitle("API Key Setup")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Key Saved", isPresented: $viewModel.showSavedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your API key has been stored securely in the Keychain.")
        }
    }
}

// MARK: - Preview

#Preview("No key stored") {
    NavigationStack {
        SetupView()
    }
}

#Preview("Key already exists") {
    KeychainHelper.saveAPIKey("sk-ant-preview-key-placeholder")
    return NavigationStack {
        SetupView()
    }
}
