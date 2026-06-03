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
    let sentence: String   // contains "___"
    let blank: String      // the correct fill word(s)
    let hint: String?
    let explanation: String
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

// MARK: - Discriminated union

enum Exercise: Identifiable {
    case multipleChoice(MultipleChoiceExercise)
    case fillBlank(FillBlankExercise)
    case matchPairs(MatchPairsExercise)
    case reorderWords(ReorderWordsExercise)

    var id: String {
        switch self {
        case .multipleChoice(let e): return e.id
        case .fillBlank(let e):      return e.id
        case .matchPairs(let e):     return e.id
        case .reorderWords(let e):   return e.id
        }
    }

    var topic: String {
        switch self {
        case .multipleChoice(let e): return e.topic
        case .fillBlank(let e):      return e.topic
        case .matchPairs(let e):     return e.topic
        case .reorderWords(let e):   return e.topic
        }
    }

    var explanation: String {
        switch self {
        case .multipleChoice(let e): return e.explanation
        case .fillBlank(let e):      return e.explanation
        case .matchPairs(let e):     return e.explanation
        case .reorderWords(let e):   return e.explanation
        }
    }
}

extension Exercise: Codable {
    private enum TypeKey: String, Codable {
        case multiple_choice, fill_blank, match_pairs, reorder_words
    }

    private enum CodingKeys: String, CodingKey { case type }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type_ = try container.decode(TypeKey.self, forKey: .type)
        let single = try decoder.singleValueContainer()
        switch type_ {
        case .multiple_choice: self = .multipleChoice(try single.decode(MultipleChoiceExercise.self))
        case .fill_blank:      self = .fillBlank(try single.decode(FillBlankExercise.self))
        case .match_pairs:     self = .matchPairs(try single.decode(MatchPairsExercise.self))
        case .reorder_words:   self = .reorderWords(try single.decode(ReorderWordsExercise.self))
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .multipleChoice(let e): try e.encode(to: encoder)
        case .fillBlank(let e):      try e.encode(to: encoder)
        case .matchPairs(let e):     try e.encode(to: encoder)
        case .reorderWords(let e):   try e.encode(to: encoder)
        }
    }
}
