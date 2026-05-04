'use client';
import { useState, useMemo } from 'react';
import { cn } from '@/lib/utils';
import type { MatchPairsExercise } from '@/types';

interface Props {
  exercise: MatchPairsExercise;
  onAnswer: (correct: boolean) => void;
}

function shuffle<T>(arr: T[]): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

export function MatchPairs({ exercise, onAnswer }: Props) {
  const leftItems  = useMemo(() => shuffle(exercise.pairs.map((p, i) => ({ ...p, id: i }))), []);
  const rightItems = useMemo(() => shuffle(exercise.pairs.map((p, i) => ({ ...p, id: i }))), []);

  const [selectedLeft, setSelectedLeft]   = useState<number | null>(null);
  const [matched,      setMatched]        = useState<Set<number>>(new Set());
  const [wrongPair,    setWrongPair]      = useState<Set<number>>(new Set());
  const [done,         setDone]           = useState(false);

  function tapLeft(id: number) {
    if (matched.has(id) || done) return;
    setSelectedLeft(prev => prev === id ? null : id);
  }

  function tapRight(id: number) {
    if (matched.has(id) || done) return;
    if (selectedLeft === null) return;

    if (selectedLeft === id) {
      const nextMatched = new Set([...matched, id]);
      setMatched(nextMatched);
      setSelectedLeft(null);
      if (nextMatched.size === exercise.pairs.length) {
        setDone(true);
        onAnswer(true);
      }
    } else {
      setWrongPair(new Set([selectedLeft, id]));
      setTimeout(() => setWrongPair(new Set()), 500);
      setSelectedLeft(null);
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <p className="text-xs font-bold uppercase tracking-widest text-slate-400">Match the pairs</p>
      <p className="text-sm text-slate-500">Tap a word on the left, then its match on the right</p>
      <div className="grid grid-cols-2 gap-3 mt-2">
        <div className="flex flex-col gap-2">
          {leftItems.map(p => (
            <button
              key={p.id}
              aria-pressed={selectedLeft === p.id}
              onClick={() => tapLeft(p.id)}
              disabled={matched.has(p.id)}
              className={cn(
                'p-3 rounded-xl border-2 text-sm font-bold text-left transition-all',
                matched.has(p.id)    && 'border-emerald-500 bg-emerald-50 text-emerald-700 cursor-default',
                wrongPair.has(p.id)  && 'border-red-400 bg-red-50',
                selectedLeft === p.id && !matched.has(p.id) && 'border-blue-400 bg-blue-50 text-blue-700',
                !matched.has(p.id) && selectedLeft !== p.id && !wrongPair.has(p.id) && 'border-slate-200 hover:border-blue-300',
              )}
            >
              {p.left}
            </button>
          ))}
        </div>
        <div className="flex flex-col gap-2">
          {rightItems.map(p => (
            <button
              key={p.id}
              onClick={() => tapRight(p.id)}
              disabled={matched.has(p.id)}
              className={cn(
                'p-3 rounded-xl border-2 text-sm font-bold text-left transition-all',
                matched.has(p.id)   && 'border-emerald-500 bg-emerald-50 text-emerald-700 cursor-default',
                wrongPair.has(p.id) && 'border-red-400 bg-red-50',
                !matched.has(p.id) && !wrongPair.has(p.id) && 'border-slate-200 hover:border-blue-300',
              )}
            >
              {p.right}
            </button>
          ))}
        </div>
      </div>
      {done && (
        <p className="text-sm p-3 bg-emerald-50 border border-emerald-200 rounded-xl text-emerald-800">
          {exercise.explanation}
        </p>
      )}
    </div>
  );
}
