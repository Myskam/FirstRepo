import type { StudentProfile, Exercise, Answer } from '@/types';
import { generateSessionExercises, generateSessionSummary } from './api';
import { getOfflineExercises, cacheExercises } from './offline';
import { getActivePracticeTopics } from './profile';

export async function buildSession(profile: StudentProfile): Promise<Exercise[]> {
  const activeTopics = getActivePracticeTopics(profile);

  try {
    const exercises = await generateSessionExercises(profile, 12);
    // Cache exercises by topic for offline use
    const byTopic = new Map<string, Exercise[]>();
    for (const ex of exercises) {
      const arr = byTopic.get(ex.topic) ?? [];
      arr.push(ex);
      byTopic.set(ex.topic, arr);
    }
    for (const [topicId, exs] of byTopic) {
      await cacheExercises(topicId, exs);
    }
    return exercises;
  } catch (err) {
    // Offline fallback: pull cached/static exercises for active topics
    const topicIds = activeTopics.slice(0, 3).map(t => t.id);
    if (!topicIds.length) topicIds.push('a1_greetings');
    const all: Exercise[] = [];
    for (const id of topicIds) {
      const exs = await getOfflineExercises(id);
      all.push(...exs);
    }
    return all.slice(0, 12);
  }
}

export async function buildSummary(
  profile: StudentProfile,
  answers: Answer[],
) {
  try {
    return await generateSessionSummary(profile, answers);
  } catch {
    const errorTopics = Array.from(new Set(answers.filter(a => !a.correct).map(a => a.topic)));
    const strongTopics = Array.from(new Set(answers.filter(a => a.correct).map(a => a.topic)));
    return {
      strongTopics,
      weakTopics: errorTopics,
      recommendation: errorTopics.length
        ? `Focus on ${errorTopics[0]} in your next session.`
        : 'Great session! Keep up the consistent practice.',
    };
  }
}
