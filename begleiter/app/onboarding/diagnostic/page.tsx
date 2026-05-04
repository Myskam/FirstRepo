'use client';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useProfileStore } from '@/stores/profileStore';
import { initProfile } from '@/lib/profile';
import { fetchDiagnosticQuestions, scoreDiagnostic } from '@/lib/diagnostic';
import { QuizCard } from '@/components/quiz/QuizCard';
import { ProgressBar } from '@/components/ui/ProgressBar';
import { Button } from '@/components/ui/Button';
import type { CefrLevel, StudyContext, DiagnosticQuestion, Answer } from '@/types';

export default function DiagnosticStep() {
  const router = useRouter();
  const { set: setProfile } = useProfileStore();

  const [questions, setQuestions]   = useState<DiagnosticQuestion[]>([]);
  const [answers,   setAnswers]     = useState<Record<string, string>>({});
  const [idx,       setIdx]         = useState(0);
  const [loading,   setLoading]     = useState(true);
  const [error,     setError]       = useState<string | null>(null);
  const [done,      setDone]        = useState(false);

  useEffect(() => {
    const level    = (sessionStorage.getItem('bg_ob_level')   as CefrLevel)   ?? 'A1';
    const context  = (sessionStorage.getItem('bg_ob_context') as StudyContext) ?? 'app_only';
    const covered  = JSON.parse(sessionStorage.getItem('bg_ob_covered') ?? '[]') as string[];

    const draft = initProfile({ level, studyContext: context, textbook: null, coveredTopicIds: covered });

    fetchDiagnosticQuestions(draft)
      .then(qs => { setQuestions(qs); setLoading(false); })
      .catch(err => {
        setError(err.message);
        setLoading(false);
      });
  }, []);

  function handleAnswer(answer: Answer) {
    const q = questions[idx];
    if (!q) return;
    setAnswers(prev => ({ ...prev, [q.id]: answer.correct ? q.correct : '' }));
    setTimeout(() => {
      if (idx + 1 >= questions.length) {
        setDone(true);
      } else {
        setIdx(i => i + 1);
      }
    }, 900);
  }

  function finish() {
    const level   = (sessionStorage.getItem('bg_ob_level')   as CefrLevel)   ?? 'A1';
    const context = (sessionStorage.getItem('bg_ob_context') as StudyContext) ?? 'app_only';
    const covered = JSON.parse(sessionStorage.getItem('bg_ob_covered') ?? '[]') as string[];

    let profile = initProfile({ level, studyContext: context, textbook: null, coveredTopicIds: covered });
    profile = scoreDiagnostic(profile, questions, answers);

    setProfile(profile);
    sessionStorage.removeItem('bg_ob_level');
    sessionStorage.removeItem('bg_ob_context');
    sessionStorage.removeItem('bg_ob_covered');
    router.push('/');
  }

  if (loading) {
    return (
      <div className="flex flex-col items-center gap-4 py-16 text-center">
        <div className="w-8 h-8 border-4 border-emerald-500 border-t-transparent rounded-full animate-spin" />
        <p className="text-slate-500">Preparing your diagnostic…</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center gap-4 py-16 text-center">
        <p className="text-red-600 font-bold">Could not load diagnostic</p>
        <p className="text-slate-500 text-sm">{error}</p>
        <Button variant="secondary" onClick={() => router.back()}>← Back</Button>
        <Button onClick={() => {
          // Skip diagnostic and use coverage check only
          const level   = (sessionStorage.getItem('bg_ob_level')   as CefrLevel)   ?? 'A1';
          const context = (sessionStorage.getItem('bg_ob_context') as StudyContext) ?? 'app_only';
          const covered = JSON.parse(sessionStorage.getItem('bg_ob_covered') ?? '[]') as string[];
          let profile = initProfile({ level, studyContext: context, textbook: null, coveredTopicIds: covered });
          profile.onboardingComplete = true;
          setProfile(profile);
          router.push('/');
        }}>
          Skip diagnostic →
        </Button>
      </div>
    );
  }

  if (done) {
    const correct = Object.values(answers).filter(Boolean).length;
    return (
      <div className="flex flex-col items-center gap-6 py-8 text-center">
        <div className="text-5xl">🎯</div>
        <h2 className="text-2xl font-black">Diagnostic complete</h2>
        <p className="text-slate-500">
          {correct} / {questions.length} correct.{' '}
          {correct >= questions.length * 0.7
            ? "Good knowledge base — we'll build from here."
            : "We've identified gaps to focus on first."}
        </p>
        <Button size="lg" onClick={finish}>See your personalised dashboard →</Button>
      </div>
    );
  }

  const current = questions[idx];
  if (!current) return null;

  // Adapt DiagnosticQuestion to Exercise shape for QuizCard
  const asExercise = current.type === 'multiple_choice'
    ? { type: 'multiple_choice' as const, id: current.id, topic: current.topic, question: current.question, options: current.options ?? [], correct: current.correct, hint: null, explanation: current.explanation }
    : { type: 'fill_blank' as const, id: current.id, topic: current.topic, sentence: current.question, blank: current.correct, correct: current.correct, hint: null, explanation: current.explanation };

  return (
    <div className="flex flex-col gap-6">
      <div>
        <p className="text-xs font-bold uppercase tracking-widest text-emerald-600 mb-2">Step 4 of 4 — Diagnostic</p>
        <ProgressBar value={idx + 1} max={questions.length} label={`Question ${idx + 1} of ${questions.length}`} />
        <p className="text-sm text-slate-500 mt-2">Question {idx + 1} of {questions.length}</p>
      </div>
      <QuizCard exercise={asExercise} exerciseIndex={idx} onAnswer={handleAnswer} />
    </div>
  );
}
