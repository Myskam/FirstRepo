import taxonomyData from '@/content/taxonomy.json';
import type { TaxonomyTopic, CefrLevel } from '@/types';

const topics: TaxonomyTopic[] = taxonomyData.topics as TaxonomyTopic[];
const topicMap = new Map(topics.map(t => [t.id, t]));

export function getTopic(id: string): TaxonomyTopic | undefined {
  return topicMap.get(id);
}

export function getByLevel(level: CefrLevel): TaxonomyTopic[] {
  return topics.filter(t => t.level === level);
}

export function getAllTopics(): TaxonomyTopic[] {
  return topics;
}

export function getPrerequisites(id: string): TaxonomyTopic[] {
  return (topicMap.get(id)?.prerequisites ?? [])
    .map(pid => topicMap.get(pid))
    .filter((t): t is TaxonomyTopic => t !== undefined);
}

// Returns topics grouped by level for the onboarding checklist
export function topicsForChecklist(): Record<CefrLevel, TaxonomyTopic[]> {
  return {
    'A1':  getByLevel('A1'),
    'A2':  getByLevel('A2'),
    'B1':  getByLevel('B1'),
    'B2+': [],
  };
}

// Given a level, return all topic IDs at or below that level
export function topicsUpToLevel(level: CefrLevel): string[] {
  const order: CefrLevel[] = ['A1', 'A2', 'B1', 'B2+'];
  const cutoff = order.indexOf(level);
  return topics
    .filter(t => order.indexOf(t.level) <= cutoff)
    .map(t => t.id);
}
