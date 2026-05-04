'use client';
import { useState } from 'react';
import { cn } from '@/lib/utils';
import type { MultipleChoiceExercise } from '@/types';

interface Props {
  exercise: MultipleChoiceExercise;
  onAnswer: (correct: boolean, chosen: string) => void;
}

export function MultipleChoice({ exercise, onAnswer }: Props) {
  const [chosen, setChosen] = useState<string | null>(null);
  const answered = chosen !== null;

  function pick(opt: string) {
    if (answered) return;
    setChosen(opt);
    onAnswer(opt === exercise.correct, opt);
  }

  return (
    <div className="flex flex-col gap-4">
      <p className="text-xs font-bold uppercase tracking-widest text-slate-400">Choose the correct answer</p>
      <p className="text-2xl font-black text-slate-800 leading-snug">{exercise.question}</p>
      {exercise.hint && !answered && (
        <p className="text-sm text-slate-500 italic">{exercise.hint}</p>
      )}
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 mt-2">
        {exercise.options.map(opt => {
          let cls = 'p-4 rounded-xl border-2 font-bold text-left transition-all cursor-pointer';
          if (!answered) {
            cls = cn(cls, 'border-slate-200 hover:border-emerald-400 hover:bg-emerald-50');
          } else if (opt === exercise.correct) {
            cls = cn(cls, 'border-emerald-500 bg-emerald-50 text-emerald-800');
          } else if (opt === chosen) {
            cls = cn(cls, 'border-red-400 bg-red-50 text-red-700');
          } else {
            cls = cn(cls, 'border-slate-200 opacity-50');
          }
          return (
            <button key={opt} className={cls} onClick={() => pick(opt)} disabled={answered} aria-pressed={chosen === opt}>
              {opt}
            </button>
          );
        })}
      </div>
      {answered && (
        <p className="text-sm text-slate-600 mt-2 p-3 bg-slate-50 rounded-xl border border-slate-200">
          {exercise.explanation}
        </p>
      )}
    </div>
  );
}
