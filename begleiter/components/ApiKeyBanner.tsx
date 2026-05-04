'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';

export function ApiKeyBanner() {
  const [show, setShow] = useState(false);

  useEffect(() => {
    setShow(!localStorage.getItem('bg_apiKey'));
  }, []);

  if (!show) return null;

  return (
    <div className="fixed top-0 inset-x-0 z-50 bg-amber-500 text-white text-sm font-bold px-4 py-3 flex items-center justify-between gap-4">
      <span>⚠ No API key set — some features need your Claude API key.</span>
      <Link href="/setup" className="underline whitespace-nowrap hover:no-underline">
        Set up →
      </Link>
    </div>
  );
}
