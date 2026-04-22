import styles from './CompleteScreen.module.css';

export default function CompleteScreen({ result, onContinue, onBack }) {
  const { correctCount, wrongCount, lessonXP } = result;
  const total    = correctCount + wrongCount;
  const accuracy = total > 0 ? Math.round((correctCount / total) * 100) : 100;

  return (
    <div className={styles.screen}>
      <div className={styles.card}>
        <span className={styles.icon}>🎉</span>
        <h2 className={styles.title}>Lesson Complete!</h2>
        <p className={styles.sub}>Great work — keep practising to build your streak!</p>

        <div className={styles.xpBadge}>
          +{lessonXP} <span>XP</span>
        </div>

        <div className={styles.statsRow}>
          {[
            { val: correctCount, label: 'Correct',  color: 'var(--green)' },
            { val: wrongCount,   label: 'Errors',   color: 'var(--red)'   },
            { val: `${accuracy}%`, label: 'Accuracy', color: 'var(--blue)' },
          ].map(s => (
            <div key={s.label} className={styles.stat}>
              <span className={styles.statVal} style={{ color: s.color }}>{s.val}</span>
              <span className={styles.statLabel}>{s.label}</span>
            </div>
          ))}
        </div>

        <button className="btn btn-primary" onClick={onContinue} style={{ marginBottom: 12 }}>
          Continue →
        </button>
        <button className="btn btn-secondary" onClick={onBack}>
          Back to Course
        </button>
      </div>
    </div>
  );
}
