'use client';
import { useState, useRef, useEffect } from 'react';
import { cn } from '@/lib/utils';
import type { FillBlankExercise } from '@/types';

interface Props {
  exercise: FillBlankExercise;
  onAnswer: (correct: boolean, given: string) => void;
}

function normalize(s: string) {
  return s.trim().toLowerCase().replace(/[.,!?;:'"()]/g, '');
}

export function FillBlank({ exercise, onAnswer }: Props) {
  const [value, setValue] = useState('');
  const [submitted, setSubmitted] = useState(false);
  const [correct, setCorrect] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => { inputRef.current?.focus(); }, []);

  const displaySentence = exercise.sentence.replace('___', '_____');

  function submit() {
    if (submitted || !value.trim()) return;
    const isCorrect = normalize(value) === normalize(exercise.correct);
    setCorrect(isCorrect);
    setSubmitted(true);
    onAnswer(isCorrect, value.trim());
  }

  return (
    <div className="flex flex-col gap-4">
      <p className="text-xs font-bold uppercase tracking-widest text-slate-400">Fill in the blank</p>
      <p className="text-xl font-black text-slate-800 leading-snug whitespace-pre-wrap">{displaySentence}</p>
      {exercise.hint && !submitted && (
        <p className="text-sm text-slate-500 italic">{exercise.hint}</p>
      )}
      <input
        ref={inputRef}
        aria-label={`Fill in the blank: ${exercise.sentence}`}
        className={cn(
          'w-full rounded-xl border-2 px-4 py-3 text-lg font-bold outline-none transition-colors',
          !submitted && 'border-slate-200 focus:border-emerald-400',
          submitted && correct && 'border-emerald-500 bg-emerald-50 text-emerald-800',
          submitted && !correct && 'border-red-400 bg-red-50 text-red-700',
        )}
        value={value}
        onChange={e => !submitted && setValue(e.target.value)}
        onKeyDown={e => e.key === 'Enter' && submit()}
        disabled={submitted}
        autoComplete="off"
        autoCorrect="off"
        spellCheck={false}
      />
      {!submitted && (
        <button
          className="self-start rounded-xl bg-emerald-500 text-white font-bold px-6 py-3 disabled:opacity-40 transition-opacity"
          onClick={submit}
          disabled={!value.trim()}
        >
          Check
        </button>
      )}
      {submitted && (
        <div className={cn('text-sm p-3 rounded-xl border', correct ? 'bg-emerald-50 border-emerald-200 text-emerald-800' : 'bg-red-50 border-red-200 text-red-800')}>
          {!correct && <p className="font-bold mb-1">Correct answer: {exercise.correct}</p>}
          <p>{exercise.explanation}</p>
        </div>
      )}
    </div>
  );
}
