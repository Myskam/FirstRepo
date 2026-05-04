'use client';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';

export default function SetupPage() {
  const router = useRouter();
  const [key, setKey] = useState('');
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    const existing = localStorage.getItem('bg_apiKey') ?? '';
    setKey(existing);
  }, []);

  function save() {
    if (!key.trim()) return;
    localStorage.setItem('bg_apiKey', key.trim());
    setSaved(true);
    setTimeout(() => router.push('/'), 900);
  }

  return (
    <div className="flex flex-col gap-6 py-8">
      <div>
        <h1 className="text-2xl font-black">API Key Setup</h1>
        <p className="text-slate-500 mt-1">
          Begleiter uses the Claude API to generate personalised exercises.
          Your key is stored only in your browser — never sent to any server.
        </p>
      </div>

      <Card className="p-5 flex flex-col gap-4">
        <label className="flex flex-col gap-1.5">
          <span className="text-sm font-bold text-slate-600">Claude API Key</span>
          <input
            type="password"
            className="w-full rounded-xl border-2 border-slate-200 px-4 py-3 font-mono text-sm focus:border-emerald-400 outline-none transition-colors"
            placeholder="sk-ant-api03-…"
            value={key}
            onChange={e => setKey(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && save()}
            autoComplete="off"
          />
        </label>
        <Button onClick={save} disabled={!key.trim() || saved}>
          {saved ? '✓ Saved!' : 'Save Key'}
        </Button>
      </Card>

      <p className="text-xs text-slate-400">
        Get your API key at console.anthropic.com. The key is stored in localStorage and
        sent directly to api.anthropic.com from your browser.
      </p>
    </div>
  );
}
