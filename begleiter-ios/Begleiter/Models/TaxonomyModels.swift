import Foundation

enum CefrLevel: String, Codable, CaseIterable, Comparable {
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2plus = "B2+"

    static func < (lhs: CefrLevel, rhs: CefrLevel) -> Bool {
        let order = allCases
        return (order.firstIndex(of: lhs) ?? 0) < (order.firstIndex(of: rhs) ?? 0)
    }
}

enum TopicCategory: String, Codable {
    case grammar = "grammar"
    case vocabulary = "vocabulary"
}

struct TaxonomyTopic: Codable, Identifiable, Hashable {
    let id: String
    let level: CefrLevel
    let category: TopicCategory
    let displayName: String
    let prerequisites: [String]
}
