'use client';
import { useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { useSessionStore } from '@/stores/sessionStore';
import { useProfileStore } from '@/stores/profileStore';
import { QuizCard } from '@/components/quiz/QuizCard';
import { ProgressBar } from '@/components/ui/ProgressBar';
import { buildSummary } from '@/lib/session';
import { transitionTopic } from '@/lib/profile';
import type { Answer } from '@/types';

export default function ActiveSessionPage() {
  const router = useRouter();
  const { exercises, currentIndex, answers, startedAt, next, recordAnswer, setSummary, setLoading } = useSessionStore();
  const { profile, update: updateProfile } = useProfileStore();
  const finishingRef = useRef(false);

  useEffect(() => {
    if (!startedAt || exercises.length === 0) router.push('/session');
  }, [startedAt, exercises, router]);

  async function handleAnswer(answer: Answer) {
    recordAnswer(answer);

    // Update profile live
    if (profile) {
      updateProfile(p => transitionTopic(p, answer.topic, answer.correct));
    }

    // Small delay so user sees the feedback
    await new Promise(r => setTimeout(r, 1100));

    if (currentIndex + 1 >= exercises.length) {
      if (finishingRef.current) return;
      finishingRef.current = true;
      setLoading(true);
      try {
        const allAnswers = [...answers, answer];
        const summary = profile ? await buildSummary(profile, allAnswers) : null;
        if (summary) setSummary(summary);
      } finally {
        setLoading(false);
        router.push('/session/summary');
      }
    } else {
      next();
    }
  }

  const exercise = exercises[currentIndex];
  if (!exercise) return null;

  const total = exercises.length;

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center gap-3">
        <button className="text-slate-400 hover:text-slate-600 font-bold" onClick={() => router.push('/')}>✕</button>
        <ProgressBar value={currentIndex + 1} max={total} className="flex-1" label={`Exercise ${currentIndex + 1} of ${total}`} />
        <span className="text-sm font-bold text-slate-400 whitespace-nowrap">{currentIndex + 1} / {total}</span>
      </div>

      <QuizCard exercise={exercise} exerciseIndex={currentIndex} onAnswer={handleAnswer} />
    </div>
  );
}
