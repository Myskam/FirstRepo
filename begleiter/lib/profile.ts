import type { StudentProfile, TopicState, TopicStatus, CefrLevel, StudyContext, SessionResult } from '@/types';
import { getAllTopics, getTopic } from './taxonomy';

const STORAGE_KEY = 'bg_profile';

function emptyTopicState(): TopicState {
  return {
    status: 'not_covered',
    correctStreak: 0,
    totalAttempts: 0,
    correctAttempts: 0,
    lastPracticed: null,
    sessionHistory: [],
  };
}

export function initProfile(opts: {
  level: CefrLevel;
  studyContext: StudyContext;
  textbook: string | null;
  coveredTopicIds: string[];
}): StudentProfile {
  const allTopics = getAllTopics();
  const topics: Record<string, TopicState> = {};
  for (const t of allTopics) {
    topics[t.id] = emptyTopicState();
  }
  for (const id of opts.coveredTopicIds) {
    if (topics[id]) topics[id].status = 'introduced';
  }
  return {
    id: crypto.randomUUID(),
    createdAt: new Date().toISOString(),
    level: opts.level,
    studyContext: opts.studyContext,
    textbook: opts.textbook,
    onboardingComplete: false,
    topics,
  };
}

export function loadProfile(): StudentProfile | null {
  if (typeof window === 'undefined') return null;
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as StudentProfile) : null;
  } catch { return null; }
}

export function saveProfile(profile: StudentProfile): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(STORAGE_KEY, JSON.stringify(profile));
}

export function clearProfile(): void {
  if (typeof window === 'undefined') return;
  localStorage.removeItem(STORAGE_KEY);
}

// Transition a topic state after a single answer
export function transitionTopic(
  profile: StudentProfile,
  topicId: string,
  correct: boolean,
): StudentProfile {
  const next = structuredClone(profile);
  const state = next.topics[topicId] ?? emptyTopicState();

  state.totalAttempts += 1;
  if (correct) {
    state.correctAttempts += 1;
    state.correctStreak += 1;
    if (state.correctStreak >= 3 && state.status !== 'mastered') {
      state.status = 'mastered';
    } else if (state.status === 'introduced' || state.status === 'not_covered') {
      state.status = 'active';
    } else if (state.status === 'struggling') {
      state.status = 'active';
    }
  } else {
    state.correctStreak = 0;
    const errorRate = 1 - state.correctAttempts / state.totalAttempts;
    if (errorRate > 0.4 && state.totalAttempts >= 3) {
      state.status = 'struggling';
    } else if (state.status === 'not_covered' || state.status === 'introduced') {
      state.status = 'active';
    }
  }
  state.lastPracticed = new Date().toISOString();
  next.topics[topicId] = state;
  return next;
}

// Apply a full session result to the profile
export function applySessionResult(
  profile: StudentProfile,
  sessionResult: SessionResult,
): StudentProfile {
  const next = structuredClone(profile);
  for (const topicId of sessionResult.errorTopics) {
    if (next.topics[topicId]) {
      next.topics[topicId].correctStreak = 0;
      if (next.topics[topicId].status !== 'mastered') {
        next.topics[topicId].status = 'struggling';
      }
    }
  }
  // Add to session history (keep last 5)
  const affectedTopics = Array.from(new Set([
    ...sessionResult.errorTopics,
    ...Object.keys(next.topics).filter(id =>
      next.topics[id].lastPracticed &&
      new Date(next.topics[id].lastPracticed!).toDateString() === new Date().toDateString()
    ),
  ]));
  for (const topicId of affectedTopics) {
    const state = next.topics[topicId];
    if (!state) continue;
    state.sessionHistory = [
      { ...sessionResult },
      ...state.sessionHistory,
    ].slice(0, 5);
  }
  return next;
}

// Returns active/struggling topics sorted by oldest-last-practiced first
export function getActivePracticeTopics(profile: StudentProfile) {
  return Object.entries(profile.topics)
    .filter(([, s]) => s.status === 'active' || s.status === 'struggling')
    .sort(([, a], [, b]) => {
      // Struggling first, then oldest last-practiced
      if (a.status === 'struggling' && b.status !== 'struggling') return -1;
      if (b.status === 'struggling' && a.status !== 'struggling') return 1;
      const aTime = a.lastPracticed ? new Date(a.lastPracticed).getTime() : 0;
      const bTime = b.lastPracticed ? new Date(b.lastPracticed).getTime() : 0;
      return aTime - bTime;
    })
    .map(([id, state]) => ({ id, topic: getTopic(id), state }));
}

export function markTopicsIntroduced(profile: StudentProfile, topicIds: string[]): StudentProfile {
  const next = structuredClone(profile);
  for (const id of topicIds) {
    if (next.topics[id] && next.topics[id].status === 'not_covered') {
      next.topics[id].status = 'introduced';
    }
  }
  return next;
}

export function markTopicActive(profile: StudentProfile, topicId: string): StudentProfile {
  const next = structuredClone(profile);
  if (next.topics[topicId]) next.topics[topicId].status = 'active';
  return next;
}
