'use client';
import { useRouter } from 'next/navigation';
import type { CefrLevel } from '@/types';

const LEVELS: { id: CefrLevel; label: string; desc: string }[] = [
  { id: 'A1',  label: 'Complete beginner',  desc: "I've never studied German before" },
  { id: 'A1',  label: 'A1',                 desc: 'Basic greetings, simple sentences' },
  { id: 'A2',  label: 'A2',                 desc: 'Everyday topics, simple past tense' },
  { id: 'B1',  label: 'B1',                 desc: 'Independent learner, complex sentences' },
  { id: 'B2+', label: 'B2 or above',        desc: 'Fluent conversation, advanced grammar' },
];

// De-duplicate for display
const DISPLAY = [
  { id: 'A1' as CefrLevel,  label: 'Complete beginner / A1', desc: "I've never studied German or have only just started" },
  { id: 'A2' as CefrLevel,  label: 'A2 — Elementary',        desc: 'I can handle everyday topics and simple past tense' },
  { id: 'B1' as CefrLevel,  label: 'B1 — Intermediate',      desc: 'I can read and write about familiar topics' },
  { id: 'B2+' as CefrLevel, label: 'B2+ — Upper intermediate+', desc: 'I can hold complex conversations' },
  { id: 'A1' as CefrLevel,  label: "Not sure — let the app decide", desc: 'Start with a short diagnostic' },
];

export default function LevelStep() {
  const router = useRouter();

  function pick(level: CefrLevel, skipTodiagnostic = false) {
    sessionStorage.setItem('bg_ob_level', level);
    if (skipTodiagnostic) {
      sessionStorage.setItem('bg_ob_covered', JSON.stringify([]));
      router.push('/onboarding/diagnostic');
    } else {
      router.push('/onboarding/coverage');
    }
  }

  const options: { level: CefrLevel; label: string; desc: string; skipCoverage?: boolean }[] = [
    { level: 'A1',  label: 'Complete beginner / A1',        desc: "I've never studied German or have only just started" },
    { level: 'A2',  label: 'A2 — Elementary',               desc: 'Everyday topics, simple past tense' },
    { level: 'B1',  label: 'B1 — Intermediate',             desc: 'Independent learner, complex sentences' },
    { level: 'B2+', label: 'B2+ — Upper Intermediate+',     desc: 'Fluent conversation, advanced grammar' },
    { level: 'A1',  label: "Not sure — let the app decide", desc: 'Start with a short diagnostic', skipCoverage: true },
  ];

  return (
    <div className="flex flex-col gap-6">
      <div>
        <p className="text-xs font-bold uppercase tracking-widest text-emerald-600 mb-2">Step 2 of 4</p>
        <h1 className="text-2xl font-black">What level are you at?</h1>
        <p className="text-slate-500 mt-1">Be honest — a slightly lower estimate leads to better practice.</p>
      </div>

      <div className="flex flex-col gap-3">
        {options.map((opt, i) => (
          <button
            key={i}
            className="text-left p-4 rounded-2xl border-2 border-slate-200 hover:border-emerald-400 hover:bg-emerald-50 transition-colors"
            onClick={() => pick(opt.level, opt.skipCoverage)}
          >
            <p className="font-bold text-slate-800">{opt.label}</p>
            <p className="text-sm text-slate-500 mt-0.5">{opt.desc}</p>
          </button>
        ))}
      </div>
    </div>
  );
}
