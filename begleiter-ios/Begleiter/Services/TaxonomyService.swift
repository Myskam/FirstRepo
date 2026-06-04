import Foundation

final class TaxonomyService {
    static let shared = TaxonomyService()

    private let topics: [TaxonomyTopic]

    private init() {
        guard let url = Bundle.main.url(forResource: "taxonomy", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            topics = []
            return
        }
        struct Wrapper: Decodable { let topics: [TaxonomyTopic] }
        if let wrapper = try? JSONDecoder().decode(Wrapper.self, from: data) {
            topics = wrapper.topics
        } else if let flat = try? JSONDecoder().decode([TaxonomyTopic].self, from: data) {
            topics = flat
        } else {
            topics = []
        }
    }

    func allTopics() -> [TaxonomyTopic] { topics }

    func topics(for level: CefrLevel) -> [TaxonomyTopic] {
        topics.filter { $0.level == level }
    }

    func topic(id: String) -> TaxonomyTopic? {
        topics.first { $0.id == id }
    }

    func topicsUpTo(level: CefrLevel) -> [TaxonomyTopic] {
        topics.filter { $0.level <= level }
    }

    func displayName(for id: String) -> String {
        topic(id: id)?.displayName ?? id
    }

    func groupedByLevel(_ subset: [TaxonomyTopic]) -> [(CefrLevel, [TaxonomyTopic])] {
        var dict: [CefrLevel: [TaxonomyTopic]] = [:]
        for topic in subset { dict[topic.level, default: []].append(topic) }
        return CefrLevel.allCases.compactMap { level in
            guard let group = dict[level], !group.isEmpty else { return nil }
            return (level, group)
        }
    }

    func prerequisitesMet(for topic: TaxonomyTopic, in profile: StudentProfile) -> Bool {
        topic.prerequisites.allSatisfy { prereqId in
            profile.topics[prereqId]?.status == .mastered || profile.topics[prereqId]?.status == .active
        }
    }
}
