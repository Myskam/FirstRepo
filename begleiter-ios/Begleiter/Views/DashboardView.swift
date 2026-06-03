import SwiftUI

// MARK: - DashboardView

struct DashboardView: View {
    @Environment(ProfileViewModel.self) var profileVM
    @State private var showSettings = false
    @State private var navigateToSession = false
    @State private var sessionVM: SessionViewModel?

    // MARK: - Derived

    private var profile: StudentProfile? { profileVM.profile }

    private var canStartSession: Bool {
        guard let p = profile else { return false }
        return p.practiceCount > 0
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    mainContent(profile: profile)
                } else {
                    LoadingView(message: "Loading your profile…")
                }
            }
            .navigationTitle("Begleiter")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let profile {
                        StreakBadgeView(streak: profile.currentStreak)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticsService.shared.tap()
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environment(profileVM)
            }
            .navigationDestination(isPresented: $navigateToSession) {
                if let vm = sessionVM {
                    SessionStartView(sessionVM: vm)
                        .environment(profileVM)
                }
            }
        }
    }

    // MARK: - Main content

    @ViewBuilder
    private func mainContent(profile: StudentProfile) -> some View {
        VStack(spacing: 0) {
            // Stats row
            HStack(spacing: 12) {
                StatCard(
                    title: "Mastered",
                    count: profile.masteredCount,
                    color: Color("BrandGreen"),
                    icon: "checkmark.seal.fill"
                )
                StatCard(
                    title: "Practicing",
                    count: profile.activeCount,
                    color: Color(.systemOrange),
                    icon: "flame.fill"
                )
                StatCard(
                    title: "Struggling",
                    count: profile.strugglingCount,
                    color: Color(.systemRed),
                    icon: "exclamationmark.circle.fill"
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Topic status grid — fills remaining space
            TopicStatusGridView(profile: profile)

            // Bottom action area
            VStack(spacing: 0) {
                Divider()

                Button {
                    HapticsService.shared.tap()
                    sessionVM = SessionViewModel(profileVM: profileVM)
                    navigateToSession = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.body.weight(.semibold))
                        Text("Start Practice")
                            .font(.body.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        canStartSession ? Color("BrandGreen") : Color(.systemGray4),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .foregroundStyle(canStartSession ? .white : Color(.systemGray))
                }
                .buttonStyle(.plain)
                .disabled(!canStartSession)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .animation(.easeInOut(duration: 0.2), value: canStartSession)
            }
            .background(Color(.systemBackground))
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(color)

            Text("\(count)")
                .font(.title2.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.primary)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(color.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Dashboard — active profile") {
    DashboardView()
        .environment(ProfileViewModel.preview)
}

#Preview("Dashboard — no profile yet") {
    DashboardView()
        .environment(ProfileViewModel())
}
