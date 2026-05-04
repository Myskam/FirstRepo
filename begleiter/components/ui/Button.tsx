import { type ButtonHTMLAttributes, forwardRef } from 'react';
import { cn } from '@/lib/utils';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = 'primary', size = 'md', className, children, ...props }, ref) => {
    const base = 'inline-flex items-center justify-center rounded-xl font-bold transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed';
    const variants = {
      primary:   'bg-emerald-500 text-white hover:bg-emerald-600 active:scale-95 focus-visible:ring-emerald-500',
      secondary: 'bg-white text-slate-800 border-2 border-slate-200 hover:border-emerald-400 hover:text-emerald-600',
      ghost:     'bg-transparent text-slate-500 hover:bg-slate-100',
      danger:    'bg-red-500 text-white hover:bg-red-600 active:scale-95 focus-visible:ring-red-500',
    };
    const sizes = {
      sm: 'text-sm px-4 py-2 gap-1.5',
      md: 'text-base px-5 py-3 gap-2',
      lg: 'text-lg px-6 py-4 gap-2 w-full',
    };
    return (
      <button ref={ref} className={cn(base, variants[variant], sizes[size], className)} {...props}>
        {children}
      </button>
    );
  },
);
Button.displayName = 'Button';
