'use client';
import { create } from 'zustand';
import type { Exercise, Answer, SessionSummary } from '@/types';

interface SessionStore {
  exercises: Exercise[];
  currentIndex: number;
  answers: Answer[];
  startedAt: string | null;
  isLoading: boolean;
  error: string | null;
  summary: SessionSummary | null;

  startSession: (exercises: Exercise[]) => void;
  recordAnswer: (answer: Answer) => void;
  next: () => void;
  setSummary: (summary: SessionSummary) => void;
  setLoading: (v: boolean) => void;
  setError: (msg: string | null) => void;
  reset: () => void;
}

export const useSessionStore = create<SessionStore>((set) => ({
  exercises: [],
  currentIndex: 0,
  answers: [],
  startedAt: null,
  isLoading: false,
  error: null,
  summary: null,

  startSession(exercises) {
    set({ exercises, currentIndex: 0, answers: [], startedAt: new Date().toISOString(), error: null, summary: null });
  },

  recordAnswer(answer) {
    set(s => ({ answers: [...s.answers, answer] }));
  },

  next() {
    set(s => ({ currentIndex: s.currentIndex + 1 }));
  },

  setSummary(summary) {
    set({ summary });
  },

  setLoading(v) {
    set({ isLoading: v });
  },

  setError(msg) {
    set({ error: msg });
  },

  reset() {
    set({ exercises: [], currentIndex: 0, answers: [], startedAt: null, isLoading: false, error: null, summary: null });
  },
}));
