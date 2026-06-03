import SwiftUI
import UserNotifications

// MARK: - SettingsView

struct SettingsView: View {
    @Environment(ProfileViewModel.self) var profileVM
    @Environment(\.dismiss) var dismiss

    // MARK: - API Key state

    @State private var apiKeyInput: String = ""
    @State private var apiKeySaved: Bool = false
    @FocusState private var keyFieldFocused: Bool

    // MARK: - Notifications state

    @State private var notificationsEnabled: Bool = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - Data / reset state

    @State private var showResetConfirmation: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                apiKeySection
                notificationsSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        HapticsService.shared.tap()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("BrandGreen"))
                }
            }
            .task {
                await loadInitialState()
            }
            .alert("Reset Profile?", isPresented: $showResetConfirmation) {
                Button("Reset", role: .destructive) {
                    Task { @MainActor in
                        await profileVM.deleteProfile()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your progress. This cannot be undone.")
            }
        }
    }

    // MARK: - Sections

    private var apiKeySection: some View {
        Section {
            // Saved status indicator
            if apiKeySaved {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color("BrandGreen"))
                    Text("API key saved")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color("BrandGreen"))
                    Spacer()
                }
                .padding(.vertical, 2)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // Input field
            SecureField("sk-ant-api03-…", text: $apiKeyInput)
                .textContentType(.password)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($keyFieldFocused)

            // Save button
            Button {
                HapticsService.shared.tap()
                keyFieldFocused = false
                saveAPIKey()
            } label: {
                Text(apiKeySaved ? "Replace Key" : "Save Key")
                    .foregroundStyle(
                        apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color(.systemGray)
                            : Color("BrandGreen")
                    )
            }
            .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty)
        } header: {
            Text("API Key")
        } footer: {
            Text("Your Anthropic API key is stored securely in the iOS Keychain and never sent to our servers.")
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: apiKeySaved)
    }

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $notificationsEnabled) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Reminder")
                        Text("Every day at 19:00")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(Color(.systemOrange))
                }
            }
            .tint(Color("BrandGreen"))
            .onChange(of: notificationsEnabled) { _, newValue in
                Task { @MainActor in
                    await handleNotificationToggle(enabled: newValue)
                }
            }
            .disabled(notificationStatus == .denied)

            if notificationStatus == .denied {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(.secondary)
                    Text("Notifications are disabled in Settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Link("Open Settings",
                         destination: URL(string: UIApplication.openSettingsURLString)!)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                }
            }
        } header: {
            Text("Notifications")
        }
    }

    private var dataSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                Label("Reset Profile", systemImage: "trash.fill")
            }
        } header: {
            Text("Data")
        } footer: {
            Text("Deletes all progress, topics, and streaks. Cannot be undone.")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }

            Text("Not affiliated with Hueber Verlag or any publisher. Begleiter is an independent study companion that generates original exercises using the Claude AI API.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } header: {
            Text("About")
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func loadInitialState() async {
        // Check if API key exists
        apiKeySaved = KeychainHelper.loadAPIKey() != nil

        // Check notification authorization status
        let status = await NotificationService.shared.authorizationStatus()
        notificationStatus = status

        // Determine if toggle should be on:
        // enabled only when authorized AND there's a pending daily reminder
        if status == .authorized {
            let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
            notificationsEnabled = pending.contains { $0.identifier == "begleiter.daily.reminder" }
        } else {
            notificationsEnabled = false
        }
    }

    private func saveAPIKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        KeychainHelper.saveAPIKey(trimmed)
        withAnimation { apiKeySaved = true }
        apiKeyInput = ""
    }

    private func handleNotificationToggle(enabled: Bool) async {
        if enabled {
            // Request permission if not yet determined
            if notificationStatus == .notDetermined {
                let granted = await NotificationService.shared.requestAuthorization()
                notificationStatus = await NotificationService.shared.authorizationStatus()
                if !granted {
                    notificationsEnabled = false
                    return
                }
            }
            guard notificationStatus == .authorized else {
                notificationsEnabled = false
                return
            }
            NotificationService.shared.scheduleDailyReminder()
        } else {
            NotificationService.shared.cancelDailyReminder()
        }
    }
}

// MARK: - Preview

#Preview("Settings") {
    SettingsView()
        .environment(ProfileViewModel.preview)
}
