'use client';
import type { StudentProfile, TopicStatus } from '@/types';
import { getTopic } from '@/lib/taxonomy';
import { Badge } from '@/components/ui/Badge';

const STATUS_ORDER: TopicStatus[] = ['struggling', 'active', 'introduced', 'mastered', 'not_covered'];
const STATUS_LABELS: Record<TopicStatus, string> = {
  struggling:  '⚠ Needs Work',
  active:      '⟳ Practising',
  introduced:  '◦ Seen',
  mastered:    '✓ Mastered',
  not_covered: '○ Not yet',
};

interface Props {
  profile: StudentProfile;
}

export function TopicStatusGrid({ profile }: Props) {
  const grouped: Record<TopicStatus, string[]> = {
    struggling: [],
    active: [],
    introduced: [],
    mastered: [],
    not_covered: [],
  };

  for (const [id, state] of Object.entries(profile.topics)) {
    grouped[state.status].push(id);
  }

  const visibleStatuses = STATUS_ORDER.filter(s => s !== 'not_covered' || grouped.not_covered.length > 0);

  return (
    <div className="flex flex-col gap-4">
      {visibleStatuses.map(status => {
        const ids = grouped[status];
        if (!ids.length) return null;
        return (
          <div key={status}>
            <p className="text-sm font-bold text-slate-500 mb-2">{STATUS_LABELS[status]}</p>
            <div className="flex flex-wrap gap-2">
              {ids.map(id => {
                const topic = getTopic(id);
                if (!topic) return null;
                return (
                  <div key={id} className="flex items-center gap-1.5 bg-white border border-slate-200 rounded-lg px-2.5 py-1.5">
                    <span className="text-xs font-semibold text-slate-700">{topic.displayName}</span>
                    <Badge status={status} />
                  </div>
                );
              })}
            </div>
          </div>
        );
      })}
    </div>
  );
}
