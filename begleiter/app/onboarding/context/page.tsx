'use client';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';
import type { StudyContext } from '@/types';

const OPTIONS: { id: StudyContext; label: string; desc: string }[] = [
  { id: 'class',      label: 'In a class with a textbook', desc: 'Following a course at school or a language centre' },
  { id: 'self_study', label: 'Self-study with a textbook', desc: 'Working through a textbook on your own' },
  { id: 'app_only',   label: 'No textbook — just me',      desc: 'No external course, just this app' },
];

export default function ContextStep() {
  const router = useRouter();

  function pick(context: StudyContext) {
    sessionStorage.setItem('bg_ob_context', context);
    router.push('/onboarding/level');
  }

  return (
    <div className="flex flex-col gap-6">
      <div>
        <p className="text-xs font-bold uppercase tracking-widest text-emerald-600 mb-2">Step 1 of 4</p>
        <h1 className="text-2xl font-black">How are you learning German?</h1>
        <p className="text-slate-500 mt-1">This helps Begleiter work alongside what you're already doing.</p>
      </div>

      <div className="flex flex-col gap-3">
        {OPTIONS.map(opt => (
          <button
            key={opt.id}
            className="text-left p-4 rounded-2xl border-2 border-slate-200 hover:border-emerald-400 hover:bg-emerald-50 transition-colors"
            onClick={() => pick(opt.id)}
          >
            <p className="font-bold text-slate-800">{opt.label}</p>
            <p className="text-sm text-slate-500 mt-0.5">{opt.desc}</p>
          </button>
        ))}
      </div>
    </div>
  );
}
