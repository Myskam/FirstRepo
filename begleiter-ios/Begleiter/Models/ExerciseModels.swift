import Foundation

// MARK: - Concrete exercise types

struct MultipleChoiceExercise: Codable, Identifiable {
    let id: String
    let topic: String
    let question: String
    let options: [String]
    let correct: String
    let hint: String?
    let explanation: String
}

struct FillBlankExercise: Codable, Identifiable {
    let id: String
    let topic: String
    let sentence: String   // contains exactly one "___"
    let blank: String      // the correct answer
    let options: [String]  // shuffled choices including the correct answer (5–8 items)
    let hint: String?
    let explanation: String

    // Memberwise init so call-sites can omit options (backward compat)
    init(id: String, topic: String, sentence: String, blank: String,
         options: [String] = [], hint: String?, explanation: String) {
        self.id = id; self.topic = topic; self.sentence = sentence
        self.blank = blank; self.options = options; self.hint = hint
        self.explanation = explanation
    }

    // Custom decoder so missing "options" key defaults to [] instead of throwing
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(String.self, forKey: .id)
        topic       = try c.decode(String.self, forKey: .topic)
        sentence    = try c.decode(String.self, forKey: .sentence)
        blank       = try c.decode(String.self, forKey: .blank)
        options     = (try? c.decode([String].self, forKey: .options)) ?? []
        hint        = try? c.decode(String.self, forKey: .hint)
        explanation = try c.decode(String.self, forKey: .explanation)
    }
}

struct MatchPairsExercise: Codable, Identifiable {
    let id: String
    let topic: String
    let pairs: [MatchPair]
    let hint: String?
    let explanation: String
}

struct MatchPair: Codable, Identifiable, Hashable {
    let id: String
    let left: String
    let right: String
}

struct ReorderWordsExercise: Codable, Identifiable {
    let id: String
    let topic: String
    let words: [String]    // shuffled word pool
    let correct: String    // correct sentence
    let hint: String?
    let explanation: String
}

struct ArticleTapExercise: Codable, Identifiable {
    let id: String
    let topic: String
    let noun: String          // e.g. "Tisch" (capitalized, no article)
    let context: String?      // optional sentence e.g. "Ich kaufe ___ Buch."
    let correct: String       // "der", "die", or "das"
    let hint: String?
    let explanation: String
}

struct SentenceCorrectionExercise: Codable, Identifiable {
    let id: String
    let topic: String
    let words: [String]       // sentence pre-split into tappable tokens
    let wrongIndex: Int       // 0-based index of the incorrect word
    let correction: String    // correct replacement for the wrong word
    let hint: String?
    let explanation: String
}

// MARK: - Discriminated union

enum Exercise: Identifiable {
    case multipleChoice(MultipleChoiceExercise)
    case fillBlank(FillBlankExercise)
    case matchPairs(MatchPairsExercise)
    case reorderWords(ReorderWordsExercise)
    case articleTap(ArticleTapExercise)
    case sentenceCorrection(SentenceCorrectionExercise)

    var id: String {
        switch self {
        case .multipleChoice(let e):    return e.id
        case .fillBlank(let e):         return e.id
        case .matchPairs(let e):        return e.id
        case .reorderWords(let e):      return e.id
        case .articleTap(let e):        return e.id
        case .sentenceCorrection(let e): return e.id
        }
    }

    var topic: String {
        switch self {
        case .multipleChoice(let e):    return e.topic
        case .fillBlank(let e):         return e.topic
        case .matchPairs(let e):        return e.topic
        case .reorderWords(let e):      return e.topic
        case .articleTap(let e):        return e.topic
        case .sentenceCorrection(let e): return e.topic
        }
    }

    var explanation: String {
        switch self {
        case .multipleChoice(let e):    return e.explanation
        case .fillBlank(let e):         return e.explanation
        case .matchPairs(let e):        return e.explanation
        case .reorderWords(let e):      return e.explanation
        case .articleTap(let e):        return e.explanation
        case .sentenceCorrection(let e): return e.explanation
        }
    }
}

extension Exercise: Codable {
    private enum TypeKey: String, Codable {
        case multiple_choice, fill_blank, match_pairs, reorder_words, article_tap, sentence_correction
    }

    private enum CodingKeys: String, CodingKey { case type }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type_ = try container.decode(TypeKey.self, forKey: .type)
        let single = try decoder.singleValueContainer()
        switch type_ {
        case .multiple_choice:    self = .multipleChoice(try single.decode(MultipleChoiceExercise.self))
        case .fill_blank:         self = .fillBlank(try single.decode(FillBlankExercise.self))
        case .match_pairs:        self = .matchPairs(try single.decode(MatchPairsExercise.self))
        case .reorder_words:      self = .reorderWords(try single.decode(ReorderWordsExercise.self))
        case .article_tap:        self = .articleTap(try single.decode(ArticleTapExercise.self))
        case .sentence_correction: self = .sentenceCorrection(try single.decode(SentenceCorrectionExercise.self))
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .multipleChoice(let e):    try e.encode(to: encoder)
        case .fillBlank(let e):         try e.encode(to: encoder)
        case .matchPairs(let e):        try e.encode(to: encoder)
        case .reorderWords(let e):      try e.encode(to: encoder)
        case .articleTap(let e):        try e.encode(to: encoder)
        case .sentenceCorrection(let e): try e.encode(to: encoder)
        }
    }
}
