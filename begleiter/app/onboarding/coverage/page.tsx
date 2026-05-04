'use client';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { TopicChecklist } from '@/components/onboarding/TopicChecklist';
import { Button } from '@/components/ui/Button';
import type { CefrLevel } from '@/types';

export default function CoverageStep() {
  const router = useRouter();
  const [checked, setChecked] = useState<Set<string>>(new Set());
  const [level, setLevel] = useState<CefrLevel>('B1');

  useEffect(() => {
    const stored = sessionStorage.getItem('bg_ob_level') as CefrLevel | null;
    setLevel(stored ?? 'B1');
    const existing = sessionStorage.getItem('bg_ob_covered');
    if (existing) setChecked(new Set(JSON.parse(existing) as string[]));
  }, []);

  function proceed() {
    sessionStorage.setItem('bg_ob_covered', JSON.stringify(Array.from(checked)));
    router.push('/onboarding/diagnostic');
  }

  return (
    <div className="flex flex-col gap-6">
      <div>
        <p className="text-xs font-bold uppercase tracking-widest text-emerald-600 mb-2">Step 3 of 4</p>
        <h1 className="text-2xl font-black">What have you been taught?</h1>
        <p className="text-slate-500 mt-1">
          Tick topics you've been introduced to — not necessarily mastered, just seen.
          Begleiter will verify your knowledge with a short diagnostic.
        </p>
      </div>

      <TopicChecklist checked={checked} maxLevel={level} onChange={setChecked} />

      <div className="flex gap-3 sticky bottom-4">
        <Button variant="secondary" size="sm" onClick={() => router.back()}>← Back</Button>
        <Button size="lg" onClick={proceed} disabled={checked.size === 0}>
          Continue ({checked.size} selected) →
        </Button>
      </div>
    </div>
  );
}
