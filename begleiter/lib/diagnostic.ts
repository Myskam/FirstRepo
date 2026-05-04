import type { StudentProfile, DiagnosticQuestion } from '@/types';
import { generateDiagnosticQuestions } from './api';
import { transitionTopic, markTopicActive } from './profile';

export async function fetchDiagnosticQuestions(
  profile: StudentProfile,
): Promise<DiagnosticQuestion[]> {
  const coveredTopics = Object.entries(profile.topics)
    .filter(([, s]) => s.status === 'introduced' || s.status === 'active')
    .map(([id]) => id);

  if (coveredTopics.length === 0) {
    // Beginner — use default A1 starters
    return generateDiagnosticQuestions(['a1_greetings', 'a1_sein', 'a1_haben'], profile.level, 6);
  }

  return generateDiagnosticQuestions(coveredTopics, profile.level, Math.min(10, coveredTopics.length + 2));
}

// Score answers and update the profile
export function scoreDiagnostic(
  profile: StudentProfile,
  questions: DiagnosticQuestion[],
  answers: Record<string, string>,
): StudentProfile {
  let updated = structuredClone(profile);

  for (const q of questions) {
    const userAnswer = answers[q.id]?.trim().toLowerCase() ?? '';
    const correct = q.correct.trim().toLowerCase();
    const isCorrect = userAnswer === correct || userAnswer.includes(correct);

    // Mark the topic as active regardless of correctness (they've been exposed to it)
    updated = markTopicActive(updated, q.topic);
    // Then apply the correctness signal
    updated = transitionTopic(updated, q.topic, isCorrect);
  }

  updated.onboardingComplete = true;
  return updated;
}
