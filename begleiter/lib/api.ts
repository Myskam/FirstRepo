import type { Exercise, DiagnosticQuestion, SessionSummary, StudentProfile } from '@/types';

const CLAUDE_URL = 'https://api.anthropic.com/v1/messages';

function getApiKey(): string {
  if (typeof window === 'undefined') return '';
  return localStorage.getItem('bg_apiKey') ?? '';
}

interface ClaudeMessage { role: 'user' | 'assistant'; content: string; }

async function callClaude(opts: {
  system: string;
  messages: ClaudeMessage[];
  model?: string;
  max_tokens?: number;
}): Promise<string> {
  const apiKey = getApiKey();
  if (!apiKey) throw new Error('No API key configured. Go to /setup to add your Claude API key.');

  // TO SWITCH TO SERVER-SIDE PROXY:
  //   1. Replace the fetch below with:
  //        const res = await fetch('/api/generate', {
  //          method: 'POST',
  //          headers: { 'Content-Type': 'application/json' },
  //          body: JSON.stringify({ system: opts.system, messages: opts.messages, model: opts.model, max_tokens: opts.max_tokens }),
  //        });
  //   2. Create app/api/generate/route.ts that reads process.env.ANTHROPIC_API_KEY
  //   3. Remove the 'anthropic-dangerous-direct-browser-access' header

  const res = await fetch(CLAUDE_URL, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'anthropic-dangerous-direct-browser-access': 'true',
    },
    body: JSON.stringify({
      model: opts.model ?? 'claude-haiku-4-5-20251001',
      max_tokens: opts.max_tokens ?? 1500,
      system: opts.system,
      messages: opts.messages,
    }),
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({})) as { error?: { message?: string } };
    throw new Error(err.error?.message ?? `API error ${res.status}`);
  }

  const data = await res.json() as { content: { type: string; text: string }[] };
  const text = data.content
    .filter(b => b.type === 'text')
    .map(b => b.text)
    .join('');

  return text;
}

function parseJson<T>(raw: string): T {
  const clean = raw.replace(/```json\s*/g, '').replace(/```\s*/g, '').trim();
  try {
    return JSON.parse(clean) as T;
  } catch {
    // Try extracting JSON object/array
    const match = clean.match(/(\{[\s\S]*\}|\[[\s\S]*\])/);
    if (match) return JSON.parse(match[0]) as T;
    throw new Error('Could not parse AI response as JSON');
  }
}

// ── Public API ────────────────────────────────────────────────────────────────

export async function generateDiagnosticQuestions(
  coveredTopics: string[],
  level: string,
  count = 8,
): Promise<DiagnosticQuestion[]> {
  const { DIAGNOSTIC_PROMPT } = await import('./prompts');
  const system = DIAGNOSTIC_PROMPT
    .replace('{level}', level)
    .replace('{coveredTopics}', coveredTopics.join(', '))
    .replace('{count}', String(count));

  const raw = await callClaude({ system, messages: [{ role: 'user', content: 'Generate the diagnostic questions now.' }] });
  const data = parseJson<{ questions: DiagnosticQuestion[] }>(raw);
  return data.questions ?? [];
}

export async function generateSessionExercises(
  profile: StudentProfile,
  count = 12,
): Promise<Exercise[]> {
  const { EXERCISE_GENERATION_PROMPT } = await import('./prompts');
  const { getActivePracticeTopics } = await import('./profile');
  const activeTopics = getActivePracticeTopics(profile).slice(0, 5);
  const struggling = Object.entries(profile.topics)
    .filter(([, s]) => s.status === 'struggling')
    .map(([id]) => id);
  const mastered = Object.entries(profile.topics)
    .filter(([, s]) => s.status === 'mastered')
    .map(([id]) => id);

  const system = EXERCISE_GENERATION_PROMPT
    .replace('{level}', profile.level)
    .replace('{mastered}', mastered.slice(-10).join(', ') || 'none yet')
    .replace('{activePractice}', activeTopics.map(t => t.id).join(', ') || 'basic greetings')
    .replace('{weakPoints}', struggling.join(', ') || 'none identified')
    .replace('{recentErrors}', 'see active practice topics')
    .replace('{count}', String(count));

  const raw = await callClaude({ system, messages: [{ role: 'user', content: 'Generate the exercises now.' }] });
  const data = parseJson<{ exercises: Exercise[] }>(raw);
  // Ensure each exercise has an id
  return (data.exercises ?? []).map((ex, i) => ({ ...ex, id: ex.id || `ex_${i}` }));
}

export async function generateSessionSummary(
  profile: StudentProfile,
  answers: { exerciseId: string; topic: string; correct: boolean; timeSpent: number }[],
): Promise<SessionSummary> {
  const { PROFILE_UPDATE_PROMPT } = await import('./prompts');
  const system = PROFILE_UPDATE_PROMPT
    .replace('{currentProfile}', JSON.stringify({ level: profile.level, topics: Object.fromEntries(
      Object.entries(profile.topics).filter(([, s]) => s.status !== 'not_covered').map(([id, s]) => [id, { status: s.status, correctStreak: s.correctStreak }])
    )}))
    .replace('{sessionResults}', JSON.stringify(answers));

  const raw = await callClaude({
    system,
    messages: [{ role: 'user', content: 'Analyze performance and return the updated profile.' }],
    model: 'claude-sonnet-4-6',
    max_tokens: 800,
  });
  const data = parseJson<{ sessionSummary: SessionSummary }>(raw);
  return data.sessionSummary ?? { strongTopics: [], weakTopics: [], recommendation: 'Keep practising!' };
}
