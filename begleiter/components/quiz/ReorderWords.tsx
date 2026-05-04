'use client';
import { useState, useMemo } from 'react';
import { cn } from '@/lib/utils';
import type { ReorderWordsExercise } from '@/types';

interface Props {
  exercise: ReorderWordsExercise;
  onAnswer: (correct: boolean, given: string) => void;
}

function shuffle<T>(arr: T[]): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

export function ReorderWords({ exercise, onAnswer }: Props) {
  const pool = useMemo(() => shuffle(exercise.words.map((w, i) => ({ w, id: i }))), []);
  const [selected, setSelected] = useState<{ w: string; id: number }[]>([]);
  const [submitted, setSubmitted] = useState(false);
  const [correct, setCorrect] = useState(false);

  const remaining = pool.filter(p => !selected.some(s => s.id === p.id));

  function pick(item: { w: string; id: number }) {
    if (submitted) return;
    setSelected(prev => [...prev, item]);
  }

  function remove(item: { w: string; id: number }) {
    if (submitted) return;
    setSelected(prev => prev.filter(s => s.id !== item.id));
  }

  function submit() {
    if (submitted || selected.length === 0) return;
    const answer = selected.map(s => s.w).join(' ');
    const isCorrect = answer.toLowerCase() === exercise.correct.toLowerCase();
    setCorrect(isCorrect);
    setSubmitted(true);
    onAnswer(isCorrect, answer);
  }

  return (
    <div className="flex flex-col gap-4">
      <p className="text-xs font-bold uppercase tracking-widest text-slate-400">Put the words in the right order</p>
      {exercise.question && <p className="text-xl font-black text-slate-800">{exercise.question}</p>}
      {exercise.hint && !submitted && <p className="text-sm text-slate-500 italic">{exercise.hint}</p>}

      {/* Answer area */}
      <div className={cn(
        'min-h-14 p-3 rounded-xl border-2 flex flex-wrap gap-2',
        !submitted && 'border-slate-200 bg-slate-50',
        submitted && correct && 'border-emerald-500 bg-emerald-50',
        submitted && !correct && 'border-red-400 bg-red-50',
      )}>
        {selected.length === 0 && <span className="text-slate-400 text-sm self-center">Tap words below to build the sentence</span>}
        {selected.map(item => (
          <button
            key={item.id}
            onClick={() => remove(item)}
            disabled={submitted}
            className="px-3 py-1.5 rounded-lg bg-white border-2 border-emerald-400 text-sm font-bold text-emerald-700 hover:bg-red-50 hover:border-red-300 hover:text-red-600 transition-colors"
          >
            {item.w}
          </button>
        ))}
      </div>

      {/* Word bank */}
      {!submitted && (
        <div className="flex flex-wrap gap-2">
          {remaining.map(item => (
            <button
              key={item.id}
              onClick={() => pick(item)}
              className="px-3 py-1.5 rounded-lg bg-white border-2 border-slate-200 text-sm font-bold hover:border-blue-400 hover:bg-blue-50 transition-colors"
            >
              {item.w}
            </button>
          ))}
        </div>
      )}

      {!submitted && (
        <button
          className="self-start rounded-xl bg-emerald-500 text-white font-bold px-6 py-3 disabled:opacity-40"
          onClick={submit}
          disabled={selected.length === 0}
        >
          Check
        </button>
      )}

      {submitted && (
        <div className={cn('text-sm p-3 rounded-xl border', correct ? 'bg-emerald-50 border-emerald-200 text-emerald-800' : 'bg-red-50 border-red-200 text-red-800')}>
          {!correct && <p className="font-bold mb-1">Correct order: {exercise.correct}</p>}
          <p>{exercise.explanation}</p>
        </div>
      )}
    </div>
  );
}
