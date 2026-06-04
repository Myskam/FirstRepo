import Foundation

enum TopicStatus: String, Codable {
    case notCovered = "not_covered"
    case introduced = "introduced"
    case active = "active"
    case struggling = "struggling"
    case mastered = "mastered"
}

enum StudyContext: String, Codable, CaseIterable {
    case classStudy = "class"
    case selfStudy = "self_study"
    case appOnly = "app_only"

    var displayName: String {
        switch self {
        case .classStudy: return "Classroom"
        case .selfStudy: return "Self-study"
        case .appOnly: return "App only"
        }
    }
}

struct SessionResult: Codable {
    let date: String
    let exerciseCount: Int
    let correctCount: Int
    let errorTopics: [String]
}

struct TopicState: Codable {
    var status: TopicStatus
    var correctStreak: Int
    var totalAttempts: Int
    var correctAttempts: Int
    var lastPracticed: String?
    var sessionHistory: [SessionResult]

    init(status: TopicStatus = .notCovered) {
        self.status = status
        correctStreak = 0
        totalAttempts = 0
        correctAttempts = 0
        lastPracticed = nil
        sessionHistory = []
    }
}

struct StudentProfile: Codable, Identifiable {
    var id: String
    var createdAt: String
    var level: CefrLevel
    var studyContext: StudyContext
    var textbook: String?
    var onboardingComplete: Bool
    var topics: [String: TopicState]
    var currentStreak: Int
    var lastPracticeDate: Date?
    var unlockedTopics: Set<String>  // Topics the user has unlocked; empty = only fundamentals

    init(level: CefrLevel, studyContext: StudyContext) {
        id = UUID().uuidString
        createdAt = ISO8601DateFormatter().string(from: Date())
        self.level = level
        self.studyContext = studyContext
        textbook = nil
        onboardingComplete = false
        topics = [:]
        currentStreak = 0
        lastPracticeDate = nil
        unlockedTopics = []
    }

    // Custom decoder: unlockedTopics defaults to empty if missing
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        createdAt = try c.decode(String.self, forKey: .createdAt)
        level = try c.decode(CefrLevel.self, forKey: .level)
        studyContext = try c.decode(StudyContext.self, forKey: .studyContext)
        textbook = try? c.decode(String.self, forKey: .textbook)
        onboardingComplete = try c.decode(Bool.self, forKey: .onboardingComplete)
        topics = try c.decode([String: TopicState].self, forKey: .topics)
        currentStreak = try c.decode(Int.self, forKey: .currentStreak)
        lastPracticeDate = try? c.decode(Date.self, forKey: .lastPracticeDate)
        unlockedTopics = try c.decodeIfPresent(Set<String>.self, forKey: .unlockedTopics) ?? []
    }

    var masteredCount: Int { topics.values.filter { $0.status == .mastered }.count }
    var activeCount: Int { topics.values.filter { $0.status == .active }.count }
    var strugglingCount: Int { topics.values.filter { $0.status == .struggling }.count }
    var introducedCount: Int { topics.values.filter { $0.status == .introduced }.count }
    var practiceCount: Int { activeCount + strugglingCount + introducedCount }
}
