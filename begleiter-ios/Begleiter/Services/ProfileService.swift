import Foundation

actor ProfileService {
    static let shared = ProfileService()

    private let key = "begleiter_profile"
    private var profile: StudentProfile?

    private init() {}

    // MARK: - Load / Save

    func load() -> StudentProfile? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let p = try? JSONDecoder().decode(StudentProfile.self, from: data) else { return nil }
        profile = p
        return p
    }

    func save(_ p: StudentProfile) {
        profile = p
        persist(p)
    }

    func delete() {
        profile = nil
        UserDefaults.standard.removeObject(forKey: key)
    }

    // MARK: - State machine

    /// Updates a topic's state after a single answer. Returns updated profile.
    func transitionTopic(_ topicId: String, isCorrect: Bool, profile: inout StudentProfile) {
        var state = profile.topics[topicId] ?? TopicState()
        state.totalAttempts += 1

        if isCorrect {
            state.correctStreak += 1
            state.correctAttempts += 1
            if state.correctStreak >= 3 {
                state.status = .mastered
            } else if state.status == .introduced || state.status == .notCovered || state.status == .struggling {
                state.status = .active
            }
        } else {
            state.correctStreak = 0
            let errorRate = state.totalAttempts > 0 ? Double(state.totalAttempts - state.correctAttempts) / Double(state.totalAttempts) : 0.0
            if errorRate > 0.4 && state.totalAttempts >= 3 {
                state.status = .struggling
            } else if state.status == .notCovered || state.status == .introduced {
                state.status = .active
            }
        }

        state.lastPracticed = ISO8601DateFormatter().string(from: Date())
        profile.topics[topicId] = state
        persist(profile)
    }

    /// Returns up to 5 topics prioritised for the next session (struggling first, then oldest practiced).
    func getActivePracticeTopics(profile: StudentProfile) -> [(String, TopicState)] {
        let eligible = profile.topics.filter { $0.value.status == .active || $0.value.status == .struggling || $0.value.status == .introduced }
        return eligible
            .sorted { a, b in
                if a.value.status == .struggling && b.value.status != .struggling { return true }
                if a.value.status != .struggling && b.value.status == .struggling { return false }
                let dateA = a.value.lastPracticed.flatMap { ISO8601DateFormatter().date(from: $0) } ?? .distantPast
                let dateB = b.value.lastPracticed.flatMap { ISO8601DateFormatter().date(from: $0) } ?? .distantPast
                return dateA < dateB
            }
            .prefix(5)
            .map { ($0.key, $0.value) }
    }

    /// Updates streak based on lastPracticeDate.
    func updateStreak(profile: inout StudentProfile) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        if let last = profile.lastPracticeDate {
            let lastDay = cal.startOfDay(for: last)
            if cal.isDate(lastDay, inSameDayAs: today) {
                return  // already practiced today
            } else if let yesterday = cal.date(byAdding: .day, value: -1, to: today), cal.isDate(lastDay, inSameDayAs: yesterday) {
                profile.currentStreak += 1
            } else {
                profile.currentStreak = 1  // streak broken
            }
        } else {
            profile.currentStreak = 1
        }
        profile.lastPracticeDate = Date()
        persist(profile)
    }

    // MARK: - Private

    private func persist(_ p: StudentProfile) {
        guard let data = try? JSONEncoder().encode(p) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
