import Foundation

/// A unit of the curriculum: a small group of related topics the learner
/// practises together, plus the topics that unlock once the unit is mastered.
struct CurriculumUnit {
    let id: String
    let displayName: String
    let topics: [String]      // 1–2 closely related topics practised together
    let nextUnlock: [String]  // topics that unlock once every topic here is mastered
}

/// Drives the course progression: which topics are unlocked, which to practise
/// next, and how mastery opens up later units.
///
/// Design:
/// - The learner starts with whatever they reported knowing during onboarding
///   (plus the very first unit). Those are their initial `unlockedTopics`.
/// - When every topic in a unit reaches `.mastered`, that unit's `nextUnlock`
///   topics become available. Newly-unlocked topics are flipped to
///   `.introduced` so they're immediately practisable, and the unlock set is
///   persisted on the profile.
/// - A session focuses on 1–2 related topics from the earliest unlocked unit
///   that still needs work, rather than a random scattering.
final class CourseStructure {
    static let shared = CourseStructure()
    private init() {}

    // MARK: - Curriculum definition (A1 progression)

    private let curriculum: [CurriculumUnit] = [
        CurriculumUnit(
            id: "u_greetings",
            displayName: "Greetings & Basics",
            topics: ["a1_greetings"],
            nextUnlock: ["a1_sein", "a1_numbers"]
        ),
        CurriculumUnit(
            id: "u_numbers",
            displayName: "Numbers & Time",
            topics: ["a1_numbers"],
            nextUnlock: ["a1_time"]
        ),
        CurriculumUnit(
            id: "u_sein",
            displayName: "The Verb \u{201E}sein\u{201C}",
            topics: ["a1_sein"],
            nextUnlock: ["a1_pronouns", "a1_nominativ"]
        ),
        CurriculumUnit(
            id: "u_pronouns",
            displayName: "Personal Pronouns",
            topics: ["a1_pronouns"],
            nextUnlock: ["a1_present_regular"]
        ),
        CurriculumUnit(
            id: "u_nominativ",
            displayName: "Nominativ Case",
            topics: ["a1_nominativ"],
            nextUnlock: ["a1_haben", "a1_plural", "a1_akkusativ"]
        ),
        CurriculumUnit(
            id: "u_haben",
            displayName: "The Verb \u{201E}haben\u{201C}",
            topics: ["a1_haben"],
            nextUnlock: []
        ),
        CurriculumUnit(
            id: "u_present",
            displayName: "Present Tense Verbs",
            topics: ["a1_present_regular"],
            nextUnlock: ["a1_present_irregular", "a1_modal_verbs", "a1_word_order", "a1_questions", "a1_negation"]
        ),
        CurriculumUnit(
            id: "u_akkusativ",
            displayName: "Akkusativ Case",
            topics: ["a1_akkusativ"],
            nextUnlock: ["a1_adjectives_pred"]
        ),
        CurriculumUnit(
            id: "u_irregular",
            displayName: "Irregular & Modal Verbs",
            topics: ["a1_present_irregular", "a1_modal_verbs"],
            nextUnlock: ["a1_separable_verbs", "a1_perfekt"]
        ),
        CurriculumUnit(
            id: "u_perfekt",
            displayName: "Perfect Tense (Perfekt)",
            topics: ["a1_perfekt"],
            nextUnlock: []
        ),
    ]

    /// Topic ids in their pedagogical order across the whole curriculum.
    private lazy var orderedTopicIDs: [String] = curriculum.flatMap(\.topics)

    private let practisableStatuses: Set<TopicStatus> = [.active, .struggling, .introduced]

    // MARK: - Initial unlock

    /// The set a learner starts with: everything they already reported knowing
    /// (any non-`notCovered` topic) plus the very first unit, so there is always
    /// at least one thing to practise.
    func initialUnlockedTopics(for profile: StudentProfile) -> Set<String> {
        var unlocked = Set(profile.topics.filter { $0.value.status != .notCovered }.keys)
        if let firstTopic = curriculum.first?.topics.first {
            unlocked.insert(firstTopic)
        }
        return unlocked
    }

    // MARK: - Progression

    /// Compute the full unlocked set given current progress. A unit's
    /// `nextUnlock` is granted once *every* topic in that unit is mastered.
    /// Idempotent — safe to call repeatedly.
    func computeUnlockedTopics(for profile: StudentProfile) -> Set<String> {
        var unlocked = profile.unlockedTopics
        // Iterate to a fixed point so a chain of masteries can cascade in one pass.
        var changed = true
        while changed {
            changed = false
            for unit in curriculum {
                let mastered = unit.topics.allSatisfy { profile.topics[$0]?.status == .mastered }
                guard mastered else { continue }
                for topic in unit.nextUnlock where !unlocked.contains(topic) {
                    unlocked.insert(topic)
                    changed = true
                }
            }
        }
        return unlocked
    }

    /// Apply progression to a profile in place: grants newly-unlocked topics,
    /// flips any that were `.notCovered` to `.introduced` so they can be
    /// practised, and updates `unlockedTopics`.
    ///
    /// - Returns: the topic ids unlocked by this call (empty if nothing new).
    @discardableResult
    func applyProgression(to profile: inout StudentProfile) -> [String] {
        let updated = computeUnlockedTopics(for: profile)
        let newlyUnlocked = updated.subtracting(profile.unlockedTopics)

        for topicId in newlyUnlocked {
            let status = profile.topics[topicId]?.status ?? .notCovered
            if status == .notCovered {
                profile.topics[topicId] = TopicState(status: .introduced)
            }
        }
        profile.unlockedTopics = updated

        // Preserve curriculum order in the returned list.
        return orderedTopicIDs.filter { newlyUnlocked.contains($0) }
    }

    // MARK: - Session selection

    /// Unlocked topics that currently need practice, in curriculum order.
    func availablePracticeTopics(for profile: StudentProfile) -> [String] {
        let unlocked = profile.unlockedTopics.isEmpty
            ? computeUnlockedTopics(for: profile)
            : profile.unlockedTopics

        let practisable = profile.topics
            .filter { unlocked.contains($0.key) && practisableStatuses.contains($0.value.status) }
            .map(\.key)

        // Curriculum-ordered first, then any leftover (e.g. higher-level) topics.
        let ordered = orderedTopicIDs.filter { practisable.contains($0) }
        let leftover = practisable.filter { !orderedTopicIDs.contains($0) }.sorted()
        return ordered + leftover
    }

    /// Choose 1–2 related topics for a session: the earliest unlocked unit that
    /// still has a practisable topic, so practice stays focused and coherent.
    func selectTopicsForSession(for profile: StudentProfile) -> [String] {
        let available = Set(availablePracticeTopics(for: profile))
        guard !available.isEmpty else { return [] }

        for unit in curriculum {
            let hits = unit.topics.filter { available.contains($0) }
            if !hits.isEmpty { return Array(hits.prefix(2)) }
        }
        // Fallback for topics outside the defined units (keeps higher levels working).
        return Array(availablePracticeTopics(for: profile).prefix(2))
    }

    /// Human-readable name of the unit a topic belongs to (for UI labels).
    func unitName(forTopic topicId: String) -> String? {
        curriculum.first { $0.topics.contains(topicId) }?.displayName
    }
}
