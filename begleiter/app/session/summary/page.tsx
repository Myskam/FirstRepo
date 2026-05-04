'use client';
import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useSessionStore } from '@/stores/sessionStore';
import { useProfileStore } from '@/stores/profileStore';
import { applySessionResult } from '@/lib/profile';
import { getTopic } from '@/lib/taxonomy';
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';

export default function SessionSummaryPage() {
  const router = useRouter();
  const { exercises, answers, summary, reset: resetSession } = useSessionStore();
  const { profile, update: updateProfile } = useProfileStore();

  useEffect(() => {
    if (!summary && exercises.length === 0) {
      router.push('/');
      return;
    }
    // Apply aggregate session result to profile
    if (profile && answers.length > 0) {
      const errorTopics = answers.filter(a => !a.correct).map(a => a.topic);
      updateProfile(p => applySessionResult(p, {
        date: new Date().toISOString(),
        exerciseCount: exercises.length,
        correctCount: answers.filter(a => a.correct).length,
        errorTopics,
      }));
    }
  }, []);

  const correct  = answers.filter(a => a.correct).length;
  const total    = answers.length;
  const accuracy = total > 0 ? Math.round((correct / total) * 100) : 0;

  function goAgain() {
    resetSession();
    router.push('/session');
  }

  return (
    <div className="flex flex-col gap-6 py-4">
      <div className="text-center">
        <div className="text-5xl mb-3">{accuracy >= 80 ? '🎉' : accuracy >= 60 ? '👍' : '💪'}</div>
        <h1 className="text-2xl font-black">Session complete!</h1>
        <p className="text-4xl font-black text-emerald-500 mt-2">{accuracy}%</p>
        <p className="text-slate-500 text-sm">{correct} / {total} correct</p>
      </div>

      {summary && (
        <Card className="p-5">
          <p className="text-slate-700 leading-relaxed">{summary.recommendation}</p>
          {summary.strongTopics.length > 0 && (
            <div className="mt-3">
              <p className="text-xs font-bold text-emerald-600 uppercase tracking-widest mb-2">Going well</p>
              <div className="flex flex-wrap gap-1.5">
                {summary.strongTopics.map(id => (
                  <span key={id} className="text-xs font-semibold bg-emerald-50 border border-emerald-200 text-emerald-700 rounded-full px-2.5 py-1">
                    {getTopic(id)?.displayName ?? id}
                  </span>
                ))}
              </div>
            </div>
          )}
          {summary.weakTopics.length > 0 && (
            <div className="mt-3">
              <p className="text-xs font-bold text-red-500 uppercase tracking-widest mb-2">Focus on next time</p>
              <div className="flex flex-wrap gap-1.5">
                {summary.weakTopics.map(id => (
                  <span key={id} className="text-xs font-semibold bg-red-50 border border-red-200 text-red-700 rounded-full px-2.5 py-1">
                    {getTopic(id)?.displayName ?? id}
                  </span>
                ))}
              </div>
            </div>
          )}
        </Card>
      )}

      <div className="flex flex-col gap-3">
        <Button size="lg" onClick={goAgain}>Practise Again →</Button>
        <Button variant="secondary" onClick={() => { resetSession(); router.push('/'); }}>
          Back to Dashboard
        </Button>
      </div>
    </div>
  );
}
