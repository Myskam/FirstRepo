import Foundation

struct Answer: Codable {
    let exerciseId: String
    let topic: String
    let isCorrect: Bool
    let userAnswer: String
    let correctAnswer: String
    let timeSeconds: Double
}

struct SessionSummary: Codable {
    let strongTopics: [String]
    let weakTopics: [String]
    let recommendation: String
}

struct DiagnosticQuestion: Codable, Identifiable {
    let id: String
    let topic: String
    let type: String          // "multiple_choice" or "fill_blank"
    let question: String
    let options: [String]?
    let correct: String
    let explanation: String
}
