import Foundation

enum BegleiterError: LocalizedError {
    case apiKeyMissing
    case networkError(URLError)
    case parsingError(String)
    case rateLimited
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "No API key found. Please add your Anthropic API key in Settings."
        case .networkError(let e):
            return "Network error: \(e.localizedDescription)"
        case .parsingError(let detail):
            return "Could not parse response: \(detail)"
        case .rateLimited:
            return "Rate limit reached. Please wait a moment and try again."
        case .serverError(let code):
            return "Server error (\(code)). Please try again."
        }
    }
}

actor APIService {
    static let shared = APIService()

    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let haiku = "claude-haiku-4-5-20251001"
    private let sonnet = "claude-sonnet-4-6"

    private init() {}

    // MARK: - Public API

    func generateDiagnosticQuestions(coveredTopics: [String], level: String, count: Int) async throws -> [DiagnosticQuestion] {
        let prompt = """
You are a German language diagnostic tool assessing a student's actual knowledge.

Student profile:
- CEFR level: \(level)
- Self-reported topics covered: \(coveredTopics.joined(separator: ", "))

Generate \(count) diagnostic questions that verify whether the student truly understands what they've reported. Start simple, increase difficulty. Each question targets exactly one topic from the covered list.

Rules:
- Stay within vocabulary appropriate for \(level)
- Never use grammar above the student's stated level in the question itself
- Mix multiple_choice and fill_blank types
- Return ONLY valid JSON. No preamble, no markdown, no explanation.

Response format:
{"questions": [{"id": "string","topic": "topic_id","type": "multiple_choice | fill_blank","question": "string","options": ["string"] or null,"correct": "string","explanation": "string — friendly 1-sentence explanation"}]}
"""
        let raw = try await withRetry { [self] in try await call(prompt: prompt, model: self.haiku) }
        let cleaned = stripFences(raw)
        struct Wrapper: Decodable { let questions: [DiagnosticQuestion] }
        do {
            return try JSONDecoder().decode(Wrapper.self, from: Data(cleaned.utf8)).questions
        } catch {
            throw BegleiterError.parsingError(error.localizedDescription)
        }
    }

    func generateSessionExercises(profile: StudentProfile, count: Int) async throws -> [Exercise] {
        let mastered = profile.topics.filter { $0.value.status == .mastered }.keys.joined(separator: ", ")
        let active = profile.topics.filter { $0.value.status == .active || $0.value.status == .struggling }
            .keys.joined(separator: ", ")
        let struggling = profile.topics.filter { $0.value.status == .struggling }.keys.joined(separator: ", ")
        let recent = profile.topics.values
            .flatMap { $0.sessionHistory.suffix(2).flatMap { $0.errorTopics } }
            .joined(separator: ", ")

        let prompt = """
You are a German language tutor generating personalized practice exercises.

Student profile:
- CEFR level: \(profile.level.rawValue)
- Mastered topics: \(mastered.isEmpty ? "none yet" : mastered)
- Active practice topics (focus these): \(active.isEmpty ? "none yet" : active)
- Known weak points: \(struggling.isEmpty ? "none" : struggling)
- Recent session notes: \(recent.isEmpty ? "none" : recent)

Generate \(count) exercises targeting the active practice topics, weighted toward weak points.

Rules:
- All sentences must be ORIGINAL — never reproduce published content
- Vocabulary must be appropriate for \(profile.level.rawValue) per CEFR descriptors
- Vary question types: multiple_choice, fill_blank, match_pairs, reorder_words, article_tap, sentence_correction
- Prefer article_tap for noun-gender topics; prefer sentence_correction for grammar mistakes
- Explanation must be friendly and explain the grammar rule in plain English
- Return ONLY valid JSON. No preamble, no markdown, no explanation.

Response format — each exercise has "type" plus type-specific fields:
- multiple_choice: {"id","topic","type":"multiple_choice","question","options":["string"],"correct","hint","explanation"}
- fill_blank: {"id","topic","type":"fill_blank","sentence":"text with ___ for blank","blank","hint","explanation"}
- match_pairs: {"id","topic","type":"match_pairs","pairs":[{"left","right"}],"hint","explanation"}
- reorder_words: {"id","topic","type":"reorder_words","words":["shuffled"],"correct":"correct sentence","hint","explanation"}
- article_tap: {"id","topic","type":"article_tap","noun":"Tisch","context":"___ Tisch ist groß. (optional)","correct":"der|die|das","hint","explanation"}
- sentence_correction: {"id","topic","type":"sentence_correction","words":["Ich","kaufe","einen","Buch"],"wrongIndex":2,"correction":"ein","hint","explanation"}

Wrap all exercises in: {"exercises": [...]}
"""
        let raw = try await withRetry { [self] in try await call(prompt: prompt, model: self.haiku) }
        let cleaned = stripFences(raw)
        return try parseExercises(from: cleaned)
    }

    func generateSessionSummary(profile: StudentProfile, answers: [Answer]) async throws -> SessionSummary {
        let profileSummary = "Level: \(profile.level.rawValue), Mastered: \(profile.masteredCount), Active: \(profile.activeCount), Struggling: \(profile.strugglingCount)"
        let sessionDesc = answers.map { "\($0.topic): \($0.isCorrect ? "correct" : "wrong")" }.joined(separator: "; ")

        let prompt = """
You are analyzing a student's German practice session to provide feedback.

Current profile summary: \(profileSummary)
Session results: \(sessionDesc)

Analyze performance by topic. Identify what went well and what needs more work.

Rules:
- strongTopics: topic IDs where error rate was below 20%
- weakTopics: topic IDs where error rate exceeded 40%
- recommendation: one encouraging sentence personalised to their actual performance
- Return ONLY valid JSON.

Response format:
{"sessionSummary": {"strongTopics": ["topic_id"],"weakTopics": ["topic_id"],"recommendation": "string"}}
"""
        let raw = try await withRetry { [self] in try await call(prompt: prompt, model: self.sonnet) }
        let cleaned = stripFences(raw)
        struct Wrapper: Decodable { let sessionSummary: SessionSummary }
        do {
            return try JSONDecoder().decode(Wrapper.self, from: Data(cleaned.utf8)).sessionSummary
        } catch {
            throw BegleiterError.parsingError(error.localizedDescription)
        }
    }

    // MARK: - Private helpers

    private func call(prompt: String, model: String) async throws -> String {
        guard let apiKey = KeychainHelper.loadAPIKey(), !apiKey.isEmpty else {
            throw BegleiterError.apiKeyMissing
        }
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("true", forHTTPHeaderField: "anthropic-dangerous-direct-browser-access")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "messages": [["role": "user", "content": prompt]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        if statusCode == 429 { throw BegleiterError.rateLimited }
        if statusCode >= 500 { throw BegleiterError.serverError(statusCode) }

        struct APIResponse: Decodable {
            struct Content: Decodable { let text: String }
            let content: [Content]
        }
        let decoded = try JSONDecoder().decode(APIResponse.self, from: data)
        return decoded.content.first?.text ?? ""
    }

    private func withRetry<T>(operation: () async throws -> T) async throws -> T {
        var lastError: Error?
        for attempt in 0..<3 {
            do {
                return try await operation()
            } catch let urlError as URLError {
                lastError = BegleiterError.networkError(urlError)
                if attempt < 2 {
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
                }
            } catch {
                throw error
            }
        }
        throw lastError ?? BegleiterError.networkError(URLError(.unknown))
    }

    private func stripFences(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("```json") { s = String(s.dropFirst(7)) }
        else if s.hasPrefix("```") { s = String(s.dropFirst(3)) }
        if s.hasSuffix("```") { s = String(s.dropLast(3)) }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseExercises(from json: String) throws -> [Exercise] {
        struct RawExercise: Decodable {
            let id: String
            let topic: String
            let type: String
            let question: String?
            let sentence: String?
            let blank: String?
            let options: [String]?
            let pairs: [RawPair]?
            let words: [String]?
            let correct: String?
            let hint: String?
            let explanation: String
            // article_tap
            let noun: String?
            let context: String?
            // sentence_correction
            let wrongIndex: Int?
            let correction: String?
        }
        struct RawPair: Decodable { let left: String; let right: String }
        struct Wrapper: Decodable { let exercises: [RawExercise] }

        let wrapper: Wrapper
        do {
            wrapper = try JSONDecoder().decode(Wrapper.self, from: Data(json.utf8))
        } catch {
            throw BegleiterError.parsingError(error.localizedDescription)
        }

        return wrapper.exercises.compactMap { raw in
            switch raw.type {
            case "multiple_choice":
                guard let q = raw.question, let opts = raw.options, let c = raw.correct else { return nil }
                return .multipleChoice(MultipleChoiceExercise(id: raw.id, topic: raw.topic, question: q, options: opts, correct: c, hint: raw.hint, explanation: raw.explanation))
            case "fill_blank":
                guard let sentence = raw.sentence, let blank = raw.blank else { return nil }
                return .fillBlank(FillBlankExercise(id: raw.id, topic: raw.topic, sentence: sentence, blank: blank, hint: raw.hint, explanation: raw.explanation))
            case "match_pairs":
                guard let rawPairs = raw.pairs else { return nil }
                let pairs = rawPairs.enumerated().map { MatchPair(id: "\(raw.id)_\($0.offset)", left: $0.element.left, right: $0.element.right) }
                return .matchPairs(MatchPairsExercise(id: raw.id, topic: raw.topic, pairs: pairs, hint: raw.hint, explanation: raw.explanation))
            case "reorder_words":
                guard let words = raw.words, let correct = raw.correct else { return nil }
                return .reorderWords(ReorderWordsExercise(id: raw.id, topic: raw.topic, words: words, correct: correct, hint: raw.hint, explanation: raw.explanation))
            case "article_tap":
                guard let noun = raw.noun, let correct = raw.correct else { return nil }
                return .articleTap(ArticleTapExercise(id: raw.id, topic: raw.topic, noun: noun, context: raw.context, correct: correct, hint: raw.hint, explanation: raw.explanation))
            case "sentence_correction":
                guard let words = raw.words, let wrongIndex = raw.wrongIndex, let correction = raw.correction else { return nil }
                return .sentenceCorrection(SentenceCorrectionExercise(id: raw.id, topic: raw.topic, words: words, wrongIndex: wrongIndex, correction: correction, hint: raw.hint, explanation: raw.explanation))
            default:
                return nil
            }
        }
    }
}
