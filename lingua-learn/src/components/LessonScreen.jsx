import styles from './LessonScreen.module.css';

const LESSON_TYPES = [
  { id: 'vocabulary', icon: '📖', title: 'Vocabulary',   desc: 'Learn new words with flashcard-style questions' },
  { id: 'match',      icon: '🔗', title: 'Match Pairs',  desc: 'Match words to their translations'              },
  { id: 'phrases',    icon: '💬', title: 'Phrases',      desc: 'Practise common expressions'                    },
  { id: 'translate',  icon: '✍️', title: 'Translate',    desc: 'Type translations from scratch'                 },
  { id: 'review',     icon: '🔄', title: 'Review All',   desc: 'Mixed practice across everything'               },
  { id: 'converse',   icon: '🗣️', title: 'Converse',     desc: 'Free conversation practice with AI'             },
];

export default function LessonScreen({ unit, onStart, onBack, onConverse }) {
  const vocab   = unit.vocabulary?.length ?? 0;
  const phrases = unit.phrases?.length    ?? 0;

  const available = LESSON_TYPES.filter(t => {
    if (t.id === 'vocabulary' && vocab < 2)            return false;
    if (t.id === 'match'      && vocab + phrases < 3)  return false;
    if (t.id === 'phrases'    && phrases < 2)          return false;
    if (t.id === 'translate'  && vocab + phrases < 2)  return false;
    if (t.id === 'converse'   && vocab < 3)            return false;
    return true;
  });

  return (
    <div className={styles.screen}>
      <header className="app-header">
        <button className="btn-ghost btn" onClick={onBack}>←</button>
        <span style={{ fontWeight: 800, fontSize: '1.05rem' }}>{unit.title}</span>
        <span />
      </header>

      <div className={styles.content}>
        <h2 className={styles.heading}>Choose a Lesson</h2>
        <p className={styles.sub}>Pick an exercise type to practise</p>

        <div className={styles.grid}>
          {available.map(t => (
            <button key={t.id} className={styles.typeCard} onClick={() => t.id === 'converse' ? onConverse() : onStart(t.id)}>
              <span className={styles.typeIcon}>{t.icon}</span>
              <strong>{t.title}</strong>
              <span className={styles.typeDesc}>{t.desc}</span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
