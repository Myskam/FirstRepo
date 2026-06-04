import Foundation

final class SessionService {
    static let shared = SessionService()
    private init() {}

    func buildSession(profile: StudentProfile) async throws -> [Exercise] {
        // Focus the session on 1–2 related topics from the earliest unlocked unit.
        let focusTopics = CourseStructure.shared.selectTopicsForSession(for: profile)

        // Narrow the profile to just those topics so the prompt stays focused.
        // If selection came back empty (edge case), fall back to the full profile.
        var focusedProfile = profile
        if !focusTopics.isEmpty {
            focusedProfile.topics = profile.topics.filter { focusTopics.contains($0.key) }
        }

        // Try Claude first; fall back to bundled exercises on failure
        do {
            let exercises = try await APIService.shared.generateSessionExercises(
                profile: focusedProfile,
                count: 8  // Fewer exercises, more focused
            )
            return exercises.isEmpty ? fallbackExercises() : exercises
        } catch BegleiterError.apiKeyMissing {
            throw BegleiterError.apiKeyMissing
        } catch {
            return fallbackExercises()
        }
    }

    func buildSummary(profile: StudentProfile, answers: [Answer]) async throws -> SessionSummary {
        do {
            return try await APIService.shared.generateSessionSummary(profile: profile, answers: answers)
        } catch {
            // Offline summary fallback
            let correctTopics = Set(answers.filter { $0.isCorrect }.map { $0.topic })
            let wrongTopics = Set(answers.filter { !$0.isCorrect }.map { $0.topic })
            let strong = Array(correctTopics.subtracting(wrongTopics))
            let weak = Array(wrongTopics)
            return SessionSummary(strongTopics: strong, weakTopics: weak, recommendation: "Great effort! Keep practicing to improve.")
        }
    }

    private func fallbackExercises() -> [Exercise] {
        guard let url = Bundle.main.url(forResource: "a1_greetings", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [] }
        struct Wrapper: Decodable { let exercises: [Exercise] }
        return (try? JSONDecoder().decode(Wrapper.self, from: data))?.exercises ?? []
    }
}
