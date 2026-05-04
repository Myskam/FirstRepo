import { type TopicStatus } from '@/types';
import { cn } from '@/lib/utils';

const STATUS_CONFIG: Record<TopicStatus, { label: string; className: string }> = {
  not_covered: { label: 'Not yet',   className: 'bg-slate-100 text-slate-500' },
  introduced:  { label: 'Seen',      className: 'bg-blue-100 text-blue-700' },
  active:      { label: 'Practising',className: 'bg-amber-100 text-amber-700' },
  struggling:  { label: 'Needs work',className: 'bg-red-100 text-red-700' },
  mastered:    { label: 'Mastered',  className: 'bg-emerald-100 text-emerald-700' },
};

export function Badge({ status }: { status: TopicStatus }) {
  const { label, className } = STATUS_CONFIG[status];
  return (
    <span className={cn('inline-block rounded-full px-2.5 py-0.5 text-xs font-bold', className)}>
      {label}
    </span>
  );
}
