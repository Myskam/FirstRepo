import Foundation
import Observation

@Observable
final class ProfileViewModel {
    var profile: StudentProfile?
    var isLoading = false

    private let service = ProfileService.shared

    init() {
        Task { await loadProfile() }
    }

    @MainActor
    func loadProfile() async {
        profile = await service.load()
    }

    @MainActor
    func saveProfile(_ p: StudentProfile) async {
        await service.save(p)
        profile = p
    }

    @MainActor
    func deleteProfile() async {
        await service.delete()
        profile = nil
    }

    @MainActor
    func transitionTopic(_ topicId: String, isCorrect: Bool) async {
        guard var p = profile else { return }
        await service.transitionTopic(topicId, isCorrect: isCorrect, profile: &p)
        profile = p
    }

    @MainActor
    func updateStreak() async {
        guard var p = profile else { return }
        await service.updateStreak(profile: &p)
        profile = p
    }

    @MainActor
    func activePracticeTopics() async -> [(String, TopicState)] {
        guard let p = profile else { return [] }
        return await service.getActivePracticeTopics(profile: p)
    }

    /// Apply course progression: grant any topics unlocked by recent mastery,
    /// persist the change, and return the newly-unlocked topic ids (in
    /// curriculum order) so the UI can celebrate them.
    @MainActor
    func applyCourseProgression() async -> [String] {
        guard var p = profile else { return [] }
        let newly = CourseStructure.shared.applyProgression(to: &p)
        guard !newly.isEmpty else { return [] }
        await service.save(p)
        profile = p
        return newly
    }

    // MARK: - Preview

    static var preview: ProfileViewModel {
        let vm = ProfileViewModel()
        var p = StudentProfile(level: .a1, studyContext: .selfStudy)
        p.onboardingComplete = true
        p.currentStreak = 5
        p.topics["a1_greetings"] = TopicState(status: .mastered)
        p.topics["a1_sein"] = TopicState(status: .active)
        p.topics["a1_nominativ"] = TopicState(status: .struggling)
        p.unlockedTopics = ["a1_greetings", "a1_sein", "a1_nominativ", "a1_numbers"]
        vm.profile = p
        return vm
    }
}
