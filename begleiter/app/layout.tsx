import type { Metadata } from 'next';
import './globals.css';
import { ApiKeyBanner } from '@/components/ApiKeyBanner';

export const metadata: Metadata = {
  title: 'Begleiter — AI German Tutor',
  description: 'A personal AI German tutor that meets you where you are.',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="antialiased bg-slate-50 text-slate-900 font-sans min-h-screen">
        <ApiKeyBanner />
        <main className="max-w-2xl mx-auto px-4 py-8">
          {children}
        </main>
        <footer className="text-center text-xs text-slate-400 py-8 px-4">
          Begleiter is an independent German learning app. It is not affiliated with, endorsed by,
          or produced by Hueber Verlag or any other publisher. CEFR level labels are part of the
          Common European Framework of Reference for Languages, a public international standard.
        </footer>
      </body>
    </html>
  );
}
