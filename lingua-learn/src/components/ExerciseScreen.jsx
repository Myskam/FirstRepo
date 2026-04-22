import { useState, useEffect, useRef, useCallback } from 'react';
import { generateExercises, isCorrectAnswer, shuffle } from '../utils/exerciseGenerator';
import styles from './ExerciseScreen.module.css';

const MAX_HEARTS = 5;
const XP_PER_CORRECT = 10;

export default function ExerciseScreen({ unit, lessonType, language, onComplete, onExit }) {
  const exercises = useRef(generateExercises(unit, lessonType, language));

  const [idx, setIdx]         = useState(0);
  const [hearts, setHearts]   = useState(MAX_HEARTS);
  const [answered, setAnswered] = useState(false);
  const [correct, setCorrect]   = useState(false);
  const [detail, setDetail]     = useState('');
  const [correctCount, setCorrectCount] = useState(0);
  const [wrongCount,   setWrongCount]   = useState(0);
  const [lessonXP,     setLessonXP]     = useState(0);
  const [anim, setAnim] = useState('');

  // Answers state for current exercise
  const [selectedOption, setSelectedOption] = useState(null);
  const [typedAnswer, setTypedAnswer]       = useState('');
  // Match state
  const [matchLeft,  setMatchLeft]  = useState(null); // { side:'target'|'native', id }
  const [matchDone,  setMatchDone]  = useState(new Set());
  const [matchWrong, setMatchWrong] = useState(new Set());

  const inputRef = useRef();
  const ex = exercises.current[idx];
  const total = exercises.current.length;
  const progress = (idx / total) * 100;

  // Focus text input when exercise changes
  useEffect(() => {
    if (ex?.type === 'typeAnswer') {
      setTimeout(() => inputRef.current?.focus(), 80);
    }
    setAnswered(false);
    setCorrect(false);
    setDetail('');
    setSelectedOption(null);
    setTypedAnswer('');
    setMatchLeft(null);
    setMatchDone(new Set());
    setMatchWrong(new Set());
  }, [idx]);

  // Keyboard: Enter to continue, 1-4 for options
  useEffect(() => {
    function onKey(e) {
      if (answered && e.key === 'Enter') { advance(); return; }
      if (!answered && ex?.type === 'multiChoice') {
        const n = parseInt(e.key);
        if (n >= 1 && n <= 4) {
          const opts = ex.options;
          if (opts[n - 1]) submitMultiChoice(opts[n - 1]);
        }
      }
    }
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  });

  function triggerAnim(name) {
    setAnim('');
    requestAnimationFrame(() => setAnim(name));
  }

  function submitResult(isCorrect, correctAnswer) {
    setAnswered(true);
    setCorrect(isCorrect);
    if (isCorrect) {
      setCorrectCount(c => c + 1);
      setLessonXP(x => x + XP_PER_CORRECT);
      triggerAnim('anim-pop');
    } else {
      const newHearts = hearts - 1;
      setWrongCount(w => w + 1);
      setHearts(newHearts);
      triggerAnim('anim-shake');
      if (newHearts <= 0) {
        setTimeout(() => finish(correctCount, wrongCount + 1, lessonXP), 1200);
      }
    }
    setDetail(correctAnswer);
  }

  function submitMultiChoice(option) {
    if (answered) return;
    setSelectedOption(option);
    submitResult(option === ex.correct, ex.correct);
  }

  function submitTypeAnswer() {
    if (answered || !typedAnswer.trim()) return;
    submitResult(isCorrectAnswer(typedAnswer, ex.correct), ex.correct);
  }

  function handleMatchTap(side, id) {
    if (matchDone.has(id)) return;

    if (!matchLeft) {
      setMatchLeft({ side, id });
      return;
    }

    if (matchLeft.side === side) {
      // Same column — switch selection
      setMatchLeft({ side, id });
      return;
    }

    const targetId = side === 'target' ? id : matchLeft.id;
    const nativeId = side === 'native' ? id : matchLeft.id;

    if (targetId === nativeId) {
      // Correct pair
      const nextDone = new Set([...matchDone, targetId]);
      setMatchDone(nextDone);
      setMatchLeft(null);
      if (nextDone.size === ex.pairs.length) {
        setTimeout(() => submitResult(true, ''), 300);
      }
    } else {
      // Wrong
      const wrongIds = new Set([matchLeft.id, id]);
      setMatchWrong(wrongIds);
      setMatchLeft(null);
      setTimeout(() => setMatchWrong(new Set()), 600);
      setHearts(h => {
        const next = h - 1;
        if (next <= 0) setTimeout(() => finish(correctCount, wrongCount + 1, lessonXP), 900);
        return next;
      });
      setWrongCount(w => w + 1);
    }
  }

  function advance() {
    if (idx + 1 >= total || hearts <= 0) {
      finish(correctCount, wrongCount, lessonXP);
    } else {
      setIdx(i => i + 1);
    }
  }

  function finish(cc, wc, xp) {
    onComplete({ correctCount: cc, wrongCount: wc, lessonXP: xp });
  }

  function handleExit() {
    if (idx > 0 && !window.confirm('Exit lesson? Progress will not be saved.')) return;
    onExit();
  }

  if (!ex) return null;

  const heartsArr = Array.from({ length: MAX_HEARTS }, (_, i) => i < hearts);

  return (
    <div className={styles.screen}>
      {/* Header */}
      <div className={styles.header}>
        <button className={`btn btn-ghost ${styles.exitBtn}`} onClick={handleExit}>✕</button>
        <div className="progress-track">
          <div className="progress-fill" style={{ width: `${progress}%` }} />
        </div>
        <div className={styles.hearts}>
          {heartsArr.map((full, i) => (
            <span key={i}>{full ? '❤️' : '🖤'}</span>
          ))}
        </div>
      </div>

      {/* Body */}
      <div className={`${styles.body} ${anim}`}>
        {ex.type === 'multiChoice' && (
          <MultiChoice
            exercise={ex}
            selected={selectedOption}
            answered={answered}
            onSelect={submitMultiChoice}
          />
        )}
        {ex.type === 'typeAnswer' && (
          <TypeAnswer
            exercise={ex}
            value={typedAnswer}
            onChange={setTypedAnswer}
            answered={answered}
            correct={correct}
            inputRef={inputRef}
            onSubmit={submitTypeAnswer}
          />
        )}
        {ex.type === 'match' && (
          <MatchPairs
            exercise={ex}
            selected={matchLeft}
            done={matchDone}
            wrong={matchWrong}
            onTap={handleMatchTap}
          />
        )}
      </div>

      {/* Feedback footer */}
      {answered && (
        <div className={`${styles.footer} ${correct ? styles.footerCorrect : styles.footerWrong}`}>
          <p className={`${styles.feedbackMsg} ${correct ? styles.msgCorrect : styles.msgWrong}`}>
            {correct ? '🎉 Correct!' : '❌ Incorrect'}
          </p>
          {!correct && detail && (
            <p className={styles.feedbackDetail}>Correct answer: <strong>{detail}</strong></p>
          )}
          {correct && detail && (
            <p className={styles.feedbackDetail}>{detail}</p>
          )}
          <button
            className={`btn ${correct ? 'btn-primary' : 'btn-danger'}`}
            onClick={advance}
          >
            Continue
          </button>
        </div>
      )}

      {/* Check button for type answer before submission */}
      {!answered && ex.type === 'typeAnswer' && (
        <div className={styles.footer}>
          <button
            className="btn btn-primary"
            disabled={!typedAnswer.trim()}
            onClick={submitTypeAnswer}
          >
            Check
          </button>
        </div>
      )}
    </div>
  );
}

