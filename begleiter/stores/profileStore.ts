'use client';
import { create } from 'zustand';
import type { StudentProfile } from '@/types';
import { loadProfile, saveProfile, clearProfile, transitionTopic, applySessionResult, markTopicsIntroduced } from '@/lib/profile';

interface ProfileStore {
  profile: StudentProfile | null;
  load: () => void;
  set: (profile: StudentProfile) => void;
  update: (fn: (p: StudentProfile) => StudentProfile) => void;
  reset: () => void;
  recordAnswer: (topicId: string, correct: boolean) => void;
  addNewTopics: (topicIds: string[]) => void;
}

export const useProfileStore = create<ProfileStore>((set, get) => ({
  profile: null,

  load() {
    set({ profile: loadProfile() });
  },

  set(profile) {
    saveProfile(profile);
    set({ profile });
  },

  update(fn) {
    const current = get().profile;
    if (!current) return;
    const next = fn(current);
    saveProfile(next);
    set({ profile: next });
  },

  reset() {
    clearProfile();
    set({ profile: null });
  },

  recordAnswer(topicId, correct) {
    const current = get().profile;
    if (!current) return;
    const next = transitionTopic(current, topicId, correct);
    saveProfile(next);
    set({ profile: next });
  },

  addNewTopics(topicIds) {
    const current = get().profile;
    if (!current) return;
    const next = markTopicsIntroduced(current, topicIds);
    saveProfile(next);
    set({ profile: next });
  },
}));
