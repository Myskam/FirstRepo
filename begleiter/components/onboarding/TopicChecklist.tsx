'use client';
import { topicsForChecklist } from '@/lib/taxonomy';
import type { CefrLevel } from '@/types';

const LEVEL_LABELS: Record<CefrLevel, string> = {
  'A1':  'A1 — Beginner',
  'A2':  'A2 — Elementary',
  'B1':  'B1 — Intermediate',
  'B2+': 'B2+ — Upper Intermediate',
};

interface Props {
  checked: Set<string>;
  maxLevel: CefrLevel;
  onChange: (checked: Set<string>) => void;
}

export function TopicChecklist({ checked, maxLevel, onChange }: Props) {
  const grouped = topicsForChecklist();
  const levelOrder: CefrLevel[] = ['A1', 'A2', 'B1'];
  const levelRank: Record<string, number> = { A1: 0, A2: 1, B1: 2, 'B2+': 3 };
  const maxRank = levelRank[maxLevel] ?? 3;

  function toggle(id: string) {
    const next = new Set(checked);
    next.has(id) ? next.delete(id) : next.add(id);
    onChange(next);
  }

  function toggleAll(ids: string[]) {
    const next = new Set(checked);
    const allChecked = ids.every(id => next.has(id));
    ids.forEach(id => allChecked ? next.delete(id) : next.add(id));
    onChange(next);
  }

  return (
    <div className="flex flex-col gap-6">
      {levelOrder.filter(lvl => levelRank[lvl] <= maxRank).map(level => {
        const topics = grouped[level];
        if (!topics.length) return null;
        const ids = topics.map(t => t.id);
        const allChecked = ids.every(id => checked.has(id));
        return (
          <div key={level}>
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-bold text-slate-700">{LEVEL_LABELS[level]}</h3>
              <button
                className="text-xs font-bold text-emerald-600 hover:underline"
                onClick={() => toggleAll(ids)}
              >
                {allChecked ? 'Uncheck all' : 'Check all'}
              </button>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
              {topics.map(t => (
                <label
                  key={t.id}
                  className="flex items-center gap-3 p-3 rounded-xl border-2 border-slate-200 cursor-pointer hover:border-emerald-300 transition-colors has-[:checked]:border-emerald-500 has-[:checked]:bg-emerald-50"
                >
                  <input
                    type="checkbox"
                    className="w-4 h-4 accent-emerald-500"
                    checked={checked.has(t.id)}
                    onChange={() => toggle(t.id)}
                  />
                  <span className="text-sm font-semibold text-slate-700">{t.displayName}</span>
                </label>
              ))}
            </div>
          </div>
        );
      })}
    </div>
  );
}
