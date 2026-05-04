import { useState } from 'react';
import styles from './GrammarTip.module.css';

function findRelevant(grammar, question, correct) {
  if (!grammar?.length) return [];
  const haystack = `${question ?? ''} ${correct ?? ''}`.toLowerCase();
  const words = haystack.split(/\s+/).filter(w => w.length > 3);
  const scored = grammar.map(g => ({
    ...g,
    score: words.filter(w => g.rule.toLowerCase().includes(w)).length,
  }));
  const relevant = scored.filter(g => g.score > 0).sort((a, b) => b.score - a.score);
  return (relevant.length > 0 ? relevant : grammar).slice(0, 3);
}

export default function GrammarTip({ grammar, question, correct }) {
  const [open, setOpen] = useState(false);
  const tips = findRelevant(grammar, question, correct);
  if (!tips.length) return null;

  return (
    <div className={styles.wrap}>
      <button className={styles.toggle} onClick={() => setOpen(o => !o)}>
        💡 Grammar Tips {open ? '▲' : '▼'}
      </button>
      {open && (
        <ul className={styles.list}>
          {tips.map((t, i) => (
            <li key={i} className={styles.item}>
              <span className={styles.rule}>{t.rule}</span>
              {t.example && <span className={styles.example}>{t.example}</span>}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
