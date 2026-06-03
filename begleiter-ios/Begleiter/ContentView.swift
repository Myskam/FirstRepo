import SwiftUI

struct ContentView: View {
    @Environment(ProfileViewModel.self) var profileVM

    var body: some View {
        Group {
            if let profile = profileVM.profile, profile.onboardingComplete {
                DashboardView()
            } else {
                OnboardingFlow()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: profileVM.profile?.onboardingComplete)
    }
}

#Preview {
    ContentView()
        .environment(ProfileViewModel.preview)
}
