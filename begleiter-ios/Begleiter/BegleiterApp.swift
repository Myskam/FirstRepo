import SwiftUI

@main
struct BegleiterApp: App {
    @State private var profileVM = ProfileViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(profileVM)
        }
    }
}
