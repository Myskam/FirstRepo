import { openDB, type IDBPDatabase } from 'idb';
import type { Exercise } from '@/types';

const DB_NAME = 'begleiter';
const STORE = 'exercises';
const DB_VERSION = 1;

async function getDB(): Promise<IDBPDatabase> {
  return openDB(DB_NAME, DB_VERSION, {
    upgrade(db) {
      if (!db.objectStoreNames.contains(STORE)) {
        db.createObjectStore(STORE);
      }
    },
  });
}

export async function cacheExercises(topicId: string, exercises: Exercise[]): Promise<void> {
  try {
    const db = await getDB();
    await db.put(STORE, { exercises, cachedAt: Date.now() }, topicId);
  } catch { /* silent — caching is best-effort */ }
}

export async function getCachedExercises(topicId: string): Promise<Exercise[] | null> {
  try {
    const db = await getDB();
    const record = await db.get(STORE, topicId) as { exercises: Exercise[]; cachedAt: number } | undefined;
    if (!record) return null;
    // Expire cache after 7 days
    if (Date.now() - record.cachedAt > 7 * 24 * 60 * 60 * 1000) return null;
    return record.exercises;
  } catch { return null; }
}

export async function getOfflineExercises(topicId: string): Promise<Exercise[]> {
  // Tier 1: IndexedDB cache
  const cached = await getCachedExercises(topicId);
  if (cached?.length) return cached;

  // Tier 2: static fallback JSON
  try {
    const mod = await import(`@/content/fallback/${topicId}.json`).catch(() => null);
    if (mod?.default?.exercises?.length) return mod.default.exercises as Exercise[];
  } catch { /* no fallback file */ }

  // Tier 3: minimal placeholder
  return [{
    id: 'offline_placeholder',
    type: 'multiple_choice',
    topic: topicId,
    question: 'No offline content available for this topic yet. Connect to the internet to generate exercises.',
    options: ['OK'],
    correct: 'OK',
    hint: null,
    explanation: 'Connect to the internet to get AI-generated exercises for this topic.',
  }];
}
