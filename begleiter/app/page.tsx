'use client';
import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useProfileStore } from '@/stores/profileStore';
import { TopicStatusGrid } from '@/components/profile/TopicStatusGrid';
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';
import { getActivePracticeTopics } from '@/lib/profile';

export default function Dashboard() {
  const router = useRouter();
  const { profile, load } = useProfileStore();

  useEffect(() => { load(); }, [load]);

  if (!profile) {
    return (
      <div className="flex flex-col items-center gap-6 py-16 text-center">
        <div className="text-6xl">🇩🇪</div>
        <h1 className="text-3xl font-black">Begleiter</h1>
        <p className="text-slate-500 max-w-sm">
          Your personal AI German tutor. It learns what you know and practises exactly what you need.
        </p>
        <Button size="lg" onClick={() => router.push('/onboarding/context')}>
          Get Started →
        </Button>
        <p className="text-xs text-slate-400">Takes about 5 minutes to personalise your tutor.</p>
      </div>
    );
  }

  if (!profile.onboardingComplete) {
    return (
      <div className="flex flex-col items-center gap-4 py-16 text-center">
        <p className="text-slate-500">Finish setting up your tutor first.</p>
        <Button onClick={() => router.push('/onboarding/context')}>Continue Setup →</Button>
      </div>
    );
  }

  const activeTopics = getActivePracticeTopics(profile);
  const masteredCount = Object.values(profile.topics).filter(t => t.status === 'mastered').length;
  const strugglingCount = Object.values(profile.topics).filter(t => t.status === 'struggling').length;

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-black">Good to see you</h1>
          <p className="text-slate-500 text-sm">{profile.level} · {activeTopics.length} topics in practice</p>
        </div>
        <Link href="/session" className="inline-flex items-center justify-center rounded-xl bg-emerald-500 text-white font-bold px-5 py-3 hover:bg-emerald-600 transition-colors">
          Practise →
        </Link>
      </div>

      <div className="grid grid-cols-3 gap-3">
        {[
          { icon: '✓', val: masteredCount,     label: 'Mastered'   },
          { icon: '⟳', val: activeTopics.length, label: 'Active'   },
          { icon: '⚠', val: strugglingCount,   label: 'Needs work' },
        ].map(s => (
          <Card key={s.label} className="p-4 text-center">
            <div className="text-xl font-black">{s.val}</div>
            <div className="text-xs text-slate-500 font-semibold">{s.label}</div>
          </Card>
        ))}
      </div>

      <Card className="p-5">
        <h2 className="font-black text-lg mb-4">Your Knowledge Map</h2>
        <TopicStatusGrid profile={profile} />
      </Card>

      <div className="flex gap-3">
        <Button variant="secondary" size="sm" onClick={() => router.push('/session')}>
          Start Session
        </Button>
        <Button variant="ghost" size="sm" onClick={() => router.push('/onboarding/coverage')}>
          Add New Topics
        </Button>
      </div>
    </div>
  );
}