/* ── Sub-components ───────────────────────────────────────── */

function MultiChoice({ exercise, selected, answered, onSelect }) {
  return (
    <>
      <p className={styles.prompt}>{exercise.prompt}</p>
      <p className={styles.question}>{exercise.question}</p>
      <div className={styles.optionsGrid}>
        {exercise.options.map((opt, i) => {
          let cls = styles.option;
          if (answered) {
            if (opt === exercise.correct)  cls += ` ${styles.optCorrect}`;
            else if (opt === selected)     cls += ` ${styles.optWrong}`;
          } else if (opt === selected) {
            cls += ` ${styles.optSelected}`;
          }
          return (
            <button
              key={i}
              className={cls}
              onClick={() => !answered && onSelect(opt)}
              disabled={answered}
            >
              {opt}
            </button>
          );
        })}
      </div>
    </>
  );
}

function TypeAnswer({ exercise, value, onChange, answered, correct, inputRef, onSubmit }) {
  return (
    <>
      <p className={styles.prompt}>{exercise.prompt}</p>
      <p className={styles.question}>{exercise.question}</p>
      <input
        ref={inputRef}
        type="text"
        className={`input-field ${styles.typeInput} ${answered ? (correct ? 'correct' : 'wrong') : ''}`}
        placeholder="Type your answer…"
        value={value}
        onChange={e => !answered && onChange(e.target.value)}
        onKeyDown={e => e.key === 'Enter' && !answered && onSubmit()}
        disabled={answered}
        autoComplete="off"
        autoCorrect="off"
        spellCheck={false}
      />
    </>
  );
}

function MatchPairs({ exercise, selected, done, wrong, onTap }) {
  const [leftItems]  = useState(() => shuffle(exercise.pairs));
  const [rightItems] = useState(() => shuffle(exercise.pairs));

  function itemClass(side, id) {
    let cls = styles.matchItem;
    if (done.has(id))  cls += ` ${styles.matchDone}`;
    if (wrong.has(id)) cls += ` ${styles.matchWrong}`;
    if (selected && selected.id === id) cls += ` ${styles.matchSelected}`;
    return cls;
  }

  return (
    <>
      <p className={styles.prompt}>{exercise.prompt}</p>
      <p className={styles.matchHint}>Tap a word, then tap its translation</p>
      <div className={styles.matchGrid}>
        <div className={styles.matchCol}>
          {leftItems.map(p => (
            <button key={p.id} className={itemClass('target', p.id)} onClick={() => !done.has(p.id) && onTap('target', p.id)}>
              {p.target}
            </button>
          ))}
        </div>
        <div className={styles.matchCol}>
          {rightItems.map(p => (
            <button key={p.id} className={itemClass('native', p.id)} onClick={() => !done.has(p.id) && onTap('native', p.id)}>
              {p.native}
            </button>
          ))}
        </div>
      </div>
    </>
  );
}
