import { useState } from 'react';
import styles from './WelcomeScreen.module.css';
import { toast } from './Toast';

export default function WelcomeScreen({ onStart, savedCourse, onLoadGermanTutor, hasGermanCache }) {
  const [apiKey, setApiKey] = useState(() => localStorage.getItem('ll_apiKey') ?? '');

  function handleStart() {
    if (!apiKey.trim()) { toast('Please enter your Claude API key'); return; }
    localStorage.setItem('ll_apiKey', apiKey.trim());
    onStart(apiKey.trim());
  }

  return (
    <div className={styles.screen}>
      <div className={styles.card}>
        <span className={styles.owl}>🦉</span>
        <h1 className={styles.title}>LinguaLearn</h1>
        <p className={styles.subtitle}>
          Upload images of your language course book and workbook — we'll build a
          personalised Duolingo‑style course just for you.
        </p>

        <label className={styles.label}>Claude API Key</label>
        <input
          type="password"
          className={`input-field ${styles.keyInput}`}
          placeholder="sk-ant-api03-…"
          value={apiKey}
          onChange={e => setApiKey(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && handleStart()}
        />

        <button className="btn btn-primary" onClick={handleStart}>
          {savedCourse ? 'Continue Course →' : 'Get Started →'}
        </button>

        <div className={styles.divider}>or</div>

        <button className="btn btn-secondary" onClick={onLoadGermanTutor}>
          {hasGermanCache ? '📖 Continue German Tutor' : '🇩🇪 Load German Tutor'}
        </button>

        {savedCourse && (
          <p className={styles.existing}>
            📚 Existing course: <strong>{savedCourse.title}</strong>
          </p>
        )}
      </div>
    </div>
  );
}
