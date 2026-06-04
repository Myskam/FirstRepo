import Foundation

/// Defines the course curriculum, topic grouping, and unlock progression.
///
/// Topics are organized into units. Each unit has:
/// - `topics`: the 1-2 core topics to practice in this unit
/// - `nextUnlock`: topics that unlock after mastering this unit
struct CurriculumUnit {
    let id: String
    let displayName: String
    let topics: [String]           // Topics to focus on in this unit
    let nextUnlock: [String]       // Topics to unlock after this unit is completed
}

final class CourseStructure {
    static let shared = CourseStructure()

    // Define the A1 curriculum as a progression of units
    private let curriculum: [CurriculumUnit] = [
        // Unit 0: A1 Basics (always available)
        CurriculumUnit(
            id: "a1_basics",
            displayName: "Greetings & Basics",
            topics: ["a1_greetings"],
            nextUnlock: ["a1_sein", "a1_numbers"]
        ),

        // Unit 1: Sein verb (unlocked after greetings)
        CurriculumUnit(
            id: "a1_sein_unit",
            displayName: "The Verb 'Sein'",
            topics: ["a1_sein"],
            nextUnlock: ["a1_nominativ", "a1_pronouns", "a1_present_regular"]
        ),

        // Unit 2: Nominativ case (unlocked after sein)
        CurriculumUnit(
            id: "a1_nominativ_unit",
            displayName: "Nominativ Case",
            topics: ["a1_nominativ"],
            nextUnlock: ["a1_akkusativ", "a1_plural"]
        ),

        // Unit 3: Regular verbs & present (unlocked after sein)
        CurriculumUnit(
            id: "a1_present_unit",
            displayName: "Present Tense Verbs",
            topics: ["a1_present_regular"],
            nextUnlock: ["a1_present_irregular", "a1_modal_verbs", "a1_word_order"]
        ),

        // Unit 4: Akkusativ case (unlocked after nominativ)
        CurriculumUnit(
            id: "a1_akkusativ_unit",
            displayName: "Akkusativ Case",
            topics: ["a1_akkusativ"],
            nextUnlock: ["a1_adjectives_pred"]
        ),

        // Unit 5: Irregular verbs (unlocked after regular)
        CurriculumUnit(
            id: "a1_irregular_unit",
            displayName: "Irregular Verbs",
            topics: ["a1_present_irregular"],
            nextUnlock: ["a1_haben", "a1_perfekt"]
        ),

        // Unit 6: Modal verbs (unlocked after regular)
        CurriculumUnit(
            id: "a1_modal_unit",
            displayName: "Modal Verbs",
            topics: ["a1_modal_verbs"],
            nextUnlock: ["a1_separable_verbs"]
        ),

        // Unit 7: Perfect tense (unlocked after irregular)
        CurriculumUnit(
            id: "a1_perfekt_unit",
            displayName: "Perfect Tense (Perfekt)",
            topics: ["a1_perfekt"],
            nextUnlock: ["a1_past_tense"]
        ),
    ]

    private init() {}

    /// Get all topics that should be unlocked for a new user (A1 fundamentals).
    func getInitialUnlockedTopics() -> Set<String> {
        [curriculum.first?.topics.first ?? ""]  // Just greetings to start
    }

    /// Get the next topics to unlock based on current unlocked state and profile progress.
    func getUnlockedTopics(for profile: StudentProfile) -> Set<String> {
        var unlocked = profile.unlockedTopics

        // Check each unit: if all its topics are mastered, unlock the next batch
        for unit in curriculum {
            let unitTopicsAreMastered = unit.topics.allSatisfy {
                profile.topics[$0]?.status == .mastered
            }
            if unitTopicsAreMastered && !unlocked.contains(unit.topics.first ?? "") {
                // This unit is done, unlock next topics
                unlocked.formUnion(unit.nextUnlock)
            }
        }

        return unlocked
    }

    /// Get active topics (that can be practiced right now) within the unlocked set.
    func getAvailablePracticeTopics(for profile: StudentProfile) -> [String] {
        let unlocked = getUnlockedTopics(for: profile)
        return profile.topics.keys.filter { topicId in
            unlocked.contains(topicId) &&
            [.active, .struggling, .introduced].contains(profile.topics[topicId]?.status)
        }.sorted()
    }

    /// Get 1-2 related topics from the available set, grouped by unit.
    func selectTopicsForSession(availableTopics: [String]) -> [String] {
        guard !availableTopics.isEmpty else { return [] }

        // Find the first unit that has an active topic
        for unit in curriculum {
            let unitTopicsInAvailable = unit.topics.filter { availableTopics.contains($0) }
            if !unitTopicsInAvailable.isEmpty {
                // Return up to 2 topics from this unit
                return Array(unitTopicsInAvailable.prefix(2))
            }
        }

        // Fallback: return first available topic
        return [availableTopics.first ?? ""]
    }
}
