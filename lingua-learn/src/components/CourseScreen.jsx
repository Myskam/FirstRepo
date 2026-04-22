import styles from './CourseScreen.module.css';
import { toast } from './Toast';

export default function CourseScreen({ course, totalXP, streak, onSelectUnit, onAddMore, onReset }) {
  const completed = course.units.filter(u => u.completed).length;

  return (
    <div className={styles.screen}>
      <header className="app-header">
        <span className="logo">🦉 LinguaLearn</span>
        <div className={styles.headerStats}>
          <span className={styles.xp}>⚡ {totalXP} XP</span>
          <span className={styles.streak}>🔥 {streak}</span>
        </div>
      </header>

      <div className={styles.content}>
        {/* Summary row */}
        <div className={styles.statsRow}>
          {[
            { icon: '📖', val: course.totalVocab,   label: 'Words'     },
            { icon: '✅', val: completed,            label: 'Done'      },
            { icon: '⚡', val: totalXP,              label: 'Total XP'  },
          ].map(s => (
            <div key={s.label} className={styles.statCard}>
              <span className={styles.statIcon}>{s.icon}</span>
              <span className={styles.statVal}>{s.val}</span>
              <span className={styles.statLabel}>{s.label}</span>
            </div>
          ))}
        </div>

        <h2 className={styles.courseTitle}>{course.title}</h2>
        <p className={styles.courseSub}>{course.language} · {course.units.length} units</p>

        {/* Units */}
        {course.units.map((unit, i) => {
          const locked = i > 0 && !course.units[i - 1].completed;
          return (
            <div
              key={unit.id}
              className={`${styles.unitCard} ${unit.completed ? styles.done : ''} ${locked ? styles.locked : ''}`}
              onClick={() => locked ? toast('Complete the previous unit first!') : onSelectUnit(i)}
            >
              <div className={styles.unitIcon}>
                {unit.completed ? '✅' : locked ? '🔒' : unit.icon}
              </div>
              <div className={styles.unitInfo}>
                <h3>{unit.title}</h3>
                <p>
                  {unit.vocabulary?.length ?? 0} words
                  {unit.phrases?.length ? ` · ${unit.phrases.length} phrases` : ''}
                  {unit.grammar?.length ? ' · grammar' : ''}
                </p>
                <div className={styles.progressTrack}>
                  <div className={styles.progressFill} style={{ width: `${unit.progress ?? 0}%` }} />
                </div>
              </div>
            </div>
          );
        })}

        <div className={styles.actions}>
          <button className="btn btn-secondary" onClick={onAddMore}>+ Add More Materials</button>
          <button className={styles.resetBtn} onClick={() => {
            if (window.confirm('Reset all progress and course data?')) onReset();
          }}>Reset Course</button>
        </div>
      </div>
    </div>
  );
}
