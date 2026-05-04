'use client';
import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useProfileStore } from '@/stores/profileStore';
import { useSessionStore } from '@/stores/sessionStore';
import { buildSession } from '@/lib/session';
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';
import { getActivePracticeTopics } from '@/lib/profile';
import { getTopic } from '@/lib/taxonomy';

export default function SessionStartPage() {
  const router = useRouter();
  const { profile, update: updateProfile, addNewTopics } = useProfileStore();
  const { startSession, setLoading, setError, isLoading, error } = useSessionStore();

  useEffect(() => {
    if (!profile) router.push('/');
  }, [profile, router]);

  async function start(addedTopics?: string[]) {
    if (!profile) return;
    setLoading(true);
    setError(null);
    try {
      let p = profile;
      if (addedTopics?.length) {
        addNewTopics(addedTopics);
        // Force a re-read so buildSession uses updated profile
        const { loadProfile } = await import('@/lib/profile');
        p = loadProfile() ?? profile;
      }
      const exercises = await buildSession(p);
      const sessionId = crypto.randomUUID();
      startSession(exercises);
      router.push(`/session/${sessionId}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not start session');
    } finally {
      setLoading(false);
    }
  }

  if (!profile) return null;

  const activeTopics = getActivePracticeTopics(profile).slice(0, 4);

  return (
    <div className="flex flex-col gap-6">
      <h1 className="text-2xl font-black">Ready to practise?</h1>

      {activeTopics.length > 0 && (
        <Card className="p-4">
          <p className="text-sm font-bold text-slate-500 mb-2">Today we'll focus on:</p>
          <div className="flex flex-wrap gap-2">
            {activeTopics.map(t => (
              <span key={t.id} className="text-sm font-semibold bg-amber-50 border border-amber-200 text-amber-800 rounded-lg px-2.5 py-1">
                {getTopic(t.id)?.displayName ?? t.id}
              </span>
            ))}
          </div>
        </Card>
      )}

      {error && <p className="text-red-600 text-sm font-semibold">{error}</p>}

      <div className="flex flex-col gap-3">
        <Button size="lg" onClick={() => start()} disabled={isLoading}>
          {isLoading ? 'Building session…' : 'Start Practising →'}
        </Button>
        <Button variant="secondary" onClick={() => router.push('/onboarding/coverage')} disabled={isLoading}>
          I covered something new in class
        </Button>
        <Button variant="ghost" size="sm" onClick={() => router.push('/')}>
          ← Back to dashboard
        </Button>
      </div>
    </div>
  );
}
